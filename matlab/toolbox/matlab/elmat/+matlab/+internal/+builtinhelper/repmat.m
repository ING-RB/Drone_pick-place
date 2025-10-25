function B = repmat(A, M, varargin)
%REPMAT Replicate and tile an array.
%   B = REPMAT(A,M,N) or B = REPMAT(A,[M,N]) creates a large matrix B 
%   consisting of an M-by-N tiling of copies of A. If A is a matrix, 
%   the size of B is [size(A,1)*M, size(A,2)*N].
%
%   B = REPMAT(A,N) creates an N-by-N tiling.  
%   
%   B = REPMAT(A,P1,P2,...,Pn) or B = REPMAT(A,[P1,P2,...,Pn]) tiles the array 
%   A to produce an n-dimensional array B composed of copies of A. The size 
%   of B is [size(A,1)*P1, size(A,2)*P2, ..., size(A,n)*Pn].
%   If A is m-dimensional with m > n, an m-dimensional array B is returned.
%   In this case, the size of B is [size(A,1)*P1, size(A,2)*P2, ..., 
%   size(A,n)*Pn, size(A, n+1), ..., size(A, m)].

%   Copyright 1984-2024 The MathWorks, Inc.

if isa(A, 'function_handle')
    error(message('MATLAB:err_non_scalar_function_handles'));
end

if nargin <= 2
    if isscalar(M)
        checkSizesType(M);
        siz = [M M];
    elseif ~isempty(M) && isrow(M)
        checkSizesType(M);
        siz = M;
    else
        error(message('MATLAB:repmat:invalidReplications'));
    end
    siz = double(full(siz));
else % nargin > 2
    siz = zeros(1,nargin-1);
    if isscalar(M)
        siz(1) = double(full(checkSizesType(M)));
    else
        error(message('MATLAB:repmat:invalidReplications'));
    end
    for idx = 2:nargin-1
        arg = varargin{idx-1};
        if isscalar(arg)
            siz(idx) = double(full(checkSizesType(arg)));
        else
            error(message('MATLAB:repmat:invalidReplications'));
        end
    end
end

if isscalar(A) && ~isobject(A)
    B = A(ones(siz,'int8'));
elseif ismatrix(A) && numel(siz) == 2
    [m,n] = size(A);
    if (m == 1 && siz(2) == 1)
        B = A(ones(siz(1), 1), :);
    elseif (n == 1 && siz(1) == 1)
        B = A(:, ones(siz(2), 1));
    else
        mind = (1:m)';
        nind = (1:n)';
        mind = mind(:,ones(1,siz(1)));
        nind = nind(:,ones(1,siz(2)));
        B = A(mind,nind);
    end
else
    Asiz = size(A);
    Asiz = [Asiz ones(1,length(siz)-length(Asiz))];
    siz = [siz ones(1,length(Asiz)-length(siz))];
    subs = cell(1,length(Asiz));
    for i=length(Asiz):-1:1
        ind = (1:Asiz(i))';
        subs{i} = ind(:,ones(1,siz(i)));
    end
    B = A(subs{:});
end

%-----------------------------------------------------------------------
function siz = checkSizesType(siz)
if ~(isnumeric(siz) || islogical(siz))
    throwAsCaller(MException(message('MATLAB:repmat:nonNumericReplications')));
end
if ~isreal(siz)
    throwAsCaller(MException(message('MATLAB:repmat:complexReplications')));
end
if ~(allfinite(siz) && all(round(siz) == siz))
    throwAsCaller(MException(message('MATLAB:repmat:invalidReplications')));
end
