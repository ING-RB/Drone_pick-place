function y = rowReduction(f,pred,nzinit,x,yeg)
%MATLAB Code Generation Private Method

%   Copyright 2017-2018 The MathWorks, Inc.

% Helper to perform a reduction across rows of the sparse matrix x.
%
% ARGUMENTS:
%   f - The binary function handle used to reduce across the row.
%
%   pred - A unary predicate evaluated on each nonzero value to determine if
%   that value should take part in the reduction. For example this allows
%   implementing the omitnan/includenan behavior of sum and prod.
%
%   x - The sparse upon which the reduction is performed
%
%   yeg - An full scalar used as the example for the desired output type
%#codegen
nzx = nnzInt(x);
[xrowidx,xrowidxPerm] = coder.internal.introsortIdx(x.rowidx(1:nzx,1));
y = coder.internal.sparse.nullcopyLike(x.m,ONE,nzx,yeg);
idx = ONE;
outIdx = ONE;
while idx <= nzx
    count = ONE;
    currentRow = xrowidx(idx);
    xd = x.d(xrowidxPerm(idx));
    y.d(outIdx) = nzinit(xd);
    idx = idx+1;
    while idx <= nzx && xrowidx(idx) == currentRow
        xd = x.d(xrowidxPerm(idx));
        if pred(xd)
            y.d(outIdx) = f(y.d(outIdx),cast(xd,'like',yeg));
        end
        count = count+1;
        idx = idx+1;
    end
    if count < x.n
        % Include a 0
        y.d(outIdx) = f(y.d(outIdx),zeros('like',yeg));
    end
    if y.d(outIdx) ~= zeros('like',yeg)
        y.rowidx(outIdx) = currentRow;
        outIdx = outIdx+1;
    end
end
%y is always a column, so these are all the elements we need to assign
y.colidx(1) = ONE;
y.colidx(end) = outIdx;

