function out = not(S)
%MATLAB Code Generation Private Method

%   Copyright 2017-2018 The MathWorks, Inc.
%#codegen
coder.internal.assert(isreal(S), 'MATLAB:Not:operandsNotReal');
outNNZ= notnnz(S.m, S.n, nnzInt(S));
out = coder.internal.sparse.nullcopyLike(S.m, S.n, outNNZ, true);
out.d(1:outNNZ) = true;
curPosition = ONE;
for c = 1:S.n
    out.colidx(c) = curPosition;
    if S.colidx(c) == S.colidx(c+1)%empty column
        for i = ONE:S.m
            out.rowidx(curPosition+i-1) = i;
        end
        curPosition = curPosition+S.m;
    else
        %fill in rowidx up to the first entry
        for writeRow = ONE:(S.rowidx(S.colidx(c))-ONE)
            out.rowidx(curPosition) = writeRow;
            curPosition = curPosition+1;
        end
        %gaps between elements of S.rowidx
        nnzInThisRowOfS = S.colidx(c+1) - S.colidx(c);
        for i = ZERO:(nnzInThisRowOfS - 2)%do not include the last element
            coder.internal.errorIf(isnan(S.d(S.colidx(c)+i)), 'MATLAB:nologicalnan');
            writeStart = S.rowidx(S.colidx(c)+i) +ONE; %from one past current element
            writeEnd = S.rowidx(S.colidx(c)+i+ONE) -ONE;%to one before the next
            for writeRow = writeStart:writeEnd
                out.rowidx(curPosition) = writeRow;
                curPosition = curPosition+1;
            end
        end
        %fill from the last entry to the end
        coder.internal.errorIf(isnan(S.d(S.colidx(c)+nnzInThisRowOfS-1)),...
            'MATLAB:nologicalnan');
        writeStart = S.rowidx(S.colidx(c)+nnzInThisRowOfS-1) +ONE;
        writeEnd = S.m;
        for writeRow = writeStart:writeEnd
            out.rowidx(curPosition) = writeRow;
            curPosition = curPosition+1;
        end
    end
end

out.colidx(S.n+1) = curPosition;
coder.internal.sparse.sanityCheck(out);

end




%check the number of non-zeros in the output matrix
function outnnz = notnnz(m,n,nnz)
% [m,n] = size(S);
% nnz = nnz(S);
% outnnz = nnz(~S);
coder.internal.prefer_const(m,n);
if m > n
    smaller = n;
    larger = m;
else
    smaller = m;
    larger = n;
end
if smaller == 0
    outnnz = ZERO;
else
    q = coder.internal.indexDivide(nnz,smaller);
    r = nnz - q*smaller; % 0 <= r < S
    larger = larger - q;
    if larger==0
        outnnz = ZERO;
        return
    end
    
    Imax = intmax(coder.internal.indexIntClass);
    Lmax = coder.internal.indexDivide(Imax,smaller);  % + rem(Imax,smaller)/smaller
    Smax = coder.internal.indexDivide(Imax,larger);  % + rem(Imax,larger)/larger
    % smaller*(larger - 1) < outnnz <= smaller*larger
    coder.internal.assert(larger <= Lmax && smaller <= Smax, 'Coder:toolbox:SparseNot');  
    outnnz = smaller*larger - r;
    
end

end
