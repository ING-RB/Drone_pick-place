function M = c2rMatrix(A,columnwise,sparsityPattern)
% Produce the real interleaved form for a complex matrix A. The transform
% may be done treating A as a collection of column vectors (columnwise =
% true) or as a matrix (columnwise = false).
% If A is sparse, nargin == 3, and sparsityPattern is true, we consider A to
% be a sparsity pattern, and A(i,j) = 1 means that the corresponding
% (i,j)th element of the matrix referred to by A may have a nonzero real or
% imaginary part. Each element of a(i,j) of A is "replaced" by
%   repmat(xij,2,2) (columnwise = false)
%   repmat(xij,2,1) (columnwise = true)
% where xij = logical(real(a(i,j))) || logical(imag(a(i,j))).
% Otherwise a(i,j) is "replaced" by
%   [real(a(i,j)),-imag(a(i,j));imag(a(i,j)),real(a(i,j))] (columnwise = false)
%   [real(a(i,j);imag(a(i,j))]. (columnwise = true)

%    Copyright 2024 MathWorks, Inc.

if nargin < 3
    sparsityPattern = false;
    if nargin < 2
        columnwise = false;
    end
end
if issparse(A)
    [ia,ja,va] = find(A);
    ia = 2*ia.';
    if columnwise
        iar = [ia - 1; ia];
        ja = ja.';
        jar = [ja;ja];
        if sparsityPattern
            x = logical(real(va)) | logical(imag(va));
            var = [x.'; x.'];
        else
            var = [real(va).'; imag(va).'];
        end
        M = sparse(iar,jar,var,2*size(A,1),size(A,2));
    else
        iar = [ia - 1;ia;ia - 1;ia];
        ja = 2*ja.';
        jar = [ja - 1;ja - 1;ja;ja];
        rva = real(va).';
        iva = imag(va).';
        if sparsityPattern
            x = logical(rva) | logical(iva);
            var = repmat(x,4,1);
        else
            var = [rva;iva;-iva;rva];
        end
        M = sparse(iar,jar,var,2*size(A,1),2*size(A,2));
    end
else
    [m,n] = size(A);
    if columnwise
        M = reshape(typecast(complex(A(:)),'like',real(A)),2*m,n);
    else
        M = zeros(2*m,2*n,'like',real(A));
        for c = 1:n
            j = c + c;
            jm1 = j - 1;
            for r = 1:m
                re = real(A(r,c));
                im = imag(A(r,c));
                i = r + r;
                M(i-1,jm1) =  re;
                M( i ,jm1) =  im;
                M(i-1, j ) = -im;
                M( i , j ) =  re;
            end
        end
    end
end
