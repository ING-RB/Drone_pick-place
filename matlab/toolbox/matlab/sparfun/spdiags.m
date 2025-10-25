function [res1,res2] = spdiags(arg1,arg2,arg3,arg4)
%SPDIAGS Sparse matrix formed from diagonals.
%   SPDIAGS, which generalizes the function "diag", deals with three
%   matrices, in various combinations, as both input and output.
%
%   [B,d] = SPDIAGS(A) extracts all nonzero diagonals from the m-by-n
%   matrix A. B is a min(m,n)-by-p matrix whose columns are the p nonzero
%   diagonals of A. d is a vector of length p whose integer components
%   specify the diagonals in A.
%
%   B = SPDIAGS(A,d) extracts the diagonals specified by d.
%
%   A = SPDIAGS(B,d,A) replaces the diagonals of A specified by d with
%       the columns of B. B can be a matrix, a column vector, a row vector, 
%       or a scalar. The output is sparse.
%
%   A = SPDIAGS(B,d,m,n) creates an m-by-n sparse matrix from the
%       columns of B and places them along the diagonals specified by d.
%
%   Roughly, if B is a matrix, A, B and d are related by
%       for k = 1:p
%           B(:,k) = diag(A,d(k))
%       end
%
%   Some elements of B, corresponding to positions "outside" of A, are not
%   actually used. They are not referenced when B is an input and are set
%   to zero when B is an output. See the documentation for an illustration
%   of this behavior.
%
%   See also DIAG, SPEYE.

%   Rob Schreiber
%   Copyright 1984-2024 The MathWorks, Inc.

if nargin <= 2
    % Extract diagonals
    A = arg1;
    if nargin == 1
        % Find all nonzero diagonals
        [i,j] = find(A);
        % Compute d = unique(d) without extra function call
        d = sort(j-i);
        d = d(diff([-inf; d(:)])~=0);
        d = d(:);
    else
        % Diagonals are specified
        if ~isIntOrInf(arg2)
            error(message('MATLAB:spdiags:InvalidDiagonal'));
        end
        d = arg2(:);
    end
    [m,n] = size(A);
    p = length(d);
    B = zeros(min(m,n),p,class(A));
    for k = 1:p
        if m >= n
            i = max(1,1+d(k)):min(n,m+d(k));
        else
            i = max(1,1-d(k)):min(m,n-d(k));
        end
        B(i,k) = diagk(A,d(k));
    end
    res1 = B;
    res2 = d;
end

if nargin >= 3
    B = arg1;
    if ~isInt(arg2)
        error(message('MATLAB:spdiags:InvalidDiagonal'));
    end
    d = arg2(:);
    p = length(d);
    if nargin == 3 % Replace specified diagonals
        A = arg3;
        [m,n] = size(A);
    else           % Create new matrix with specified diagonals
        if ~isNonnegativeInt(arg3) || ~isNonnegativeInt(arg4)
            error(message('MATLAB:spdiags:InvalidMN'));
        end
        m = double(arg3);
        n = double(arg4);
    end

    % Check size of B. Should be min(m,n)-by-p for matrix,
    % min(m,n) for column vector, p for row vector, or a scalar.
    % For backwards compatibility, only error if the code would
    % previously have errored out in the indexing expression.
    [mB, nB] = size(B);
    maxIndexRows = max(max(1,1-d), min(m,n-d)) + (m>=n)*d;
    maxIndexRows(max(1,1-d) > min(m,n-d)) = 0;
    if (mB ~= 1 && any(maxIndexRows > mB)) || (nB ~= 1 && nB < p)
        if nargin == 3
            error(message('MATLAB:spdiags:InvalidSizeBThreeInput'));
        else
            error(message('MATLAB:spdiags:InvalidSizeBFourInput'));
        end
    end

    % Compute indices and values of sparse matrix with given diagonals
    if nargin == 3
        % Insert diagonals into existing matrix A.
        res1 = makeSparseGeneral(B, d, A);
    else
        % Create new A with diagonals
        B = full(B);

        % Trim or expand B to be the correct size for makeSparsePresorted
        minMN = min(m,n);
        if mB ~= 1 && mB ~= minMN
            B = resize(B,minMN,"Dimension",1);
        end
        if nB ~= 1 && nB ~= p
            B = resize(B,p,"Dimension",2);
        end
        
        if m < n
            % Compute transpose of A, then transpose before returning.
            d = -d;
        end
        
        % Sort d in descending order and reorder B accordingly:
        if issorted(d, 'descend')
        elseif issorted(d, 'ascend')
            d = flip(d);
            B = flip(B, 2);
        else
            [d, ind] = sort(d, 'descend');
            if ~iscolumn(B)
                B = B(:, ind);
            end
        end

        % Merge duplicate diagonals
        hasDuplicates = nnz(diff(d)) < length(d)-1;
        if hasDuplicates
            [B, d] = mergeDuplicateDiagonals(B, d);
        end

        if ~matlab.internal.feature('SingleSparse') && isa(B, 'single')
            B = double(B);
        end
        
        if m >= n
            res1 = matlab.internal.sparse.makeSparsePresorted(B, double(d), m, n);
        else
            % Compute transpose of A, then transpose before returning.
            res1 = matlab.internal.sparse.makeSparsePresorted(B, double(d), n, m);
            res1 = res1.';
        end
    end
end
end


function A = makeSparseGeneral(B, d, A)
% Construct sparse matrix by inserting
% diagonals into existing matrix A.

[m, n] = size(A);
p = length(d);

% Precompute number of nonzeros (parts of each diagonal that overlap with
% the matrix) and allocate inputs I, J and V for sparse
nz = sum(max(0, min(m, n-d) - max(1, 1-d) + 1));
I = zeros(nz, 1);
J = zeros(nz, 1);

prototype = full(zeros(1, "like", A));
V = zeros(nz, 1, "like", prototype);

% Fill in the diagonals
offset = 1;
if isscalar(B)
    for k = 1:p
        % Append new d(k)-th diagonal to compact form
        for i=max(1, 1-d(k)):min(m, n-d(k))
            I(offset) = i;
            J(offset) = i + d(k);
            V(offset) = B;
            offset = offset + 1;
        end
    end
elseif isrow(B)
    for k = 1:p
        % Append new d(k)-th diagonal to compact form
        for i=max(1, 1-d(k)):min(m, n-d(k))
            I(offset) = i;
            J(offset) = i + d(k);
            V(offset) = B(k);
            offset = offset + 1;
        end
    end
elseif iscolumn(B)
    for k = 1:p
        % Append new d(k)-th diagonal to compact form
        for i=max(1, 1-d(k)):min(m, n-d(k))
            I(offset) = i;
            J(offset) = i + d(k);
            if m >= n
                V(offset) = B(i + d(k));
            else
                V(offset) = B(i);
            end
            offset = offset + 1;
        end
    end
else
    for k = 1:p
        % Append new d(k)-th diagonal to compact form
        for i=max(1, 1-d(k)):min(m, n-d(k))
            I(offset) = i;
            J(offset) = i + d(k);
            if m >= n
                V(offset) = B(i + d(k), k);
            else
                V(offset) = B(i, k);
            end
            offset = offset + 1;
        end
    end
end

if nnz(A) > 0
    % Process A in compact form
    [Iold,Jold,Vold] = find(A);
    
    % Delete current d(k)-th diagonal, k=1,...,p
    i = any((Jold(:) - Iold(:)) == d', 2);
    Iold(i) = [];
    Jold(i) = [];
    Vold(i) = [];
    
    % Combine new diagonals and non-diagonal entries of original matrix
    I = [I(:); Iold(:)];
    J = [J(:); Jold(:)];
    V = [V(:); Vold(:)];
end

A = sparse(I, J, V, m, n);
end


function tf = isInt(X)
% Check if X is an integer array
tf = (isnumeric(X) || islogical(X)) && isreal(X) && allfinite(X) && all(fix(X)==X,'all');
end


function tf = isIntOrInf(X)
% Check if X is an integer array allowing values of inf
tf = (isnumeric(X) || islogical(X)) && isreal(X) && ~anynan(X) && all(fix(X)==X,'all');
end


function tf = isNonnegativeInt(X)
% Check if X is a non-negative integer scalar
tf = isscalar(X) && (isnumeric(X) || islogical(X)) && isreal(X) && X>=0 && isfinite(X) && fix(X)==X;
end


function D = diagk(X,k)
% DIAGK  K-th matrix diagonal.
% DIAGK(X,k) is the k-th diagonal of X, even if X is a vector.
D = matlab.internal.math.diagExtract(X,k);
end


function [BinMerged, dMerged] = mergeDuplicateDiagonals(Bin, d)
% Combine columns addressed to the same diagonal
if ~iscolumn(Bin)
    [dMerged, ~, input2output] = unique(d, 'stable');
    M = sparse(1:length(d), input2output, 1);
    BinMerged = Bin * M;
else
    [dMerged, ~, input2output] = unique(d, 'stable');
    repetitions = accumarray(input2output(:), 1);
    BinMerged = Bin .* repetitions';
end

if islogical(Bin)
    BinMerged = logical(BinMerged);
end
end