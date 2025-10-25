function s = parenReference1D(this,linidx)
%MATLAB Code Generation Private Method

% 1D indexing for coder.internal.sparse

%   Copyright 2016-2024 The MathWorks, Inc.
%#codegen

validateIndexTypeHelper(linidx);
if issparse(linidx)
    s = parenReference1D(this,reshape(nonzeros(linidx),linidx.m,linidx.n));
elseif ischar(linidx)
    % s(:)
    s = parenReference1DColon(this);
else
    % s(I)
    s = parenReference1DNumeric(this,linidx(:,:));
end

%--------------------------------------------------------------------------

function s = parenReference1DColon(this)
% Handle indexing: s(:)
[ns,overflow] = coder.internal.bigProduct(this.m,this.n, false);
coder.internal.assert(overflow == 0,...
                      'Coder:toolbox:SparseColonOverflow');
nz = coder.internal.indexInt(nnz(this));
s = coder.internal.sparse.nullcopyLike(ns,coder.internal.indexInt(1),nz,coder.internal.scalarEg(this.d));
s.colidx(1) = 1;
s.colidx(end) = nz+1;
for k = 1:nz
    s.d(k) = this.d(k);
end

% Eliminate unnecessary initialization
s.rowidx = coder.nullcopy(s.rowidx);

for c = 1:this.n
    ridx = this.colidx(c);
    offs = (c-1)*this.m;
    while ridx < this.colidx(c+1)
        s.rowidx(ridx) = offs+this.rowidx(ridx);
        ridx = ridx+1;
    end
end

%--------------------------------------------------------------------------

function s = parenReference1DNumeric(this,linidx)
% Handle indexing: s(I)
[~,overflow] = coder.internal.bigProduct(this.m,this.n, true);
if overflow == 0
    validateNumericIndex(ONE,this.m*this.n,linidx);
else
    validateNumericIndex(ONE,intmax(coder.internal.indexIntClass),linidx);

end
% Intentionally flatten dimensions 2-ndims(linidx)
[midx,nidx] = size(linidx);
nrow = coder.internal.indexInt(midx);
ncol = coder.internal.indexInt(nidx);
if coder.internal.isConst(isvector(this)) && isvector(this) && ...
        coder.internal.isConst(isvector(linidx)) && isvector(linidx)
    if ~haveSameOrientation(this,linidx) && mayBeScalar(this)
        coder.internal.indexShapeCheck(size(this),size(linidx),2, 'v', 'v');
    end
    if coder.internal.isConst(isrow(this)) && isrow(this)
        sm = ONE;
        sn = nrow*ncol;
    else
        sm = nrow*ncol;
        sn = ONE;
    end
else
    if mayBeVector(this) && mayBeVector(linidx)
        coder.internal.indexShapeCheck(size(this),size(linidx),1, 'm', 'm');
    end
    sm = nrow;
    sn = ncol;
end

s = coder.internal.sparse.nullcopyLike(sm,sn,1,this);
ub = numel(linidx);
ONENC = coder.internal.ignoreRange(ZERO);
assert(ONENC <= ub || ub == 0); %<HINT>
s.d = zeros(ONENC,1,'like',this.d);
s.rowidx = zeros(ONENC,1,'like',this.rowidx);
s.colidx = zeros(coder.internal.ignoreRange(sn+1),1,'like',this.rowidx);
k = ONE;
s.colidx(1) = 1;
colNnz = ONE;
for cidx = 1:sn
    for ridx = 1:sm
        [row,col] = ind2sub(size(this),coder.internal.indexInt(linidx(k)));
        [idx,found] = locBsearch(this.rowidx,row,this.colidx(col),this.colidx(col+1));
        if found
            s.d = [s.d; this.d(idx)];
            s.rowidx = [s.rowidx; ridx];
            colNnz = colNnz+1;
        end
        k = k+1;
    end
    s.colidx(cidx+1) = colNnz;
end

if isempty(s.d)
    s.d = zeros(coder.internal.ignoreRange(1), 1, 'like',this.d);
    s.rowidx = zeros(coder.internal.ignoreRange(1), 1, 'like', ONE);
end
s.maxnz = max2(s.colidx(end)-1,ONE);
s.matlabCodegenUserReadableName = makeUserReadableName(s);

%--------------------------------------------------------------------------

function p = haveSameOrientation(a,b)
nda = coder.internal.ndims(a);
ndb = coder.internal.ndims(b);
nd = min2(nda,ndb);
for k = coder.unroll(1:nd)
    if (constSize(a,k) == 1) ~= (constSize(b,k) == 1)
        p = false;
        return
    end
end
for k = coder.unroll(nd+1:nda)
    if constSize(a,k) ~= 1
        p = false;
        return
    end
end
for k = coder.unroll(nd+1:ndb)
    if constSize(b,k) ~= 1
        p = false;
        return
    end
end
p = true;

%--------------------------------------------------------------------------

function n = constSize(x,d)
coder.internal.prefer_const(d);
if coder.internal.isConst(size(x,d))
    n = coder.internal.indexInt(size(x,d));
else
    n = coder.internal.indexInt(-1);
end

%--------------------------------------------------------------------------

function p = mayBeScalar(x)
for k = coder.unroll(1:coder.internal.ndims(x))
    if coder.internal.isConst(size(x,k)) && size(x,k) ~= 1
        p = false;
        return
    end
end
p = true;

%--------------------------------------------------------------------------

function p = mayBeVector(x)
if coder.internal.isConst(size(x))
    p = isvector(x);
else
    numNonSingletonDim = ZERO;
    for k = coder.unroll(1:coder.internal.ndims(x))
        if coder.internal.isConst(size(x,k)) && size(x,k) > 1
            numNonSingletonDim = numNonSingletonDim+1;
        end
    end
    p = numNonSingletonDim <= 1;
end

%--------------------------------------------------------------------------

function y = min2(a,b)
if a <= b
    y = a;
else
    y = b;
end

%--------------------------------------------------------------------------

function validateIndexTypeHelper(linidx)
coder.internal.assert(coder.internal.ndims(linidx)==2, 'MATLAB:ndFullOnly');
validateIndexType(linidx);

%--------------------------------------------------------------------------
