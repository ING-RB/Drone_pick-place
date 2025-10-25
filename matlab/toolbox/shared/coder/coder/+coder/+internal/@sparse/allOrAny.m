function y = allOrAny(op,x,dim)
%MATLAB Code Generation Private Method

%   Copyright 2017-2018 The MathWorks, Inc.

% Helper for computing all or any on a sparse input x. All other inputs should
% be full.
%#codegen
coder.internal.prefer_const(op,dim);
isall = coder.const(strcmp(op,'all'));
if dim > 2
    if isall
        % Return a logical with same sparsity pattern as x. Note we can't return
        % logical(x) since NaNs are converted to true for ALL whereas they are
        % errors for logical conversion.
        y = spfunImpl(@allSpfun,x);
    else
        % Here we must filter out NaNs which can result in underflow. So defer to
        % spfunImpl which already does a fillIn for us.
        y = spfunImpl(@anyComparator,x);
    end
    return
end
xszdim = coder.internal.indexInt(size(x,dim));
if coder.internal.isConst(size(x)) && ~isempty(x) && isVectorAlongDim(x,dim)
    % Vector input, scalar output case
    if isall
        % nnz must equal numel for all to be true
        yp = nnzInt(x) == xszdim;
    else
        % Must actually check data vector
        ub = nnzInt(x);
        yp = false;
        for k = 1:ub
            xd = x.d(k);
            if ~isnan(xd)
                yp = true;
                break;
            end
        end
    end
    y = coder.internal.sparse(yp);
elseif dim == 1
    y = columnAllOrAny(isall,x);
else
    y = rowAllOrAny(isall,x);
end
y.matlabCodegenUserReadableName = makeUserReadableName(y);
coder.internal.sparse.sanityCheck(y);

%--------------------------------------------------------------------------

function y = columnAllOrAny(isall,x)
coder.internal.prefer_const(isall);
y = coder.internal.sparse.nullcopyLike(ONE, x.n, 1, true);
y.colidx(1) = 1;
if isempty(x)
    for k = ONE+1:x.n+1
        if coder.const(isall)
            y.colidx(k) = k;
        else
            y.colidx(k) = 1;
        end
    end
else
    xnrows = x.m;
    if isall
        % Compute directly from column offsets
        for col = ONE:x.n
            if (x.colidx(col+1) - x.colidx(col)) == xnrows
                y.colidx(col+1) = y.colidx(col)+1;
            else
                y.colidx(col+1) = y.colidx(col);
            end
        end
    else
        % Cannot compute directly from column offsets since NaNs don't count as nonzero
        % for any
        for col = ONE:x.n
            xpend = x.colidx(col+1)-1;
            y.colidx(col+1) = y.colidx(col);
            for xp = x.colidx(col):xpend
                xd = x.d(xp);
                if ~isnan(xd)
                    y.colidx(col+1) = y.colidx(col+1)+1;
                    break;
                end
            end
        end
    end
end
ynnz = nnzInt(y);
nalloc = max2(ynnz,ONE);
y.rowidx = ones(nalloc,ONE,'like',ONE);
y.d = true(nalloc,ONE);
y.maxnz = nalloc;

%--------------------------------------------------------------------------

function y = rowAllOrAny(isall,x)
coder.internal.prefer_const(isall);
if isempty(x)
    if isall
        eg = true;
    else
        eg = false;
    end
    y = coder.internal.sparse.genericLike(eg,x.m,ONE);
else
    % If the number of rows is bounded by the size of an already allocated array, we
    % use a fast map-like algorithm. Otherwise, fall back to slower methods
    % which use less memory.
    if canUseRowMap(x)
        y = mapRowAllOrAny(isall,x);
    else
        if isall
            y = mergeRowAll(x);
        else
            y = mergeRowAny(x);
        end
    end
end

%--------------------------------------------------------------------------

function y = mapRowAllOrAny(isall,x)
% Compute an array of row counts from which we derive the result
coder.internal.prefer_const(isall);
xnnz = nnzInt(x);
rowmap = zeros(x.m,ONE, 'like',x.rowidx);
for k = 1:xnnz
    xrk = x.rowidx(k);
    if coder.const(isall)
        rowmap(xrk) = rowmap(xrk)+1;
    else
        % It turns out checking this first is faster than always checking xd
        if rowmap(xrk) == 0
            xd = x.d(k);
            if ~isnan(xd)
                rowmap(xrk) = 1;
            end
        end
    end
end

% Compute nnz(y) and record nonzero rows in rowmap(1:ynnz) to avoid multiple
% iterations of length ynnz
ynnz = ZERO;
xncols = x.n;
for k = 1:x.m
    if coder.const(isall)
        if rowmap(k) == xncols
            ynnz = ynnz+1;
            rowmap(ynnz) = k;
        end
    else
        if rowmap(k) > 0
            ynnz = ynnz+1;
            rowmap(ynnz) = k;
        end
    end
end
y = coder.internal.sparse();
y.m = x.m;
y.n = ONE;
if ynnz == ZERO
    nalloc = ONE;
    rowmap(1) = 1;
else
    nalloc = ynnz;
end
y.d = true(nalloc,ONE);
y.rowidx = coder.nullcopy(zeros(nalloc,ONE,'like',x.rowidx));
for k = 1:nalloc
    y.rowidx(k) = rowmap(k);
end
y.colidx = [ONE;ynnz+1];
y.maxnz = nalloc;

%--------------------------------------------------------------------------

function y = mergeRowAll(x)
% Do a simple merge-like intersection of all the column row sets

% Scratch space to record hits
yrowidx = zeros(nnzInt(x),ONE,'like',x.rowidx);

% Current index for each column. Seeded with column starts
xcolidx = coder.nullcopy(zeros(x.n,ONE,'like',ONE));
ncol = x.n;
for k = 1:ncol
    xcolidx(k) = x.colidx(k);
end

maxRow = ONE;
newMaxRow = ONE;
ynnz = zeros('like',ONE);
done = false;
while ~done
    match = true;
    for col = 1:ncol
        xrend = x.colidx(col+1);
        xcolidxcol = xcolidx(col);
        while xcolidxcol < xrend && x.rowidx(xcolidxcol) < maxRow
            xcolidxcol = xcolidxcol+1;
        end
        xcolidx(col) = xcolidxcol;
        if xcolidxcol < xrend
            xr = x.rowidx(xcolidxcol);
            match = match && xr == maxRow;
            if xr > newMaxRow
                newMaxRow = xr;
            end
        else
            match = false;
        end
        done = done || xcolidxcol == xrend;
    end
    if match
        ynnz = ynnz+1;
        yrowidx(ynnz) = maxRow;
        newMaxRow = newMaxRow+1;
    end
    maxRow = newMaxRow;
end

y = coder.internal.sparse.nullcopyLike(x.m,ONE,ynnz,true);
y.colidx(1) = 1;
y.colidx(end) = ynnz+1;
for k = 1:ynnz
    y.rowidx(k) = yrowidx(k);
end
y.d(:) = true;

%--------------------------------------------------------------------------

function y = mergeRowAny(x)
% Sort the row indices, and look for matches
xnnz = nnzInt(x);
if coder.target('MATLAB')
    [xrowidx,xrowidxPerm] = sort(x.rowidx(1:xnnz),1,'ascend');
else
    [xrowidx,xrowidxPerm] = locSortidx(x.rowidx(1:xnnz,1));
end
ynnz = ZERO;
k = ONE;
while k <= xnnz
    xr = xrowidx(k);
    xd = x.d(xrowidxPerm(k));
    if ~isnan(xd)
        ynnz = ynnz+1;
        xrowidx(ynnz) = xr;
        % Found a match so skip past rest of duplicates
        while k <= xnnz && xrowidx(k) == xr
            k = k+1;
        end
    else
        k = k+1;
    end
end
y = coder.internal.sparse.nullcopyLike(x.m,ONE,ynnz,true);
y.colidx(1) = 1;
y.colidx(end) = ynnz+1;
for k = 1:ynnz
    y.rowidx(k) = xrowidx(k);
end
y.d(:) = true;

%--------------------------------------------------------------------------

function n = ONE
coder.inline('always');
n = coder.internal.indexInt(1);

%--------------------------------------------------------------------------

function n = ZERO
coder.inline('always');
n = coder.internal.indexInt(0);

%--------------------------------------------------------------------------

function p = anyComparator(x)
coder.inline('always');
p = coder.nullcopy(true(coder.internal.indexInt(size(x))));
for k = 1:coder.internal.indexInt(numel(x))
    xk = x(k);
    p(k) = ~isnan(xk);
end

%--------------------------------------------------------------------------

function y = allSpfun(x)
y = true(size(x));

%--------------------------------------------------------------------------

function [x,idx] = locSortidx(x)
nx = coder.internal.indexInt(numel(x));
idx = (1:nx)';
idx = coder.internal.introsort(idx,ONE,nx,@(i,j)sortidxCmp(i,j,x));
x = x(idx);

%--------------------------------------------------------------------------

function p = sortidxCmp(i,j,x)
coder.inline('always');
p = x(i) < x(j);

%--------------------------------------------------------------------------

function out = isVectorAlongDim(x,dim)
out = true;
sx = size(x);
for i = coder.unroll(1:numel(sx))
    if i ~= dim
        out = out && sx(i) == 1;
    end
end
