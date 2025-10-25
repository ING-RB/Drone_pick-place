function s = binOp(a,b,opstr,sparseOutputPredicate,opImpl)
%MATLAB Code Generation Private Method

% Apply the binary operator specified by opstr or opImpl. To supply an operation by name just supply
% opstr. To override the user-visible name supply opstr as the name to be printed for diagnostics
% and a function handle for opImpl.

% sparseOutputPredicate is a binary function which should determine whether or not the output of
% the binary operation should be sparse. When sparseOutputPredicate is omitted the output is assumed
% to always be sparse.

%   Copyright 2017-2022 The MathWorks, Inc.
%#codegen
coder.internal.prefer_const(opstr);
if nargin < 4
    sparseOutputPredicate = @returnTrue;
end
if nargin < 5
    op = str2func(opstr);
    opImpl = op;
else
    coder.internal.prefer_const(opImpl);
    op = opImpl;
end
opData = getOpData(opstr);
scalara = coder.internal.isConst(isscalar(a)) && isscalar(a);
sparsea = issparse(a);
scalarb = coder.internal.isConst(isscalar(b)) && isscalar(b);
sparseb = issparse(b);
noscalars = ~(scalara || scalarb);
coder.internal.errorIf(isinteger(a) || isinteger(b), ...
                       'MATLAB:sparseInteger');
coder.internal.assert(isAllowedSparseClass(a), ...
                      'Coder:toolbox:unsupportedClass',opstr,class(a));
coder.internal.assert(isAllowedSparseClass(b), ...
                      'Coder:toolbox:unsupportedClass',opstr,class(b));
% Try our hardest to give a compile time error if possible
if noscalars
    if sparsea
        am = a.m;
        an = a.n;
    else
        am = coder.internal.indexInt(size(a,1));
        an = coder.internal.indexInt(size(a,2));
    end
    if sparseb
        bm = b.m;
        bn = b.n;
    else
        bm = coder.internal.indexInt(size(b,1));
        bn = coder.internal.indexInt(size(b,2));
    end

    coder.internal.assert(coder.internal.isImplicitExpansionSupported ||...
        am == bm, 'MATLAB:dimagree');
    coder.internal.assert( coder.internal.isImplicitExpansionSupported ||...
        an == bn, 'MATLAB:dimagree');

    coder.internal.assert(~coder.internal.isImplicitExpansionSupported ||...
        isImpexCompatibleSize(a,b), 'MATLAB:dimagree');
end
if ischar(a)
    s = binOp(double(a),b,opstr,sparseOutputPredicate,opImpl);
    return
end
if ischar(b)
    s = binOp(a,double(b),opstr,sparseOutputPredicate,opImpl);
    return
end

[sm,sn] = getBinOpSize(a,b);
%determine output type and sparsity
ZEROA = fullZero(a);
ZEROB = fullZero(b);
if opData.isDivide || opData.isRem
    isIdent = false;
    ZEROD = coder.internal.scalarEg(ZEROA,ZEROB);
else
    ZEROD = zeros('like',op(ZEROA,ZEROB));
    isIdent = op(ZEROA, ZEROB) == ZEROD;
end

if coder.const(sparseOutputPredicate(a,b))
    coder.internal.assert(ismatrix(a) && ismatrix(b), ...
                          'MATLAB:sparseBinaryOperator:reshapedNdOutput');
end


if numel(size(a)) > 2 || numel(size(b)) > 2
    if numel(size(a)) > 2
        bigMat = a;
        sparseMat = b;
        normalOp = op;
    else
        bigMat = b;
        sparseMat = a;
        normalOp = @(x,y)op(y,x);
    end

    bigSize = size(bigMat);
    numPages = prod(bigSize(3:end));

    s = coder.nullcopy(repmat(ZEROD, [sm,sn,bigSize(3:end)]));
    for i=1:numPages
        s(:,:,i) = normalOp(bigMat(:,:,i), sparseMat); %should we recurse directly to binOp? does it matter?
    end

    return;
end



% Top-level cases
if noscalars

    %allocate output
    if isIdent
        sparses = sparseOutputPredicate(a,b);
        temporarilyFull = false;
    else
        sparses = false;
        temporarilyFull = sparseOutputPredicate(a,b);
    end
    ZEROD = op(ZEROA, ZEROB);
    S = allocEqsizeBinop(sparses, opData, ZEROD,a,b,sn,sm);

    %fill output
    if sparsea && sparseb
        if all(size(a)  == size(b)) || ~coder.internal.isImplicitExpansionSupported
            S = sparseSparseEqHeightBinOp(op,a,b,S, false);
        elseif iscolumn(a)
            if isrow(b)
                S = sparseSparseRowExpandBinOp(@(x,y)(op(y,x)),b,a,S, true);
            else
                S = sparseSparseEqHeightBinOp(op,a,b,S,true);
            end
        elseif iscolumn(b)
            if isrow(a)
                S = sparseSparseRowExpandBinOp(op, a,b,S, true);
            else
                %swap so column is earlier input
                S = sparseSparseEqHeightBinOp(@(x,y)(op(y,x)),b,a,S, true);
            end
        elseif isrow(a)
            %must be matrix case
            S = sparseSparseRowExpandBinOp(op, a,b,S, false);
        elseif isrow(b)
            %matrix case
            S = sparseSparseRowExpandBinOp(@(x,y)(op(y,x)),b,a,S, false);
        end
    else
        if sparsea
            sparseInput = a;
            fullInput = b;
            normalizedOp = op;
        else
            sparseInput = b;
            fullInput = a;
            normalizedOp = @(x,y)(op(y,x));
        end
        S = sparseFullEqsizeBinOp(normalizedOp,sparseInput,fullInput,S);
    end

    %ensure output type is correct
    if temporarilyFull
        s = sparse(S);
    else
        s = S;
    end

else %scalar expansion

    if scalara
        sa = getScalar(a);
        uniOp = @(x)(op(sa,x));
        replaceZerosWith = uniOp(ZEROB);
        c = b;
    else % scalar b
        sb = getScalar(b);
        uniOp = @(x)(op(x,sb));
        replaceZerosWith = uniOp(ZEROA);
        c = a;
    end
    isIdent = replaceZerosWith == ZEROD;

    if ~issparse(c)
        S = uniOp(c);
        if coder.const(sparseOutputPredicate(a,b))
            s = sparse(S);
        else
            s = S;
        end
    elseif isIdent && coder.const(sparseOutputPredicate(a,b))
        s = spfun(uniOp, c);
        return;
    elseif ~coder.internal.isConst(isIdent) &&...
            coder.internal.isConstTrue(sparseOutputPredicate(a,b))&&...
            (opData.isTimes || opData.isDivide) %should relops, rem/mod be here too?
        %while these operations *could* require an essentially full matrix,
        %they probably wont. To avoid statically allocating a big full
        %matrix and then never using it, we force this to always be
        %varsized. g2670752
        S = eml_expand(replaceZerosWith, coder.internal.ignoreRange(sm),coder.internal.ignoreRange(sn));
        S = scalarBinOp(uniOp,c,S);
        if coder.const(sparseOutputPredicate(a,b))
            s = sparse(S(1:sm, 1:sn));
        else
            s = S;
        end
    else
        S = eml_expand(replaceZerosWith, sm,sn);
        S = scalarBinOp(uniOp,c,S);
        if coder.const(sparseOutputPredicate(a,b))
            s = sparse(S);
        else
            s = S;
        end
    end
end

%--------------------------------------------------------------------------

function s = sparseSparseEqHeightBinOp(op,a,b,s, impex)
% sparse-sparse same size or a is a column being expanded
coder.internal.prefer_const(op, impex);
ZEROA = fullZero(a);
ZEROB = fullZero(b);
didx = ONE;
if issparse(s)
    s.colidx(ONE) = ONE;
end
n = coder.internal.indexInt(size(s,2));

ac = ONE;
if impex
    acInc = ZERO;
else
    acInc = ONE;
end

for c = 1:n
    aidx = a.colidx(ac);
    bidx = b.colidx(c);
    moreAToDo = aidx < a.colidx(ac+1);
    moreBToDo = bidx < b.colidx(c+1);
    while (moreAToDo || moreBToDo) %still nonzeros in this col to process
        while (aidx < a.colidx(ac+1) &&...
                (~moreBToDo || a.rowidx(aidx) < b.rowidx(bidx)))% process nonzeros in a for rows where b is 0, until we find a nonzero in b or a zero in a
            row = a.rowidx(aidx);
            val = op(a.d(aidx) , ZEROB);
            [s, didx] = writeOneOutput(s, didx, row, c, val);
            aidx = aidx + 1;
        end
        moreAToDo = aidx < a.colidx(ac+1);
        while (bidx < b.colidx(c+1) &&...
                (~moreAToDo || b.rowidx(bidx) < a.rowidx(aidx))) %same but a <-> b
            row = b.rowidx(bidx);
            val = op(ZEROA, b.d(bidx));
            [s, didx] = writeOneOutput(s, didx, row, c, val);
            bidx = bidx + 1;
        end
        while (aidx < a.colidx(ac+1) && bidx < b.colidx(c+1) && a.rowidx(aidx) == b.rowidx(bidx))%process section where both are non-zero
            row = b.rowidx(bidx);
            val = op(a.d(aidx), b.d(bidx));
            [s, didx] = writeOneOutput(s, didx, row, c, val);
            bidx = bidx + 1;
            aidx = aidx +1;
        end
        moreAToDo = aidx < a.colidx(ac+1);
        moreBToDo = bidx < b.colidx(c+1);
    end
    if issparse(s)
        s.colidx(c+1) = didx;
    end
    ac = ac + acInc; %go to the next column, or stay if we are implict expanding
end

%--------------------------------------------------------------------------

function s = sparseSparseRowExpandBinOp(op, rowA, b, s, expandB)
ZEROR = fullZero(rowA);
ZEROM = fullZero(b);
ZEROS = zeros(1,1, 'like', op(ZEROR, ZEROM));
didx = ONE;
if issparse(s)
    s.colidx(ONE) = ONE;
end
n = coder.internal.indexInt(size(s,2));

bc = ONE;
if expandB
    bcInc = ZERO;
else
    bcInc = ONE;
end


for c = 1:n
    isZeroInRow = rowA.colidx(c) == rowA.colidx(c+1);
    if isZeroInRow
        av = ZEROR;
    else
        av = rowA.d(rowA.colidx(c));
    end



    fillVal = op(av, ZEROM);

    if b.colidx(bc) == b.colidx(bc+1) %empty col
        if ~issparse(s) || fillVal ~= ZEROS
            for r = 1:size(s,1)
                [s, didx] = writeOneOutput(s, didx, r, c, fillVal);
            end
        end
        if issparse(s)
            s.colidx(c+1) = didx;
        end
        bc = bc + bcInc;
        continue;
    end

    firstNonZeroRow = b.rowidx(b.colidx(bc));
    lastNonZeroRow = b.rowidx(b.colidx(bc+1)-1);
    if ~issparse(s) || fillVal ~= ZEROS %processes zeros at the top of this col of the matrix if necessary
        for r = 1:(firstNonZeroRow-1)
            [s, didx] = writeOneOutput(s, didx, r, c, fillVal);
        end
    end
    offset = ZERO;
    for r = firstNonZeroRow:lastNonZeroRow
        if b.rowidx(b.colidx(bc)+offset) == r
            v = b.d(b.colidx(bc) + offset);
            [s, didx] = writeOneOutput(s, didx, r, c, op(av, v));
            offset = offset+1;
        else %zero in this row
            [s, didx] = writeOneOutput(s, didx, r, c, fillVal);
        end
    end
    if ~issparse(s) || fillVal ~= ZEROS %processes zeros at the bottom of this col of the matrix if necessary
        for r = lastNonZeroRow+1:size(s,1)
            [s, didx] = writeOneOutput(s, didx, r, c, fillVal);
        end
    end
    if issparse(s)
        s.colidx(c+1) = didx;
    end
    bc = bc + bcInc;

end



function s = sparseFullEqsizeBinOp(op,sparseInput,fullInput,s)
coder.internal.prefer_const(op);
ZEROI = fullZero(sparseInput);

if all(size(sparseInput) == size(fullInput)) || ~coder.internal.isImplicitExpansionSupported
%     no expansion
    sparseColIncrement = ONE;
    idxInc = ONE;
    fullRowIncrement = ONE;
    fullColIncrement = ONE;
else
    if isrow(sparseInput)
        %sparseExpand = EXPAND_DOWN;
        sparseColIncrement = ONE;
        idxInc = ZERO;
    elseif iscolumn(sparseInput)
        %sparseExpand = EXPAND_RIGHT;
        sparseColIncrement = ZERO;
        idxInc = ONE;
    else
        %sparseExpand = NO_EXPAND;
        sparseColIncrement = ONE;
        idxInc = ONE;
    end

    if isrow(fullInput)
        %fullExpand = EXPAND_DOWN;
        fullRowIncrement = ZERO;
        fullColIncrement = ONE;
    elseif iscolumn(fullInput)
        %fullExpand = EXPAND_RIGHT;
        fullRowIncrement = ONE;
        fullColIncrement = ZERO;
    else
        %fullExpand = NO_EXPAND;
        fullRowIncrement = ONE;
        fullColIncrement = ONE;
    end
end




if issparse(s)
    s.colidx(ONE) = ONE;
end

didx = ONE;
sm = coder.internal.indexInt(size(s,1));
sn = coder.internal.indexInt(size(s,2));

sparse_col = ONE;
full_col = ONE;

for col = 1:sn
    idx = sparseInput.colidx(sparse_col);
    full_row = ONE;
    for row = 1:sm

        if idx < sparseInput.colidx(sparse_col+1) && (row == sparseInput.rowidx(idx) || idxInc == ZERO)%non-zero element in sparse matrix
            val = op(sparseInput.d(idx), fullInput(full_row, full_col));
            idx = idx+idxInc; %look at the next one
        else %zero element
            val = op(ZEROI, fullInput(full_row, full_col));
        end

        [s, didx] = writeOneOutput(s, didx, row, col, val);

        full_row = full_row + fullRowIncrement;
    end
    if issparse(s)
        s.colidx(col+1) = didx;
    end

    sparse_col = sparse_col + sparseColIncrement;
    full_col = full_col + fullColIncrement;
end

%--------------------------------------------------------------------------

function s = scalarBinOp(op,c,s)
coder.internal.prefer_const(op);
n = coder.internal.indexInt(size(s, 2));
for col = 1:n
    for idx = c.colidx(col):(c.colidx(col+1)-1)
        row = c.rowidx(idx);
        s(row, col) = op(c.d(idx));
    end
end

%--------------------------------------------------------------------------

function z = fullZero(x)
if issparse(x)
    z = zeros('like',x.d);
else
    z = zeros('like',x);
end

%--------------------------------------------------------------------------

function scalarx = getScalar(x)
sparsex = issparse(x);
if sparsex && coder.internal.indexInt(nnz(x)) > 0
    scalarx = x.d(1);
elseif sparsex
    scalarx = zeros('like',x.d);
else
    scalarx = x(1);
end

%--------------------------------------------------------------------------

function s = allocEqsizeBinop(sparses, opData,ZEROD,a,b,sn,sm)
% Allocate sparse output for op(a,b) where a and b have equal sizes or are
% implicit expanding

% prefer_const to preserve constant sizes in allocation
coder.internal.prefer_const(sparses, opData,ZEROD,sn,sm);

if ~sparses %includes non-identity case
    s = eml_expand(ZEROD,sm,sn);
   return;
end

% if we are implict expanding then these numbers are effectively much
% larger, as we are basically treating an input as if it had been repmat'd
nza = coder.internal.indexInt(nnz(a));
nzb = coder.internal.indexInt(nnz(b));

if coder.internal.isImplicitExpansionSupported &&...
        ~(size(a,1) == size(b,1) && size(a,2) == size(b,2)) %implict expansion is happening
    if iscolumn(a)
        nza = nza * coder.internal.indexInt(size(b,2));
    elseif isrow(a)
        nza = nza * coder.internal.indexInt(size(b,1));
    end
    if iscolumn(b)
        nzb = nzb * coder.internal.indexInt(size(a,2));
    elseif isrow(a)
        nzb = nzb * coder.internal.indexInt(size(a,1));
    end
end


if opData.isAnd
    numalloc = min(nza,nzb);
else
    addInRange = nza <= intmax(coder.internal.indexIntClass) - nzb;
    mulInRange = mulIsSafe(sn,sm);
    coder.internal.assert( ...
        addInRange ||... %check that add is safe
        mulInRange,...
        'Coder:toolbox:SparseFuncAlmostFull');
    if addInRange
        nzsum = nza + nzb;
    else
        nzsum = intmax(coder.internal.indexIntClass);
    end
    if mulInRange
        sizeMul = sn*sm;
    else
        sizeMul = intmax(coder.internal.indexIntClass);
    end
    numalloc = min(nzsum, sizeMul);
end
numalloc = max2(numalloc,ONE);
s = coder.internal.sparse.nullcopyLike(sm, sn, numalloc, ZEROD);

%--------------------------------------------------------------------------

function [s,didx] = writeOneOutput(s, didx, row, col, val)

if issparse(s)
    if val ~= zeros(1,1, 'like', val) %otherwise, nothing to do
        s.d(didx) = val;
        s.rowidx(didx) = row;
        didx = didx+1;
    end
else
    s(row, col) = val;
end

%--------------------------------------------------------------------------

function [m,n] = getBinOpSize(a,b)
f = @coder.internal.indexInt;
if coder.internal.isConst(isscalar(a)) && isscalar(a)
    m = f(size(b,1));
    n = f(size(b,2));
elseif coder.internal.isConst(isscalar(b)) && isscalar(b)
    m = f(size(a,1));
    n = f(size(a,2));
else
    m = f(max2(size(a, 1), size(b,1)));
    n = f(max2(size(a, 2), size(b,2)));
end

%--------------------------------------------------------------------------

function p = returnTrue(~,~)
coder.inline('always');
p = true;

%--------------------------------------------------------------------------

function p = getOpData(op)
coder.internal.prefer_const(op);
p.isAnd = coder.const(strcmp(op,'and'));
p.isDivide = coder.const(strcmp(op,'rdivide') || strcmp(op,'ldivide'));
p.isTimes = coder.const(strcmp(op, 'times'));
p.isRem = coder.const(strcmp(op, 'rem'));

%--------------------------------------------------------------------------

function out = mulIsSafe(a,b)
[~,overflow] = coder.internal.bigProduct(a,b,true);
out = overflow==0;

%--------------------------------------------------------------------------

function good = isImpexCompatibleSize(A,B)
    coder.inline('always')
    dims = coder.const(max2(numel(size(A)), numel(size(B))));
    good = true;
    coder.unroll();
    for i = 1:dims
        good = good && (...
            size(A,i) == 1 || size(B,i) == 1||...
            size(A,i) == size(B,i));
    end
