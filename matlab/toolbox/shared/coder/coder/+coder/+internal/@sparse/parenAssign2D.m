function this = parenAssign2D(this, rhs, r, c, alreadySqueezed, sorted)
%MATLAB Code Generation Private Method

% 2D indexing for coder.internal.sparse
% sorted is a boolean indicating whether r and c are sorted

%   Copyright 2016-2023 The MathWorks, Inc.
%#codegen
if nargin < 5
    alreadySqueezed = false;
else
    coder.internal.prefer_const(alreadySqueezed);
end
if nargin < 6
    sorted = false;
else
    coder.internal.prefer_const(sorted);
end
% Handle any cases like s(1:2,3:4) = ones(1,1,2,1,1,1,2);
if ~alreadySqueezed && ~issparse(rhs) && coder.internal.ndims(rhs) > 2
    this = parenAssign2D(this, squeeze(rhs), r, c, true, sorted);
    return
end
validateIndexTypes(r,c);
if ischar(r)
    nr = this.m;
else
    nr = coder.internal.indexInt(numel(r));
end
if ischar(c)
    nc = this.n;
else
    nc = coder.internal.indexInt(numel(c));
end
nAssign = nr*nc;
scalarRhs = isConstScalar(rhs);
scalarR = isConstScalar(r);
scalarC = isConstScalar(c);
vectorRhs = coder.internal.isConst(isvector(rhs)) && isvector(rhs);
vectorLhs = coder.internal.isConst(isvector(this)) && isvector(this);
coder.internal.assert(ismatrix(rhs),'MATLAB:subsassigndimmismatch');
coder.internal.assert(scalarRhs || ...
                      ((scalarR || scalarC) && vectorRhs && sameNumel(rhs,nAssign)) || ...
                      (nr == size(rhs,1) && nc == size(rhs,2)) || ...
                      (vectorRhs && vectorLhs && sameNumel(this,nAssign)), ...
                      'MATLAB:subsassigndimmismatch');
coder.internal.errorIf(isreal(this) && ~isreal(rhs), 'Coder:builtins:LhsRhsComplexMismatch');
isSqueezed = false;
if issparse(r)
    this = parenAssign2D(this,rhs,nonzeros(r),c,isSqueezed,sorted);
elseif issparse(c)
    this = parenAssign2D(this,rhs,r,nonzeros(c),isSqueezed,sorted);
elseif ischar(r) && ischar(c)
    % s(:,:) = x is just a copy
    coder.inline('always');
    this = parenAssignSpan(this,rhs,scalarRhs,nAssign);
elseif ischar(r)
    % s(:,J)
    if vectorRhs && isrow(rhs) && ~isrow(this)
        this = parenAssign2DColumns(this,rhs.',c);
    else
        this = parenAssign2DColumns(this,rhs,c);
    end
elseif ischar(c)
    % s(I,:)
    if vectorRhs && iscolumn(rhs)
        this = parenAssign2DRows(this,rhs.',r,sorted); 
    else
        this = parenAssign2DRows(this,rhs,r,sorted);
    end
else
    this = parenAssign2DNumeric(this,rhs,r,c,sorted); 
end

%--------------------------------------------------------------------------

function this = parenAssignSpan(this,rhs,scalarRhs,nAssign)
this = parenAssignAllSpan(this,rhs,scalarRhs,nAssign,2);

%--------------------------------------------------------------------------

function this = parenAssign2DNumeric(this,rhs,r,c,sorted)
coder.internal.prefer_const(sorted);
validateNumericIndex(ONE,this.m,r);
validateNumericIndex(ONE,this.n,c);
sm = coder.internal.indexInt(numel(r));
sn = coder.internal.indexInt(numel(c));
this = parenAssign2DNumericImpl(this,rhs,r,c,sm,sn,sorted);

%--------------------------------------------------------------------------

function this = parenAssign2DNumericImpl(this,rhs,r,c,sm,sn,sorted)
% In this function, we batch up row indices of same column together.
% We look for two already exising row locations in *this.
% Between these two locations, we know any other rows in between that we
% want to index do not already exist so we can shift things altogether
coder.internal.prefer_const(sorted);
[rhs,r,c] = coder.internal.sortSparseParenAssignInputs(rhs,r,c,sorted);
rhsIter = makeRhsIter(rhs);
for cidx = 1:sn
    col = getIdx(c,cidx);
    pass = ZERO;
    shiftleft = ZERO;
    extraAlloc = ZERO;
    vidx = ONE;
    for ridx = 1:sm
        row = getIdx(r,ridx);
        [rhsv,rhsIter] = nextRhsFromVector(rhs,rhsIter);
        % check for duplicate row entry
        % if so, continue and record the last row entry only
        if ridx ~= sm
            nrow = getIdx(r,ridx+1);
        else
            nrow = ZERO;
        end
        if row == nrow
            if pass ~= 0
                shiftleft = shiftleft + 1;
                pass = pass - 1;
            end
            continue
        end 
        if pass == 0
            [vidx,found] = locBsearch(this.rowidx,row,this.colidx(col),this.colidx(col+1));
            if found
                thisv = this.d(vidx);
            else
                thisv = zeros('like',this.d);
            end
            % look for the next row location that already exists
            if this.colidx(col+1) - vidx > 1 || (this.colidx(col+1) - vidx == 1 && r(ridx) ~= this.m)
                if this.colidx(col+1) - vidx > 1
                    nextrow = this.rowidx(vidx+1);
                else
                    nextrow = this.m + 1;
                end
                for cnt = ridx+1:sm
                    if r(cnt) < nextrow
                        pass = pass + 1;
                    else
                        break;
                    end
                end
            end
            extraAlloc = pass;
            shiftleft = ZERO;
            % make space for potentially (pass+1) new insertion
            nz = coder.internal.indexInt(nnz(this));
            % if row we want to index does not exist
            if thisv == 0
                if nz+coder.internal.indexInt(pass+1) > this.maxnz
                    this = realloc(this,nz+coder.internal.indexInt(max(pass+1,10)),vidx,vidx+1,nz,coder.internal.indexInt(pass+1));
                else
                    this = shiftRowidxAndData(this,vidx+coder.internal.indexInt(pass+2),vidx+1,nz-vidx);
                end
                extraAlloc = extraAlloc + 1;
                vidx = vidx + 1;
            % if row we want to index exist already
            else
                if nz+coder.internal.indexInt(pass) > this.maxnz
                    this = realloc(this,nz+max(pass,10),vidx,vidx+1,nz,pass);
                else
                    this = shiftRowidxAndData(this,vidx+pass+1,vidx+1,nz-vidx);
                end
            end
        else
            % if between two existing row locations
            thisv = zeros('like',this.d);
            pass = pass - 1;
        end

        if thisv == 0 && rhsv == 0
            % if index location is zero and rhs is zero
            shiftleft = shiftleft + 1;
        elseif thisv ~= 0 && rhsv ~= 0
            % if index exists and rhs is non zero
            % just assign value
            this.d(vidx) = rhsv;
            vidx = vidx + 1;
        elseif thisv == 0 % && rhsv ~= 0
            this.d(vidx) = rhsv;
            this.rowidx(vidx) = row;
            vidx = vidx+1;
        else 
            % if thisv ~= 0 && rhsv == 0
            shiftleft = shiftleft + 1;
        end
        if pass == 0
            % increase or decrease colidx
            if extraAlloc - shiftleft > 0
                this = incrColIdx(this,col,coder.internal.indexInt(extraAlloc - shiftleft));
            elseif extraAlloc - shiftleft < 0
                this = decrColIdx(this,col,coder.internal.indexInt(shiftleft-extraAlloc));
            end
            nz = coder.internal.indexInt(nnz(this));
            % check if we shifted too much
            if shiftleft ~= 0
                this = shiftRowidxAndData(this,vidx,vidx+coder.internal.indexInt(shiftleft),nz-vidx+ONE);
            end
        end
    end
end

%--------------------------------------------------------------------------

function this = parenAssign2DColumns(this,rhs,c)
validateNumericIndex(ONE,this.n,c);
sm = this.m;
sn = coder.internal.indexInt(numel(c));
scalarRhs = isConstScalar(rhs);
rhsIter = makeRhsIter(rhs);
for cidx = 1:sn
    col = coder.internal.indexInt(c(cidx));
    nz = coder.internal.indexInt(nnz(this));
    nzColAlloc = this.colidx(col+1) - this.colidx(col);
    idx = this.colidx(col);
    if scalarRhs
        % Just fill in column with value
        [rhsv,rhsIter] = nextRhs(rhs,rhsIter);
        if rhsv == 0
            % Shift left and decrement
            this = shiftRowidxAndData(this,idx,idx+nzColAlloc,nz-nzColAlloc-idx+1);
            this = decrColIdx(this,col,nzColAlloc);
        else
            % Is there space in this column?
            extraCol = this.m - nzColAlloc;
            if extraCol > 0
                % Check to see if we need to allocate more space
                numAlloc = this.maxnz;
                extraAlloc = numAlloc - nz;
                start = this.colidx(col+1);
                if extraAlloc < extraCol
                    num2Alloc = extraCol-extraAlloc;
                    this = realloc(this,numAlloc+num2Alloc,idx-1,start,nz,extraCol);
                else
                    this = shiftRowidxAndData(this,start+extraCol,start,nz-start+1);
                end
                [this,~,rhsIter] = copyNonzeroValues(this,rhsIter,idx,rhs,rhsv);
                this = incrColIdx(this,col,extraCol);
            else
                % Entire column is nonzero so just assign
                for k = idx:this.colidx(col+1)-1
                    this.d(k) = rhsv;
                end
            end
        end
    else
        % Count non-zeros in corresponding chunk of RHS
        nzRhs = countNumnzInColumn(rhs,rhsIter,sm);

        % Is there space in this column?
        if nzColAlloc < nzRhs
            extraCol = nzRhs - nzColAlloc;
            numAlloc = coder.internal.indexInt(nzmax(this));
            extraAlloc =  numAlloc - nz;
            start = this.colidx(col+1);
            if extraAlloc < extraCol
                num2Alloc =  extraCol - extraAlloc;
                this = realloc(this,numAlloc+num2Alloc,idx-1,start,nz,extraCol);
            else
                this = shiftRowidxAndData(this,start+extraCol,start,nz-start+1);
            end
            [this,~,rhsIter] = copyNonzeroValues(this,rhsIter,idx,rhs);
            this = incrColIdx(this,col,extraCol);
        else
            % Sufficient space
            [this,outIdx,rhsIter] = copyNonzeroValues(this,rhsIter,idx,rhs);

            % Shift data and row indices left and adjust column indices if needed
            extraSpace = nzColAlloc - nzRhs;
            if extraSpace > 0
                start = this.colidx(col+1);
                this = shiftRowidxAndData(this,outIdx,start,nz-start+1);
                this = decrColIdx(this,col,extraSpace);
            end
        end
    end
    rhsIter = nextCol(rhsIter);
end

%--------------------------------------------------------------------------

function this = parenAssign2DRows(this,rhs,r,sorted)
coder.internal.prefer_const(sorted);
validateNumericIndex(ONE,this.m,r);
sm = coder.internal.indexInt(numel(r));
sn = this.n;
this = parenAssign2DNumericImpl(this,rhs,r,':',sm,sn,sorted);

%--------------------------------------------------------------------------

function validateIndexTypes(r,c)
validateIndexType(r);
validateIndexType(c);

%--------------------------------------------------------------------------

function y = ONE
y = coder.internal.indexInt(1);

%--------------------------------------------------------------------------

function y = ZERO
y = coder.internal.indexInt(0);

%--------------------------------------------------------------------------

function n = getIdx(idx,k)
% Helper to get index values from either span index, ':', or index vector
coder.inline('always');
if ischar(idx)
    nt = k;
else
    nt = idx(k);
end
n = coder.internal.indexInt(nt);

%--------------------------------------------------------------------------

function this = shiftRowidxAndData(this,outstart,instart,nelem)
if nelem <= zeros('like',nelem)
    return
end
USEMEMMOVE = ~coder.target('MATLAB') && coder.internal.isMemcpyEnabled() && ~coder.internal.isAmbiguousTypes;
if USEMEMMOVE
    this.rowidx = locMemmove(this.rowidx,outstart,instart,nelem);
    this.d = locMemmove(this.d,outstart,instart,nelem);
else
    if outstart >= instart
        for k = nelem-1:-1:0
            this.rowidx(k+outstart) = this.rowidx(k+instart);
            this.d(k+outstart) = this.d(k+instart);
        end
    else
        for k = 0:nelem-1
            this.rowidx(k+outstart) = this.rowidx(k+instart);
            this.d(k+outstart) = this.d(k+instart);
        end
    end
end

%--------------------------------------------------------------------------

function this = incrColIdx(this,col,offs)
for k = col+1:this.n+1
    this.colidx(k) = this.colidx(k)+offs;
end

%--------------------------------------------------------------------------

function this = decrColIdx(this,col,offs)
for k = col+1:this.n+1
    this.colidx(k) = this.colidx(k)-offs;
end

%--------------------------------------------------------------------------

function [this,outIdx,rhsIter] = copyNonzeroValues(this,rhsIter,outStart,rhs,rhsv)
outIdx = outStart;
if nargin == 5
    if rhsv ~= 0
        for k = 1:this.m
            this.rowidx(outIdx) = k;
            this.d(outIdx) = rhsv;
            outIdx = outIdx+1;
        end
    end
elseif issparse(rhs)
    [~,rhsCol] = currentRowCol(rhsIter);
    thisRow = ONE;
    prevRhsRow = ONE;
    for rhsIdx = rhs.colidx(rhsCol):rhs.colidx(rhsCol+1)-1
        rhsRow = rhs.rowidx(rhsIdx);
        thisRow = thisRow+(rhsRow-prevRhsRow);
        this.d(outIdx) = rhs.d(rhsIdx);
        this.rowidx(outIdx) = thisRow;
        outIdx = outIdx+1;
        prevRhsRow = rhsRow;
    end
else
    for k = 1:this.m
        [rhsv,rhsIter] = nextRhs(rhs,rhsIter);
        if rhsv ~= 0
            this.rowidx(outIdx) = k;
            this.d(outIdx) = rhsv;
            outIdx = outIdx+1;
        end
    end
end

%--------------------------------------------------------------------------

function y = locMemmove(y,outstart,instart,nelem)
% Call memmove
voidt = coder.opaque('void');
ignr = coder.opaquePtr('void');
% memmove header will be included by CRL, so don't put include at this point.
ignr = coder.ceval('-jit','memmove', ...
                   coder.ref(y(outstart),'like',voidt), ...
                   coder.rref(y(instart),'like',voidt), ...
                   coder.internal.csizeof(coder.internal.scalarEg(y),nelem)); %#ok<NASGU>

%--------------------------------------------------------------------------

function this = realloc(this,numAllocRequested,ub1,lb2,ub2,offs)
rowidxt = this.rowidx;
dt = this.d;
[~,overflow] = coder.internal.bigProduct(this.m, this.n, true);
if overflow == 0
    numAlloc = max2(ONE,min2(numAllocRequested,coder.internal.indexInt(numel(this))));
else
    numAlloc = max2(ONE,min2(numAllocRequested,intmax(coder.internal.indexIntClass)));
end
this.rowidx = zeros(numAlloc,1,'like',this.rowidx);
this.d = zeros(numAlloc,1,'like',this.d);
this.maxnz = numAlloc;
this.matlabCodegenUserReadableName = makeUserReadableName(this);
for k = 1:ub1
    this.rowidx(k) = rowidxt(k);
    this.d(k) = dt(k);
end

for k = lb2:ub2
    this.rowidx(k+offs) = rowidxt(k);
    this.d(k+offs) = dt(k);
end

%--------------------------------------------------------------------------

function iter = makeRhsIter(rhs)
iter.idx = ONE;
iter.col = ONE;
iter.row = ONE;
scalarRhs = isConstScalar(rhs);
if scalarRhs
    iter.advance = @addNone;
else
    iter.advance = @addOne;
end

%--------------------------------------------------------------------------

function p = isConstScalar(x)
% Is x a fixed-size scalar not including ':'?
coder.inline('always');
p = ~ischar(x) && coder.internal.isConst(isscalar(x)) && isscalar(x);

%--------------------------------------------------------------------------

function [r,c] = currentRowCol(iter)
r = iter.row;
c = iter.col;

%--------------------------------------------------------------------------

function [v,iter] = nextRhs(rhs,iter)
scalarRhs = isConstScalar(rhs);
if scalarRhs
    if issparse(rhs)
        v = rhs.d(1);
    else
        v = rhs(1);
    end
elseif issparse(rhs)

    if iter.idx < rhs.colidx(iter.col+1) && ...
            iter.idx <= nnzInt(rhs) && ...
            iter.row == rhs.rowidx(iter.idx)
        v = rhs.d(iter.idx);
        iter.idx = iter.advance(iter.idx);
    else
        v = zeros('like',rhs.d);
    end
    iter.row = iter.advance(iter.row);
else
    v = rhs(iter.idx);
    iter.idx = iter.advance(iter.idx);
    iter.row = iter.advance(iter.row);
end


%--------------------------------------------------------------------------

function[v, iter] = nextRhsFromVector(rhs, iter)
[v, iter] = nextRhs(rhs, iter);
if issparse(rhs) && iter.row > size(rhs,1)
    iter = nextCol(iter);
end


%--------------------------------------------------------------------------

function iter = nextCol(iter)
iter.col = iter.advance(iter.col);
iter.row = ONE;

%--------------------------------------------------------------------------

function y = addOne(y)
coder.inline('always');
y = y+1;

%--------------------------------------------------------------------------

function y = addNone(y)
coder.inline('always');

%--------------------------------------------------------------------------

function nz = countNumnzInColumn(rhs,rhsIter,sm)
if issparse(rhs)
    [~,col] = currentRowCol(rhsIter);
    nz = rhs.colidx(col+1)-rhs.colidx(col);
else
    nz = zeros('like',ONE);
    for k = 1:sm
        [rhsv,rhsIter] = nextRhs(rhs,rhsIter);
        if rhsv == 0
        else
            nz = nz+1;
        end
    end
end

%--------------------------------------------------------------------------

function y = min2(a,b)
if a <= b
    y = a;
else
    y = b;
end

%--------------------------------------------------------------------------

function p = sameNumel(a,n)
sa = coder.internal.indexInt(size(a));
[lowOrder,highOrder] = coder.internal.bigProduct(sa(1),sa(2),false);
if highOrder == 0
    p = lowOrder == n;
else
    p = false;
end

%--------------------------------------------------------------------------
