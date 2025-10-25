function K = kron(fA,fB)
%MATLAB Code Generation Private Method

%   Copyright 2020 The MathWorks, Inc.

%#codegen


if ~issparse(fB)
    B = sparse(fB);
else
    B = fB;
end
if ~issparse(fA)
    A = sparse(fA);
else
    A = fA;
end

K = coder.internal.sparse.nullcopyLike(A.m*B.m, A.n*B.n, nnz(A)*nnz(B), A.d(1)*B.d(1));
curInd = ONE;
K.colidx(1) = ONE;


%matches compKron in matlab/src/mathcore/kronSparse.cpp

for jja = 1:A.n
    if A.colidx(jja) == A.colidx(jja+1)
        for jjb = 1:B.n
            jjk = B.n*(jja-1)+jjb;
            K.colidx(jjk+1) = curInd;
        end
    else
        for jjb = 1:B.n
            jjk = B.n*(jja-1)+jjb;
            if B.colidx(jjb)~= B.colidx(jjb+1)%skip zero columns in B
                for inda = A.colidx(jja):(A.colidx(jja+1)-1)
                    iia = A.rowidx(inda);
                    for indb = B.colidx(jjb):(B.colidx(jjb+1)-1)
                        iib = B.rowidx(indb);
                        K.rowidx(curInd) = B.m*(iia-1)+iib;
                        K.d(curInd) = A.d(inda)*B.d(indb);
                        curInd = curInd+1;
                    end
                end
            end
            K.colidx(jjk+1) = curInd;
        end
    end
end

coder.internal.sparse.sanityCheck(K);

end

function z = ONE
coder.inline('always');
z = coder.internal.indexInt(1);
end
