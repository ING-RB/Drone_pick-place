function [U,S,V] = svdappend(U,S,V,D,varargin)
%SVDAPPEND Revise singular value decomposition after appending data.
%   [U1,S1,V1] = SVDAPPEND(U,S,V,D), where A = U*S*V' is an existing SVD,
%   calculates the SVD of [A D] without explicitly forming A or [A D].
%   The results are equal up to round-off differences to
%           [U1,S1,V1] = svd([A D],"econ","vector")
%
%   [U1,S1,V1] = SVDAPPEND(..., Name=Value) additionally specifies options  
%   with one or more name-value arguments:
%
%                Shape - Specifies "columns" or "rows" as the shape of the
%                        appended data in D. If the value is "columns", the
%                        revised SVD is for [A D], and for "rows" the
%                        revised SVD is for [A; D]. Neither [A D] nor
%                        [A; D] are explicitly formed. The default is
%                        "columns".
%
%           WindowSize - Specifies the maximum number of columns or rows to
%                        be used in computing the appended SVD. WindowSize
%                        must be a positive integer and it controls the
%                        memory consumption of the algorithm. New data is
%                        appended, while the oldest data (starting with the
%                        first column or row) is deleted to satisfy
%                        WindowSize before computing the revised SVD. By
%                        default, no data is discarded.
%
%   The following name-value arguments truncate the revised SVD factors U1,
%   S1, V1. Each option results in a specific rank for the revised SVD.
%   Truncation is based on the minimum value among all provided options.
% 
%    AbsoluteTolerance - Truncates singular values in S1 less than or equal
%                        to AbsoluteTolerance. Corresponding singular
%                        vectors in U1 and V1 are also truncated.
%                        AbsoluteTolerance must be a nonnegative real
%                        numeric scalar. By default, nothing is truncated.
%
%    RelativeTolerance - Truncates singular values in S1 less than or equal
%                        to RelativeTolerance*S1(1). Corresponding
%                        singular vectors in U1 and V1 are also truncated.
%                        RelativeTolerance must be a real numeric scalar in
%                        the range [0 1]. By default, nothing is truncated.
%
%              MaxRank - Maximum rank of the revised singular value
%                        decomposition. MaxRank imposes a limit on the
%                        number of singular values in S1 and the number of
%                        singular vectors in U1 and V1. MaxRank must be a
%                        positive integer. By default, there is no limit to
%                        the rank.
%
%   See also SVD, SVDSKETCH, SVDS.

%   Copyright 2023-2024 The MathWorks, Inc.

narginchk(4,Inf);

verifyDataIsNonsparseFloatMatrix(U);
verifyDataIsNonsparseFloatMatrix(S);
verifyDataIsNonsparseFloatMatrix(V);
verifyDataIsNonsparseFloatMatrix(D);

% Only allow matching data types for U, S, V
if ~(isequal(class(U), class(S)) && isequal(class(S), class(V)))
    error(message('MATLAB:svdappend:TypeError'))
end

[mU, nU, mV, nV, mS, nS] = getAndValidateSizes(U, S, V);

[method,windowSize,absTol,relTol,maxRank] = parseInputs(varargin);

% If we add rows, we switch U and V and transpose D, as the algorithm
% focuses on adding columns, and switching back before exiting.
if method=="addrows"
    [U,V] = swap(U,V);
    [mU,mV] = swap(mU,mV);
    [nU,nV] = swap(nU,nV);
    [mS,nS] = swap(mS,nS);
    D = D';
end

% Check number of rows in D and A match, unless A is []
if (mU~=0 || mV~=0) && size(D,1)~=mU
    if method=="addrows"
        error(message('MATLAB:svdappend:UpdateSizeErrorAddRows'))
    else
        error(message('MATLAB:svdappend:UpdateSizeErrorAddCols'))
    end
end
numNewCols = size(D,2);

% If U,S,V are not 0x0, cast D to matching type of U,S,V
if any([mU,nU,mV,nV,mS,nS] ~= 0)
    D = cast(D, "like", U);
end


% Early exit calling SVD on D for the following cases:
%  * numNewCols is larger or equal than windowSize
%  * any of U, S, V are empty
if (numNewCols >= windowSize) || ...
        any([mU,nU,mV,nV,mS,nS] == 0)
    % Only keep last windowSize columns
    D(:, 1:end-windowSize) = [];
    if method=="addrows"
        D = D';
    end
    [U,S,V] = svd(D, 'econ', 'vector');
    if ~isempty([absTol,relTol,maxRank])
        [U,S,V] = svdtruncateImpl(U,S,V,absTol,relTol,maxRank);
    end
    return;
end

% Early exit for non-finites involved in the revision
if ~(allfinite(U) && allfinite(S) && allfinite(V) && allfinite(D))
    
    numColsToReturn = min(size(V,1)+numNewCols, windowSize);
    newRank = min([mU, numColsToReturn, maxRank]);
    
    U = NaN(mU,newRank,class(D));
    V = NaN(numColsToReturn,newRank,class(D));
    S = NaN(newRank,1,class(D));
    if method=="addrows"
        [U,V] = swap(U,V);
    end
    return;
end

% Data is not a vector but S is already a vector, no extraction needed
if isvector(S) && ~(mU==1 || mV==1)
    s = S;
else
    s = matlab.internal.math.diagExtract(S);
end

initRank = numel(s);

% Truncate inputs to be conform with rank
U = matlab.internal.math.viewColumns(U, initRank);
V = matlab.internal.math.viewColumns(V, initRank);

% If no new data is added, just post-process if needed and exit
if isempty(D)
    if ~isempty([absTol,relTol,maxRank])
        [U,S,V] = svdtruncateImpl(U,s,V,absTol,relTol,maxRank);
    else
        S = s;
    end
    if method=="addrows"
        [U,V] = swap(U,V);
    end
    return;
end

% Reorganize columns: determine cols to revise (overwrite), add, or delete
% New size is bigger than windowSize -> front cols get moved to end  
colsToMove = 0;
if windowSize < mV+numNewCols
    colsToMove = mV+numNewCols-windowSize;
end

% How many new cols will be added; negative means deleting cols
colsToAdd =  numNewCols - colsToMove;

% Number of cols to revise, i.e., moved cols that get updated by data in A
colsToRevise = min(colsToMove, numNewCols);
% Number of columns to modify (revise/add/delete)
colsToModify = max(colsToMove, numNewCols);

% Build factors for SVD udpate: Anew = A + X*Y', where X has the data and Y
% is the index into the cols.

% Y has identy of size colsToModify on bottom but has max(n, n+colsToAdd)
% rows in total 
numRowsD = max(mV, mV+colsToAdd) - colsToModify;

Y = [zeros(numRowsD, colsToModify); ...
    eye(colsToModify)];

% Build X holding data:
%   X = [X_revise X_add] 
% or 
%   X = [X_revise X_old]

% X_revise substracts data of cols in D from data in cols of A
if colsToRevise==0
    X_revise = [];
else
    X_revise = D(:, 1:colsToRevise) - (U.*s')*V(1:colsToRevise, :)';
end

if colsToAdd > 0 % Adding cols left that weren't revised
    X = [X_revise D(:, colsToRevise+1:end)];
else 
    % Delete cols that are modified but didn't get revised by new data by
    % adding them negated into D
    X = [X_revise -(U.*s')*V(colsToRevise+1:colsToModify, :)'];
end
% Modify V accordingly
V = [V([colsToMove+1:end, 1:colsToMove],:); zeros(colsToAdd, size(V,2))];

% svdUpdateImpl to update U,S,V 
[U,S,V] = svdUpdateImpl(U,s,V,X,Y,absTol,relTol,maxRank,initRank,colsToAdd,windowSize);

if method=="addrows"
    [U,V] = swap(U,V);
end
end % END svdappend

function [U,S,V] = svdUpdateImpl(U,s,V,X,Y,absTol,relTol,maxRank,initRank,colsToAdd,windowSize)
assert(iscolumn(s));

V(end+colsToAdd+1:end, :) = [];
Y(end+colsToAdd+1:end, :) = [];

V = V .* s';

[qa,ra] = qr([U X], 0);
[qb,rb] = qr([V Y], 0);

C = ra * rb';

[Unew,S,Vnew] = svd(C, 'econ', 'vector');

if ~isempty([absTol,relTol,maxRank])
    [Unew,S,Vnew,initRank] = svdtruncateImpl(Unew,S,Vnew,absTol,relTol,maxRank);
end

U = qa*Unew;
V = qb*Vnew;

% Truncate cols in all factors up to windowSize if needed
if initRank > windowSize
    U = matlab.internal.math.viewColumns(U, windowSize);
    V = matlab.internal.math.viewColumns(V, windowSize);
    S = matlab.internal.math.viewColumns(S.', windowSize).';
end
end % END svdUpdateImpl

function [U,S,V,finalRank] = svdtruncateImpl(U,s,V,absTol,relTol,maxRank)

finalRank = size(U,2);
assert(finalRank==size(V,2));
assert(finalRank==numel(s));

% Minimize finalRank based on absTol, relTol, or rank if provided
if ~isempty(absTol)
    finalRank = min(finalRank, sum(s > absTol));
end

if ~isempty(relTol)
    finalRank = min(finalRank, sum(s > s(1)*relTol));
end

if ~isempty(maxRank)
    finalRank = min(finalRank, maxRank);
end

U = matlab.internal.math.viewColumns(U, finalRank);
V = matlab.internal.math.viewColumns(V, finalRank);
S = (matlab.internal.math.viewColumns(s.', finalRank)).';
end % END svdtruncateImpl

function [method,windowSize,absTol,relTol,maxRank] = parseInputs(args)
% Set defaults
method = "columns";
windowSize = Inf;
absTol = [];
relTol = [];
maxRank = [];

% Parse NVPs if provided
if isempty(args)
    return;
end

nameList = {'Shape', 'WindowSize', 'AbsoluteTolerance', ...
    'RelativeTolerance', 'MaxRank'};

if mod(numel(args), 2) ~= 0
    error(message('MATLAB:svdappend:NameWithoutValue'));
end

for i=1:2:(numel(args))
    indName = strncmpiWithInputCheck(args{i}, nameList);

    if nnz(indName) ~= 1
        % Let validatestring give the error message
        validatestring(args{i}, nameList);
    else
        indName = find(indName);
    end

    value = args{i+1};

    switch indName
        case 1 % Shape
            if matlab.internal.math.partialMatch(value, "columns", 1)
                method = "addcols";
            elseif matlab.internal.math.partialMatch(value, "rows", 1)
                method = "addrows";
            else
                error(message('MATLAB:svdappend:InvalidShapeFlag'))
            end
        case 2 % 'WindowSize'
            if ~(isscalar(value) && isnumeric(value) && isreal(value) && ...
                    fix(value) == value && value > 0)
                error(message('MATLAB:svdappend:InvalidWindowSize'));
            end
            windowSize = double(full(value));
        case 3 % 'AbsoluteTolerance'
            if ~(isscalar(value) && isnumeric(value) && isreal(value) && value >= 0)
                error(message('MATLAB:svdappend:InvalidAbsTol'));
            end
            absTol = double(full(value));
        case 4 % 'RelativeTolerance'
            if ~(isscalar(value) && isnumeric(value) && isreal(value) && ...
                    value >= 0 && value <= 1)
                error(message('MATLAB:svdappend:InvalidRelTol'));
            end
            relTol = double(full(value));
        case 5 % 'MaxRank'
            if ~(isscalar(value) && isnumeric(value) && isreal(value) && ...
                    fix(value) == value && value > 0)
                error(message('MATLAB:svdappend:InvalidMaxRank'));
            end
            maxRank = double(full(value));
    end
end
end % END parseInputs

function index = strncmpiWithInputCheck(arg, list)
% Check that the input is either a row char vector or a scalar string. Use
% that valid input to compare it against a provided list and return the
%index. Return [] if validation failed.
index = [];
if (ischar(arg) && isrow(arg)) || (isstring(arg) && isscalar(arg))
    index = startsWith(list, arg, 'IgnoreCase', true);
end
end

function [B, A] = swap(A, B)
end

function verifyDataIsNonsparseFloatMatrix(A)
if ~isfloat(A) || issparse(A) || ~ismatrix(A)
   error(message('MATLAB:svdappend:TypeError'))
end
end % END strncmpiWithInputCheck

function [mU, nU, mV, nV, mS, nS] = getAndValidateSizes(U, S, V)
% U*S*V' = A (for diag matrix S)
% (U.*S')*V' = A (for column vector S)

% [m, n] = size(A);
[mU, nU] = size(U);
[mV, nV] = size(V);
[mS, nS] = size(S);

r = min(mU,mV);

if nS==1 && mS~=1 && mV ~=1 % S is column vector of non-vector A 
    numS = mS;
    isValidSVD = (mS==r && ...
        (mU==nU && mV==nV || ... % full case
        nU==r && nV==r)) || ...   % econ case
        nU==numS && nV==numS;   % truncated case
else
    numS = min(mS,nS);
    isValidSVD = mU==nU && mV==nV && mS==nU && nS==nV || ... % full case
        nU==r && nV==r && mS==r && nS==r || ...              % econ case
        nU==numS && nV==numS && mS==numS && nS==numS;        % truncated case    
end

if ~isValidSVD
    error(message('MATLAB:svdappend:InvalidUSV'))
end
end % END getAndValidateSizes
