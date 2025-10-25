% Sparse matrices.
%
% Elementary sparse matrices.
%   speye       - Sparse identity matrix.
%   sprand      - Sparse uniformly distributed random matrix.
%   sprandn     - Sparse normally distributed random matrix.
%   sprandsym   - Sparse random symmetric matrix.
%   spdiags     - Sparse matrix formed from diagonals.
%
% Full to sparse conversion.
%   sparse      - Create sparse matrix.
%   full        - Convert sparse matrix to full matrix.
%   find        - Find indices of nonzero elements.
%   spconvert   - Import from sparse matrix external format.
%
% Working with sparse matrices.
%   nnz         - Number of nonzero matrix elements.
%   nonzeros    - Nonzero matrix elements.
%   nzmax       - Amount of storage allocated for nonzero matrix elements.
%   spones      - Replace nonzero sparse matrix elements with ones.
%   spalloc     - Allocate space for sparse matrix.
%   issparse    - True for sparse matrix.
%   spfun       - Apply function to nonzero matrix elements.
%
% Reordering algorithms.
%   amd         - Approximate minimum degree permutation.
%   colamd      - Column approximate minimum degree permutation.
%   symamd      - Symmetric approximate minimum degree permutation.
%   symrcm      - Symmetric reverse Cuthill-McKee permutation.
%   colperm     - Column permutation.
%   dmperm      - Dulmage-Mendelsohn permutation.
%   dissect     - Nested dissection permutation.
%   equilibrate - Matrix equilibration.
%
% Linear algebra.
%   eigs        - A few eigenvalues and eigenvectors.
%   svds        - A few singular values and vectors.
%   ilu         - Incomplete LU factorization.
%   ichol       - Incomplete Cholesky factorization.
%   normest     - Estimate the matrix 2-norm.
%   condest     - 1-norm condition number estimate.
%   sprank      - Structural rank.
%
% Linear Equations (iterative methods).
%   pcg         - Preconditioned Conjugate Gradients Method.
%   bicg        - BiConjugate Gradients Method.
%   bicgstab    - BiConjugate Gradients Stabilized Method.
%   bicgstabl   - BiCGStab(l) Method.
%   cgs         - Conjugate Gradients Squared Method.
%   gmres       - Generalized Minimum Residual Method.
%   lsqr        - LSQR Method.
%   minres      - Minimum Residual Method.
%   qmr         - Quasi-Minimal Residual Method.
%   symmlq      - Symmetric LQ Method.
%   tfqmr       - Transpose-Free QMR Method.
%
% Operations on graphs (trees).
%   treelayout  - Lay out tree or forest.
%   etree       - Elimination tree.
%
% Miscellaneous.
%   symbfact    - Symbolic factorization analysis.
%   spparms     - Set parameters for sparse matrix routines.
%   spaugment   - Form least squares augmented system.
%   numgrid     - Number the grid points in a two dimensional region.
%   delsq       - Construct five-point finite difference Laplacian.

% Utility functions.
%   rjr         - Random Jacobi rotation.
%   unmesh      - Convert a list of edges to a graph or matrix.

%   Copyright 1984-2018 The MathWorks, Inc.

