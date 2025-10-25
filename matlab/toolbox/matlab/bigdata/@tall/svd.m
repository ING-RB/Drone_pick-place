function [U,S,V] = svd(A,varargin)
%SVD    Singular value decomposition.
%
%   Supported Syntaxes:
%
%   s = SVD(X)
%   [U,S,V] = SVD(X,0)
%     Note: This syntax is not recommended. Use the "econ" option instead.
%   [U,S,V] = SVD(X,"econ")
%   [...] = SVD(...,"vector")
%   [...] = SVD(...,"matrix")
%
%   Limitations:
%
%   1) The three-output syntax [U,S,V] = SVD(X) is not supported. For three
%      outputs, you must specify SVD(X,"econ"), and can optionally specify
%      the "vector" or "matrix" options.
% 
%   2) With one output s = SVD(X,...), the singular values must be returned as
%      a vector unless you specify "econ".
%

%   Copyright 2018-2023 The MathWorks, Inc.

import matlab.bigdata.internal.broadcast

narginchk(1, 3);
% Check correct inputs/outputs are given requested or error
if (nargout > 1) && (nargin < 2)
    error(message("MATLAB:bigdata:array:SVDnoecon"));
end

% Parse inputs and error out as early as possible.
fname = mfilename;

% Check correct tallness of inputs
if nargin > 1
    for k = 1:numel(varargin)
        tall.checkNotTall(upper(fname), k, varargin{k});
    end
end
tall.checkIsTall(upper(fname), 1, A);

% Verify economy and sigma shape flags are correctly specified.
econFlag = 0;
if nargout > 1
    shapeFlag = "matrix";
else
    shapeFlag = "vector";
end

if nargin > 1
    setEcon = 0;
    for k = 1:numel(varargin)
        thisArg = varargin{k};
        if ~isnumeric(thisArg)
            if ~matlab.internal.datatypes.isScalarText(thisArg)
                error(message("MATLAB:svd:invalidOption"));
            end
            thisArg = matlab.internal.datatypes.partialMatch(thisArg, ...
                {'econ', 'vector', 'matrix'});
            if thisArg == "econ"
                econFlag = thisArg;
                setEcon = setEcon + 1;
            elseif thisArg == "vector" || thisArg == "matrix"
                shapeFlag = thisArg;
            else
                error(message("MATLAB:svd:invalidOption"));
            end
        elseif isnumeric(thisArg) && isscalar(thisArg) && thisArg == 0 && k == 1
            % "econ" flag provided as a second-input argument: 0.
            econFlag = thisArg;
            setEcon = setEcon + 1;
        else
            error(message("MATLAB:svd:invalidOption"));
        end
    end
    
    if setEcon > 1
        error(message("MATLAB:svd:repeatedEconomyFlag"));
    elseif ~setEcon && nargout > 1
        % Tall/svd limitation: "econ" flag must be provided for
        % multiple-output svd.
        error(message("MATLAB:bigdata:array:SVDnoecon"));
    elseif shapeFlag == "matrix" && ~setEcon
        % Tall/svd limitation: "econ" flag must be provided for
        % one-output svd with 'matrix' form.
        error(message("MATLAB:bigdata:array:SVDOneOutputMatrixNotSupported"))
    end
end

% verify A is a tall of the right class
A = tall.validateTypeWithError(A, "svd", 1, "float", "MATLAB:svd:inputType");

% lazy Validate A is a matrix
A = tall.validateMatrix(A,"MATLAB:svd:inputMustBe2D");

% Start by reducing A
rA = reducefun(@redQRfun,A);

if nargout <= 1
    % gather rA on one worker and get the singular values
    U = clientfun(@svd,rA,broadcast(econFlag),broadcast(shapeFlag));
else
    % gather rA and either get all U,S,V if short and wide or gather
    % S,V to use in generating the new U from A
    [U0,S1,V1,rankS,flag] = clientfun(@SVDishfun,rA,econFlag);
    U1 = slicefun(@deASVingfun,A,broadcast(S1),broadcast(V1),broadcast(flag));
    
    % Set rng state to default in case we need it next, and add cleanup
    oldRngState = tallrng('default');
    tallrngCleanup = onCleanup(@() tallrng(oldRngState));
    
    % flag will inform next steps if doing any work or skipping
    opts = matlab.bigdata.internal.PartitionedArrayOptions;
    opts.RequiresRandState = true;
    U2 = slicefun(opts,@orthofun,U1,broadcast(rankS),broadcast(flag));
    
    % reduce U2 in preparation for 2nd svd
    rA2 = reducefun(@redQRfun,U2);
    [~,S2,V2,~,~] = clientfun(@SVDishfun,rA2,econFlag);
    
    % build Uf only if flag is not 0 (not already done)
    Uf = slicefun(@deASVingfun,U2,broadcast(S2),broadcast(V2),broadcast(flag));
    
    % Compute svd of small multiplication
    A3 = clientfun(@combineSVsfun,flag,S1,V1,S2,V2);
    [U3,S3,V3,~,~] = clientfun(@SVDishfun,A3,econFlag);
    
    % Compute new U by multiplying Uf with U3
    U4 = slicefun(@Umultfun,Uf,broadcast(U3),broadcast(flag));
    
    % At the end choose correct U,S,V based on flag
    Un = slicefun(@selectUflag,U1,U4,broadcast(flag));
    opts = matlab.bigdata.internal.PartitionedArrayOptions;
    opts.PassTaggedInputs = true;
    U = partitionfun(opts,@iCombine,Un,broadcast(U0),broadcast(flag));
    % U only depends on partitioning if A already did.
    U = copyPartitionIndependence(U, A);
    
    [S,V] = clientfun(@selectSVflag,S1,V1,S3,V3,broadcast(flag),broadcast(shapeFlag));
end
end

% reduce A via QR factorizations
function R = redQRfun(A)
if size(A,1) <= size(A,2)
    % If chunk has less rows than columns do nothing
    R = A;
else
    % Otherwise reduce via QR
    if size(A,2) == 1 && isnan(A(1))
        % If A is a column vector starting with a NaN, older versions of LAPACK
        % return a wrong answer.
        R = NaN(1,1,"like",A);
    else
        [~,R] = qr(A,0);
    end
end
end

% This function adds random vectors for low-rank Us
function U = orthofun(U,rankS,flag)
% Only reorthogonalize if low rank (flag = 3)
if (flag > 2)
    U(:,rankS+1:end) = rand(size(U(:,rankS+1:end)));
end
end

% This function computes a SVD decomposition of R and also gives rank
function [U,S,V,rankS,flag] = SVDishfun(R,econopt)
% Compute S,V from R
[U,S,V] = svd(R,econopt);
% Check rank and nubmer of values
ds = diag(S);
tol = size(ds,1) * eps(max(ds));
rankS = nnz(ds > tol);

if (size(R,1) < size(R,2))
    % Need to return smaller U computed here instead of tall U
    flag = 0;
else
    if isempty(S)
        % Empty matrix, need to create right sized U,S,V only
        flag = 1;
    else
        % based on rank and conditioning set flags
        if (rankS == size(S,2))
            if (ds(1)/ds(end) > 1/sqrt((size(ds,1)^2)*eps(class(ds))))
                % this is ill-conditioned matrix, need another U,S,V pass
                flag = 2;
            else
                % conditioning is good, need to return U,S,V
                flag = 1;
            end
        else
            % low-rank, needs new randomized U vectors and another U,S,V pass
            flag = 3;
        end
    end
end
end

% This function computes a U from A via using S,V
function U = deASVingfun(A,S,V,flag)
if(flag)
    % Investigate diagonal to determine rank
    ds = diag(S);
    tol = size(ds,1) * eps(max(ds));
    
    % Compute left singular vectors
    ds(ds < tol) = 1;
    is = 1./ds;
    U = A * V * diag(is);
else
    U = A;
end
end

% This clientfun multiplies S,V's
function A3 = combineSVsfun(flag,S1,V1,S2,V2)
if (flag > 1)
    A3 = S2 * V2' * S1 * V1';
else
    A3 = S2;
end
end

% Multiply tall U1 with clientfun U2
function Un = Umultfun(U1,U2,flag)
if (flag > 1)
    Un = U1*U2;
else
    Un = U1;
end
end

% This function selects tall U's depending on flag
function U = selectUflag(U1,U2,flag)
if (flag > 1)
    U = U2;
else
    U = U1;
end
end

% This function selects clientfun S,V's depending on flag
function [S,V] = selectSVflag(S1,V1,S2,V2,flag,shapeFlag)
if (flag > 1)
    S = S2;
    V = V2;
else
    S = S1;
    V = V1;
end
% Apply Sigma shape flag. Here S1 and S2 are guaranteed to be matrices.
% Return the diagonal vector if "vector" is specified in shapeFlag.
if shapeFlag == "vector"
    S = diag(S);
    if isempty(S)
        % For empty output, the output is 0x1 and not 0x0
        S = zeros(0,1,"like",S);
    end
end
end

% This function selects between a tall U and a clientfunU
function [isFinished, y] = iCombine(info, tallX, clientfunX, condUseTall)
% This partitionfun receives TaggedInputs. We need to guarantee that we can
% see all the partitions in the tall array even if they are tagged as
% UnknownEmptyArray. When condUseTall is false, the resulting U is the one
% generated by a clientfun operation and it needs to be injected in the
% first partition of the tall array. The rest of partitions are empty.

% Before any computation, unwrap clientfunX and condUseTall as they are
% BroadcastArrays.
clientfunX = getUnderlying(clientfunX);
condUseTall = getUnderlying(condUseTall);

if condUseTall
    isFinished = info.IsLastChunk;
    y = tallX;
else
    isFinished = true;
    if info.PartitionId == 1
        y = clientfunX;
    else
        y = clientfunX([],:);
    end
end
end