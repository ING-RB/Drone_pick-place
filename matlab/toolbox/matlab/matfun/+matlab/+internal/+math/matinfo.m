function matinfo(A)
% MATINFO(A) tests the floating-point matrix A for various matrix
% properties. The included tests are:
%
% * Size
% * Density
% * 2-Norm
% * Condition number for inversion
% * Determinant
% * Upper/Lower bandwidth
% * Rank
% * Storage size
% * Symmetry/Hermitian-ness
% * Triangularity
% * Banded-ness
% * Diagonal
% * Positive/Negative definiteness
%
% All of the tests are performed for dense, square matrices. Only a subset
% of the tests are performed for rectangular or sparse matrices.  If the
% matrix is large and dense, then some of the tests are time consuming.
%
% FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
% Its behavior may change, or it may be removed in a future release.

% Copyright 2019-2024 The MathWorks, Inc.
if ~isfloat(A)
    error("MATLAB:NonFloatInput","Matrix must be single or double precision.")
end
if ~ismatrix(A) || isscalar(A) || isvector(A)
    error("MATLAB:NonMatrixInput","Input must be a 2-D matrix.")
end
if isempty(A)
    error("MATLAB:EmptyInput","Input matrix is empty.")
end
[m,n] = size(A);
sparsity = issparse(A);
cplx = ~isreal(A);
square = (m==n);
nz = nnz(A);

warns = warning('query','all');
temp = onCleanup(@()warning(warns));
warning('off','all');
disp(" ")
disp("            Size: " + m + "x" + n)
disp("         Density: " + 100*nz/(m*n) + "%")
if sparsity
  nrm = normest(A);
else
  nrm = norm(A);
end
disp("            Norm: " + sprintf('%.3g',nrm))
if square
    if sparsity
        c = condest(A);
    else
        c = cond(A);
    end
    disp("Condition Number: " + sprintf("%.3g",c))
    disp("     Determinant: " + sprintf("%.3g",det(A)))
end
[lb,ub] = bandwidth(A);
disp(" Upper bandwidth: " + ub)
disp(" Lower bandwidth: " + lb)
tol = max(size(A)) * eps(nrm);
if sparsity
    disp(" Structural Rank: " + sprank(A) + " (full rank: " + min(m,n) + ")")
else
    s = svd(A);
    disp("            Rank: " + nnz(s>tol) + " (full rank: " + min(m,n) + ")")
end
disp("         Storage: " + (whos('A').bytes)/1e6 + " MB")

disp(" ")
disp("Notable properties:")

if isreal(A)
    if issymmetric(A)
        disp("- A is real symmetric.")
    elseif issymmetric(A,'skew')
        disp("- A is real skew-symmetric.")
    elseif square && (max(abs(A-A'),[],'all') < tol*max(abs(A),[],'all'))
        disp("- A is real and close to being symmetric, but is not.")
    elseif sparsity && issymmetric(spones(A))
        disp("- A is pattern symmetric.")
    end
else
    if ishermitian(A)
        disp("- A is complex hermitian.")
    elseif ishermitian(A,'skew')
        disp("- A is complex skew-hermitian.")
    elseif issymmetric(A)
        disp("- A is complex symmetric.")
    elseif square && (max(abs(A-A'),[],'all') < tol*max(abs(A),[],'all'))
        disp("- A is complex and close to being hermitian, but is not.")
    elseif sparsity && issymmetric(spones(A))
        disp("- A is pattern symmetric.")
    end
end

if isdiag(A)
    disp("- A is diagonal.")
elseif istril(A)
    disp("- A is lower triangular.")
elseif istriu(A)
    disp("- A is upper triangular.")
elseif sparsity && nz~=numel(A) && (isbanded(A,round(m*0.5),n) || isbanded(A,m,round(n*0.5)))
    disp("- A is banded.")
end

if square
    if issymmetric(A)
        if all(diag(A) > 0)
            try decomposition(A,'chol');
                disp("- A is positive definite.")
            catch
            end
        elseif all(diag(A) < 0)
            try decomposition(-A,'chol');
                disp("- A is negative definite.")
            catch
            end
        end
    end
    if c >= 1/tol
        disp("- A is ill-conditioned (cond = " + sprintf('%.3g',c) + ").")
    end
end

end
