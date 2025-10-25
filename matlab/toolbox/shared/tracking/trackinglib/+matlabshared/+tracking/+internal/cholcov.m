function [T,p] = cholcov(sigma)
%CHOLCOV  Cholesky-like decomposition for covariance matrix.
%   T = CHOLCOV(SIGMA) computes T such that SIGMA = T'*T.  SIGMA must be
%   square, symmetric, and positive semi-definite.  If SIGMA is positive
%   definite, then T is the square, upper triangular Cholesky factor.
%
%   If SIGMA is not positive definite, T is computed from an eigenvalue
%   decomposition of SIGMA.  T is not necessarily triangular or square in
%   this case.  Any eigenvectors whose corresponding eigenvalue is close to
%   zero (within a small tolerance) are omitted.  If any remaining
%   eigenvalues are negative, T is empty.
%
%   [T,P] = CHOLCOV(SIGMA) returns the number of negative eigenvalues of
%   SIGMA, and T is empty if P>0.  If P==0, SIGMA is positive semi-definite.
%
%   If SIGMA is not square and symmetric, P is NaN and T is empty.
%
%   SIGMA has to be of data type double.

%   Copyright 2015 The MathWorks, Inc.

%#codegen

validateattributes(sigma, {'double'}, {}, 'cholcov', 'sigma');

% Test for square, symmetric
[n,m] = size(sigma);
tol = 10*eps(max(abs(diag(sigma))));

% Assign default returns
T = zeros(0,'like',sigma);
p = nan('like',sigma);

if (n == m) && all(all(abs(sigma - sigma') < tol))
    [T,p] = chol(sigma);

    if p > 0
        % Test for positive definiteness
        
        % Can get factors of the form sigma==T'*T using the eigenvalue
        % decomposition of a symmetric matrix, so long as the matrix
        % is positive semi-definite.
        [U,D] = eig(full((sigma+sigma')/2));
        
        % Pick eigenvector direction so max abs coordinate is positive
        [~,maxind] = max(abs(U),[],1);
        negloc = (U(maxind + (0:n:(m-1)*n)) < 0);
        U(:,negloc) = -U(:,negloc);
        
        D = diag(D);
        tol = eps(max(D)) * length(D);
        t = (abs(D) > tol);
        D = D(t);
        p = sum(D<0); % number of negative eigenvalues
        
        if (p==0)
            T = diag(sqrt(D)) * U(:,t)';
        else
            T = zeros(0,'like',sigma);
        end
    end
end
