function s = parenReference2D(this,r,c)
%MATLAB Code Generation Private Method

% 2D indexing for coder.internal.sparse

%   Copyright 2016-2024 The MathWorks, Inc.
%#codegen

validateIndexTypes(r,c);
if issparse(r)
    s = parenReference2D(this,nonzeros(r),c);
elseif issparse(c)
    s = parenReference2D(this,r,nonzeros(c));
elseif ischar(r) && ischar(c)
    % s(:,:) is just a copy
    coder.inline('always');
    s = this;
elseif ischar(r)
    % s(:,J)
    s = parenReference2DColumns(this,c);
elseif ischar(c)
    % s(I,:)
    s = parenReference2DRows(this,r);
else
    s = parenReference2DNumeric(this,r,c);
end

%--------------------------------------------------------------------------

function s = parenReference2DNumeric(this,r,c)
% Handle indexing: s(r,c) for non-logical arbitrary r and c
validateNumericIndex(ONE,this.m,r);
validateNumericIndex(ONE,this.n,c);
sm = coder.internal.indexInt(numel(r));
sn = coder.internal.indexInt(numel(c));

% If rowids being extracted are strictly ascending, the final matrix can be
% formed in O(nnz).
[isRowIdxSorted,d] = isSortedIdx(r);

if isRowIdxSorted
    s = parenReference2DSortedRowIdx(this,r,c,sm,sn,d);
else
    % If both the inputs are permutations, the output matrix can be formed with
    % a time complexity proportional to nnz.
    isRowAPerm = isPermutation(r, this.m);
    isColAPerm = isPermutation(c, this.n);
    s = parenReference2DNumericImpl(this,r,c,sm,sn,isRowAPerm,isColAPerm);
end

%--------------------------------------------------------------------------

function s = parenReference2DNumericImpl(this,r,c,sm,sn,isRowAPerm,isColAPerm)
s = coder.internal.sparse();
ub = sm*sn;
ZERONC = coder.internal.ignoreRange(ZERO);
assert(ZERONC <= ub || ub == coder.internal.indexInt(0)); %<HINT>
s.d = zeros(ZERONC,1,'like',this.d);
s.colidx = zeros(coder.internal.ignoreRange(sn+1),1,'like',this.rowidx);
s.colidx(1) = 1;

% Use malloc, size of output is unknown when random access is performed.
rowidx = zeros(ZERONC,1,'like',this.rowidx); 

if isRowAPerm && isColAPerm
    % This branch is executed when the rows are permuted or when both rows and
    % cols are permuted. In case of only cols being permuted a sort on row
    % index is not needed, so parenReference2DColumns is used.
    
    % Using coder.internal.ignoreRange to prevent out-of-bounds errors when
    % indices are compile-time constants.
    pinv = coder.nullcopy(zeros(1,coder.internal.ignoreRange(numel(r)),'like',r));
    pinv(r) = 1:numel(r); % Use numel(r) to prevent 
                % size errors when 'r' is  not a permutation of 1:this.m
    nd = ONE;
    % Row and column permutation can be performed by iterating over only the
    % nnz elements and then sorting each row index.
    for k = 1:this.n
        col = getIdx(c,k);
        s.colidx(k) = nd;
        for j = (this.colidx(col+1)-1):-1:this.colidx(col)
            s.d = [s.d; this.d(j)];
            rowidx = [rowidx; pinv(this.rowidx(j))]; %#ok<AGROW>
            nd = nd + ONE;
        end
        % Sort the permuted data by row in the current column
        numNZInCol = this.colidx(col+1)-this.colidx(col);
        idx = (s.colidx(k)-1) + (1:numNZInCol)';
        fh = @(i,j) sortDataInColByRowIdx(i, j, rowidx);
        sortedIdx = coder.internal.quicksort(idx, ONE, numNZInCol, fh);
        assert(numel(idx) == numel(sortedIdx)); %<HINT>
        rowidx(idx) = rowidx(sortedIdx);
        s.d(idx) = s.d(sortedIdx);
    end
    s.rowidx = rowidx;
    s.colidx(end) = nd;
else
    colNnz = ONE;
    
    % Calling internal version to get second output as indexInt.
    rs = coder.internal.indexInt(r(:));
    [rs, rsid] = coder.internal.sort(rs);

    for cidx = ONE:sn
        col = getIdx(c,cidx);
        s.colidx(cidx) = colNnz;
        if sm % for empties just fill up the colidx.
            for j = this.colidx(col):this.colidx(col+1)-1
                rid = this.rowidx(j);
                if rid == rs(end) % Edge case, coder.internal.bsearch 
                    % ignores last element
                    nid = sm;
                    found = true;
                else
                    [nid, found] = locBsearch(rs,rid,ONE,sm);
                end
                if found
                    % bsearch returns the largest index that doesn't compare
                    % less than.
                    while(nid > ZERO && rid == rs(nid))
                        % Fill up all the occurances of this row, non-zero
                        % in the output matrix. 
                        s.d = [s.d; this.d(j)];
                        rowidx = [rowidx; rsid(nid)]; %#ok<AGROW>
                        colNnz = colNnz + ONE;
                        nid = nid - ONE;
                    end
                end
            end
            % Sort the data by row in the current column
            numNZInCol = colNnz - s.colidx(cidx);
            idx = (s.colidx(cidx)-1) + (1:numNZInCol)';
            fh = @(i,j) sortDataInColByRowIdx(i, j, rowidx);
            sortedIdx = coder.internal.quicksort(idx, ONE, numNZInCol, fh);
            assert(numel(idx) == numel(sortedIdx)); %<HINT>
            rowidx(idx) = rowidx(sortedIdx);
            s.d(idx) = s.d(sortedIdx);
        end
    end
    s.rowidx = rowidx;
    s.colidx(end) = colNnz;
end

snnz = nnzInt(s);
if snnz == 0
    s.rowidx = ones(coder.internal.ignoreRange(1),1, 'like', ONE);
    s.d = zeros(coder.internal.ignoreRange(1),1, 'like',this.d);
end
s.m = sm;
s.n = sn;
s.maxnz = max2(snnz,ONE);
s.matlabCodegenUserReadableName = makeUserReadableName(s);

%--------------------------------------------------------------------------

function s = parenReference2DSortedRowIdx(this,r,c,sm,sn,d)
% Extract a sub matrix from given sparse matrix
s = coder.internal.sparse();
ub = sm*sn;
ZERONC = coder.internal.ignoreRange(ZERO);
assert(ZERONC <= ub || ub == coder.internal.indexInt(0)); %<HINT>

s.colidx = zeros(coder.internal.ignoreRange(sn+1),1,'like',this.colidx);
s.colidx(coder.internal.ignoreRange(ONE)) = ONE;

rowidx = zeros(ZERONC,1,'like',this.rowidx); % preserve size of rowidx created
                                        % in parenReference2DNumericImpl branch
s.d = zeros(ZERONC,1,'like',this.d);

nd = ONE;
rowStart = coder.internal.indexInt(r(coder.internal.ignoreRange(ONE)));
rowEnd = coder.internal.indexInt(r(coder.internal.ignoreRange(sm)));
for k = 1:sn
    col = getIdx(c,k);
    s.colidx(k) = nd;
    for j = this.colidx(col):this.colidx(col+1)-1
        thisrid = this.rowidx(j);
        if thisrid >= rowStart && thisrid <= rowEnd
            if d == MONE
                if thisrid == rowEnd 
                    % Special case last element, bsearch assumes element
                    % to be searched is less than last element of array.
                    rid = sm;
                else
                    rid = coder.internal.bsearch(r,thisrid,ONE,sm);
                end
            else
                rid = coder.internal.indexDivide(thisrid-rowStart,d)+ONE;
            end
            if r(rid) == thisrid % Check if bsearch resulted in a match
                rowidx = [rowidx; rid]; %#ok<AGROW>
                s.d = [s.d; this.d(j)];
                nd = nd + ONE;
            end
        end
    end
end

s.rowidx = rowidx;
s.colidx(end) = nd;

snnz = nnzInt(s);
if snnz == 0
    s.rowidx = ones(coder.internal.ignoreRange(1),1,'like',ONE);
    s.d = zeros(coder.internal.ignoreRange(1),1,'like',this.d);
end
s.m = sm;
s.n = sn;
s.maxnz = max2(snnz,ONE);
s.matlabCodegenUserReadableName = makeUserReadableName(s);

%--------------------------------------------------------------------------

function s = parenReference2DColumns(this,c)
% Handle indexing: s(:,c) for numeric c
validateNumericIndex(ONE,this.n,c);
sm = this.m;
sn = coder.internal.indexInt(numel(c));
ub = sm*sn;

% Compute output sizes
nd = coder.internal.indexInt(0);
for cidx = 1:sn
    col = coder.internal.indexInt(c(cidx));
    nd = nd + (this.colidx(col+1) - this.colidx(col));
end
assert(nd <= ub || ub == coder.internal.indexInt(0)); %<HINT>
s = coder.internal.sparse.spallocLike(sm, sn, nd, this);
if nd == 0
    % All zero sparse
    return
end
outIdx = ONE;
for cidx = 1:sn
    col = coder.internal.indexInt(c(cidx));
    colstart = this.colidx(col);
    colend = this.colidx(col+1);
    colNnz =  colend - colstart;
    for k = 1:colNnz
        s.d(outIdx) = this.d(colstart+k-1);
        s.rowidx(outIdx) = this.rowidx(colstart+k-1);
        outIdx = outIdx+1;
    end
    s.colidx(cidx+1) = s.colidx(cidx) + colNnz;
end
s.matlabCodegenUserReadableName = makeUserReadableName(s);

%--------------------------------------------------------------------------

function s = parenReference2DRows(this,r)
% Handle indexing: s(r,:) for numeric r
validateNumericIndex(ONE,this.m,r);
sm = coder.internal.indexInt(numel(r));
sn = this.n;

% Check if the rowids being extracted are in sorted order. If it is, we
% don't have to pay the cost of copy incurred during transpose.
[isRowIdxSorted,d] = isSortedIdx(r);
if isRowIdxSorted && d~=MONE
    s = parenReference2DSortedRowIdx(this,r,':',sm,sn,d);
else
    % Transpose the matrix and call parenReference on the column. This
    % should be cheaper (even with temp copies) than the alternative,
    % when accessing rows in random order.

    % Transpose is a O(nnz) call and so is extracting columns.
    t = this';
    s = t(:,r)';
end
%--------------------------------------------------------------------------

function validateIndexTypes(r,c)
validateIndexType(r);
validateIndexType(c);

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

function lt = sortDataInColByRowIdx(i,j,rowIdx)

lt = rowIdx(i) < rowIdx(j);

%--------------------------------------------------------------------------

function m = ONE
coder.inline('always')
m = coder.internal.indexInt(1);

function m = MONE
coder.inline('always')
m = coder.internal.indexInt(-1);

%--------------------------------------------------------------------------

function [tf,d] = isSortedIdx(p)
% Returns true if p is non-empty and strictly increasing
tf = true;
deq = false;
MONE = coder.internal.indexInt(-1);
d = MONE;
if isempty(p)
    % For empty matrices we fallback to generic impl
    tf = false;
    return
end
for i = 2:numel(p)
    tf = tf && (p(i) > p(i-1));
    if d == MONE
        % This cast should be safe, p is an array of indices.
        d = coder.internal.indexInt(p(i)-p(i-1));
        deq = true;
    else 
        deq = deq && ((p(i)-p(i-1))==d);
    end
end

if ~tf || ~deq 
    d = MONE;
end