function B = repmat(A, varargin)
%#codegen

%   Copyright 2017-2018 The MathWorks, Inc.
coder.internal.prefer_const(varargin);
if ~issparse(A)
    tmp = cell(1, nargin-1);
    for i= coder.unroll(1:nargin-1)
        tmp{i} = full(varargin{i});
    end
    B = repmat(A, tmp{:});
    return;
end
narginchk(2,Inf);
coder.internal.assert(~issparse(A) || nargin < 4, 'MATLAB:repmat:NdSparseOutput');
coder.internal.assertValidSizeArg(varargin{:});

if nargin == 2
    if isscalar(varargin{1})
        B = repmat(A, varargin{1}, varargin{1});
    else
        coder.internal.errorIf(nargin==2 && ...
            numel(varargin{1}) > 2,...
            'MATLAB:repmat:NdSparseOutput');
        B = repmat(A, varargin{1}(1), varargin{1}(2) );
    end
    return;
end

MAXI = intmax(coder.internal.indexIntClass);
coder.internal.assert(varargin{1} < intmax(coder.internal.indexIntClass)...
    && varargin{2} < intmax(coder.internal.indexIntClass),...
    'Coder:toolbox:SparseMaxSize', MAXI);

r1 = coder.internal.indexInt(varargin{1});
r2 = coder.internal.indexInt(varargin{2});

B = coder.internal.sparse.spallocLike(A.m*r1, A.n*r2, nnzInt(A)*r1*r2, A);

if isempty(B)
   return;
end

B = repdown(A,B,r1);
B = repright(B, r2, A.n);

coder.internal.sparse.sanityCheck(B);
end



function B = repdown(A,B,m)
coder.internal.prefer_const(m);

B.colidx(1) = coder.internal.indexInt(1);
writeHead = coder.internal.indexInt(1);
for ci = 1:A.n
    B.colidx(ci+1) = B.colidx(ci) + (A.colidx(ci+1) - A.colidx(ci))*m;
    
    firstRow = A.colidx(ci);
    numelThisCol = A.colidx(ci+1) - A.colidx(ci);
    
    if numelThisCol > 0 
        for repetition = 1:m
            repetitionAdjustment = (repetition-1)*A.m;
            for i = 0:numelThisCol-1
                B.d(i+writeHead) = A.d(firstRow+i);
                B.rowidx(i+writeHead) = A.rowidx(firstRow+i) + repetitionAdjustment;
            end
            
            writeHead = writeHead+numelThisCol;
        end
    end
end

end



function B = repright(B,n, An)
coder.internal.prefer_const(n, An);

nnz = B.colidx(An+1)-1;

for repetition = 1:n-1
    for i=1:nnz
        B.rowidx(i+nnz*repetition) = B.rowidx(i);
        B.d(i+nnz*repetition) = B.d(i);
    end

    for i=1:An
        B.colidx(An*repetition + i) = B.colidx(i) + repetition*nnz;
    end
end
B.colidx(end) = nnz*n+1;


end
