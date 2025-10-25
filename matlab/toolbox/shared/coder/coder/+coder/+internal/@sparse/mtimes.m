function c = mtimes(a,b)
%MATLAB Code Generation Private Method

%   Copyright 2017-2018 The MathWorks, Inc.

% Throughout, we follow the BLAS convention:
%
%   c = a*b
%
% where a is m-by-k, b is k-by-n, and c is m-by-n

%#codegen
coder.internal.errorIf(~matlab.internal.feature("SingleSparse") && (isa(a,'single') || isa(b,'single')), ...
                       'MATLAB:mtimes:sparseSingleNotSupported')
if coder.internal.isConst(isscalar(a)) && isscalar(a) || ...
        coder.internal.isConst(isscalar(b)) && isscalar(b)
    coder.inline('always');
    c = times(a,b);
    return
end
coder.internal.errorIf(isinteger(a) || isinteger(b), ...
                      'MATLAB:mtimes:integerNotSupported');
coder.internal.assert(isAllowedSparseClass(a), ...
                      'Coder:toolbox:unsupportedClass','mtimes',class(a));
coder.internal.assert(isAllowedSparseClass(b), ...
                      'Coder:toolbox:unsupportedClass','mtimes',class(b));
coder.internal.assert(ismatrix(a) && ismatrix(b), ...
                      'MATLAB:mtimes:inputsMustBe2D');
coder.internal.assert(coder.internal.indexInt(size(a,2)) == coder.internal.indexInt(size(b,1)), ...
                      'MATLAB:innerdim');
if issparse(a)
    if issparse(b)
        c = ssmtimes(a,b);
    else
        c = sfmtimes(a,b);
    end
else
    % Since we called the sparse mtimes method either a or b must be sparse
    coder.internal.assert(issparse(b), ...
                          'Coder:builtins:Explicit','Internal error: Expected b to be sparse');
    c = fsmtimes(a,b);
end
coder.internal.sparse.sanityCheck(c);

%--------------------------------------------------------------------------

function c = ssmtimes(a,b)
% sparse*sparse
[cnnz,ccolidx] = countNnzInProduct(a,b);
c = coder.internal.sparse.nullcopyLike(a.m,b.n,cnnz,coder.internal.scalarEg(a.d,b.d));
c.colidx = ccolidx;
% Work space
if coder.internal.isConst(a.m) && a.m == 1
    % Avoid MSVC warning
    wd = zeros('like',c.d);
else
    wd = coder.nullcopy(zeros(a.m,1,'like',c.d));
end
flag = zeros(a.m,1,'like',ZERO);
pb = ONE;
cnnz = ZERO;
for j = 1:b.n
    needSort = false;
    pbend = b.colidx(j+1);
    pcstart = cnnz+1;
    blen = pbend - pb;
    if blen == 0
        % b(:,j) has no non-zeros
    elseif blen == 1
        % b(:,j) has 1 nonzero so we just scale the column of A
        k = b.rowidx(pb);
        bd = b.d(pb);
        paend = a.colidx(k+1)-1;
        for pa = a.colidx(k):paend
            cnnz = cnnz+1;
            % a is sorted so no need to sort
            i = a.rowidx(pa);
            c.rowidx(cnnz) = i;
            wd(i) = a.d(pa) * bd;
        end
        pb = pb+1;
    else
        k = b.rowidx(pb);
        bd = b.d(pb);
        paend = a.colidx(k+1)-1;
        for pa = a.colidx(k):paend
            i = a.rowidx(pa);
            cnnz = cnnz+1;
            flag(i) = cnnz;
            c.rowidx(cnnz) = i;
            wd(i) = a.d(pa)*bd;
        end
        pb = pb+1;
        while pb < pbend
            k = b.rowidx(pb);
            bd = b.d(pb);
            paend = a.colidx(k+1)-1;
            for pa = a.colidx(k):paend
                i = a.rowidx(pa);
                pc = flag(i);
                if pc < pcstart
                    cnnz = cnnz+1;
                    pc = cnnz;
                    flag(i) = pc;
                    c.rowidx(pc) = i;
                    wd(i) = a.d(pa)*bd;
                    needSort = true;
                else
                    wd(i) = wd(i) + a.d(pa)*bd;
                end
            end
            pb = pb+1;
        end
    end
    pcend = c.colidx(j+1)-1;
    pcstart = c.colidx(j);
    if needSort
        c.rowidx = coder.internal.introsort(c.rowidx,pcstart,pcend);
    end
    for k = pcstart:pcend
        c.d(k) = wd(c.rowidx(k));
    end
end
c = fillIn(c);

%--------------------------------------------------------------------------

function c = fsmtimes(a,b)
% full*sparse
% Generally compute:
%
%   c = (b'*a')';
m = coder.internal.indexInt(size(a,1));
k = coder.internal.indexInt(size(a,2));
n = b.n;
c = zeros(m,n,'like',coder.internal.scalarEg(a,b.d));
if k == 0 || m == 0 || n == 0 || nnzInt(b) == 0
    return
end

if m == 1
    % xGEMV case: a is a row vector. Compute:
    %
    %   c = (b'*a)
    c = sfmtimes_vector_at(b,a,c);
    return
end

% Build c by columns
if DOUNROLL
    B = coder.internal.indexInt(4);
end
if DOUNROLL && m >= B
    for ccol = 1:n
        coff = (ccol-1)*coder.internal.indexInt(size(c,1));
        bpend = b.colidx(ccol+1)-1;
        for bp = b.colidx(ccol):bpend
            acol = b.rowidx(bp);
            aoff = (acol-1)*coder.internal.indexInt(size(a,1));
            bd = b.d(bp);
            mend = m-mod(m,B);
            for crow = 1:B:mend
                cidx = crow+coff;
                aidx = crow+aoff;
                c(cidx) = c(cidx) + a(crow+aoff)*bd;
                c(cidx+1) = c(cidx+1) + a(aidx+1)*bd;
                c(cidx+2) = c(cidx+2) + a(aidx+2)*bd;
                c(cidx+3) = c(cidx+3) + a(aidx+3)*bd;
            end
            for crow = mend+1:m
                c(crow+coff) = c(crow+coff) + a(crow,acol)*bd;
            end
        end
    end
else
    for ccol = 1:n
        bpend = b.colidx(ccol+1)-1;
        for bp = b.colidx(ccol):bpend
            acol = b.rowidx(bp);
            bd = b.d(bp);
            for crow = 1:m
                c(crow,ccol) = c(crow,ccol) + a(crow,acol)*bd;
            end
        end
    end
end

%--------------------------------------------------------------------------

function c = sfmtimes_vector_at(a,b,c)
% c = A'*b
for k = ONE:a.n
    cd = zeros('like',c);
    apend = a.colidx(k+1)-1;
    for ap = a.colidx(k):apend
        ai = a.rowidx(ap);
        cd = cd + a.d(ap)*b(ai);
    end
    c(k) = cd;
end

%--------------------------------------------------------------------------

function c = sfmtimes(a,b)
% sparse*full
m = a.m;
k = a.n;
n = coder.internal.indexInt(size(b,2));
c = zeros(m,n,'like',coder.internal.scalarEg(a.d,b));
if k == 0 || m == 0 || n == 0 || nnzInt(a) == 0
    return
end

if n == 1
    % xGEMV case: b is a column vector
    c = sfmtimes_vector(a,b,c,ONE);
    return
end

for j = ONE:n
    c = sfmtimes_vector(a,b,c,j);
end

%--------------------------------------------------------------------------

function c = sfmtimes_vector(a,b,c,col)
coder.internal.prefer_const(col);
if DOUNROLL
    B = coder.internal.indexInt(4);
    coff = (col-1)*coder.internal.indexInt(size(c,1));
end
for acol = ONE:a.n
    bc = b(acol,col);
    if DOUNROLL
        apstart = a.colidx(acol);
        apend = a.colidx(acol+1);
        nap = apend-a.colidx(acol);
        if nap >= B
            apendmb = mod(nap,B);
            apend1 = apend-1-apendmb;
            for ap = apstart:B:apend1
                crow1 = a.rowidx(ap);
                crow2 = a.rowidx(ap+1);
                crow3 = a.rowidx(ap+2);
                crow4 = a.rowidx(ap+3);
                c(crow1+coff) = c(crow1+coff) + a.d(ap)*bc;
                c(crow2+coff) = c(crow2+coff) + a.d(ap+1)*bc;
                c(crow3+coff) = c(crow3+coff) + a.d(ap+2)*bc;
                c(crow4+coff) = c(crow4+coff) + a.d(ap+3)*bc;
            end
            apendm1 = apend-1;
            for ap = apend1+1:apendm1
                crow = a.rowidx(ap);
                c(crow,col) = c(crow,col) + a.d(ap)*bc;
            end
        else
            apend = a.colidx(acol+1)-1;
            for ap = a.colidx(acol):apend
                crow = a.rowidx(ap);
                c(crow+coff) = c(crow+coff) + a.d(ap)*bc;
            end
        end
    else
        apend = a.colidx(acol+1)-1;
        for ap = a.colidx(acol):apend
            crow = a.rowidx(ap);
            c(crow,col) = c(crow,col) + a.d(ap)*bc;
        end
    end
end

%--------------------------------------------------------------------------

function [cnnz,ccolidx] = countNnzInProduct(a,b)
ccolidx = zeros(size(b.colidx),'like',b.colidx);
flag = zeros(a.m,1,'like',ZERO);
cnnz = ZERO;
ncolB = b.n;
for j = 1:ncolB
    % nnz(C(:,j))
    bcidx = b.colidx(j);
    bend = b.colidx(j+1);

    cstart = cnnz;
    cmax = cnnz + a.m;
    ccolidx(j) = cnnz+1;
    while bcidx < bend && cnnz <= cmax
        k = b.rowidx(bcidx);
        aend = a.colidx(k+1)-1;
        for acidx = a.colidx(k):aend
            i = a.rowidx(acidx);
            if flag(i) ~= j
                flag(i) = j;
                cnnz = cnnz+1;
            end
        end
        bcidx = bcidx+1;
    end
    if cnnz < cstart
        coder.internal.error('MATLAB:nomem');
        return
    end
end
ccolidx(b.n+1) = cnnz+1;

%--------------------------------------------------------------------------

function y = DOUNROLL
coder.inline('always');
y = true;

%--------------------------------------------------------------------------
