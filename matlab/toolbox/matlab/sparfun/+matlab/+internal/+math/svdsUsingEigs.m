function [U,S,V] = svdsUsingEigs(A, k, sigma, options)
% SVDSUSINGEIGS Find a few singular values and vectors by calling EIGS.
% This is currently used by SVDS for numeric SIGMA.

%   Copyright 1984-2024 The MathWorks, Inc.

[m,n] = size(A);
p = min(m,n);
q = max(m,n);
support = matlab.internal.feature("SingleSparse");

useSingle = false;
if support
    useSingle = useSingle || isUnderlyingType(A, 'single');
end

% Helper arrays should be dense, real, and same underlying type as v0
proto = real(full(zeros("like",A)));

% B's positive eigenvalues are the singular values of A
% "top" of B's eigenvectors correspond to left singular values of A
% "bottom" of B's eigenvectors correspond to right singular vectors of A
if support
    B = [sparse(m,m,underlyingType(A)) A; A' sparse(n,n,underlyingType(A))];
else
    B = [sparse(m,m) A; A' sparse(n,n)];
end

if nargin < 2
    k = min(p,6);
end
if nnz(A) == 0
    U = eye(m,k,"like",proto);
    S = zeros(k,k,"like",proto);
    V = eye(n,k,"like",proto);
    return
end
if nargin < 3
    bk = min(p,k);
    bsigma = 'largestreal';
else
    bk = k;
    if strcmpi(sigma,'L')
        bsigma = 'largestreal';
    elseif isreal(sigma) && ((support && isa(sigma,'float'))...
            || (~support && isa(sigma,'double')))
        if sigma <= 0
            bk = 2 * min(p,k);
        end
        bsigma = sigma;
    else
        error(message('MATLAB:svds:InvalidArg3'))
    end
end
if nargin < 4
    % norm(B*W-W*D,1) / norm(B,1) <= tol / sqrt(2)
    % => norm(A*V-U*S,1) / norm(A,1) <= tol
    options = struct;
end

if isstruct(options)
    if ~isfield(options,'tol')
        if useSingle
            options.tol = 1e-5;
        else 
            options.tol = 1e-10;
        end
    end
    boptions.tol = options.tol / sqrt(2);
    if isfield(options,'maxit')
        boptions.maxit = options.maxit;
    end
    if ~isfield(options,'disp')
        options.disp = 0;
    end
    boptions.disp = options.disp;
    if isfield(options, 'u0')
        boptions.v0 = [options.u0; zeros(n, 1, "like", proto)];
    elseif isfield(options, 'v0')
        boptions.v0 = [zeros(m, 1, "like", proto); options.v0];
    end
    if ~isfield(options,'warn')
        options.warn = true;
    end
else
    error(message('MATLAB:svds:Arg4NotOptionsStruct'))
end
boptions.fail = 'drop';

if options.disp
    disp(getString(message('MATLAB:svds:EquationNumeric', num2str(bsigma))));
end

if options.warn
    [W,D] = eigs(B,bk,bsigma,boptions);
else
    [W,D,~] = eigs(B,bk,bsigma,boptions);
end

d = diag(D);
eigsConverged = length(d) == bk;

% Estimated norm of A
if ~isnumeric(bsigma)
    nA = max(d);
else
    nA = normest(A);
end

% Tolerance to determine the "small" singular values of A.
% If eigs did not converge, give extra leeway.
epsT = eps("like",proto);
if ~eigsConverged
    dtol = q * nA * sqrt(epsT);
    uvtol = m * sqrt(sqrt(epsT));
else
    dtol = q * nA * epsT;
    uvtol = m * sqrt(epsT);
end

% Which (left singular) vectors are already orthogonal, with norm 1/sqrt(2)?
UU = W(1:m,:)' * W(1:m,:);
dUU = diag(UU);
VV = W(m+(1:n),:)' * W(m+(1:n),:);
dVV = diag(VV);
indpos = find((d > dtol) & (abs(dUU-0.5) <= uvtol) & (abs(dVV-0.5) <= uvtol));
indpos = indpos(1:min(end,k));
npos = length(indpos);
U = sqrt(2) * W(1:m,indpos);
s = d(indpos);
V = sqrt(2) * W(m+(1:n),indpos);

% There may be 2*(p-rank(A)) zero eigenvalues of B corresponding
% to the rank deficiency of A and up to q-p zero eigenvalues
% of B corresponding to the difference between m and n.

if npos < k
    indzero = find(abs(d) <= dtol);
    QWU = orth(W(1:m,indzero));
    QWV = orth(W(m+(1:n),indzero));
    nzero = min([size(QWU,2), size(QWV,2), k-npos]);
    U = [U matlab.internal.math.viewColumns(QWU, nzero)];
    s = [s; abs(d(indzero(1:nzero)))];
    V = [V matlab.internal.math.viewColumns(QWV, nzero)];
else
    nzero = 0;
end

if options.disp
    disp(getString(message('MATLAB:svds:SingValsFromEigVals', npos+nzero, npos, nzero)));
end

% sort the singular values in descending order (as in svd)
[s,ind] = sort(s);
s = s(end:-1:1);

U = U(:,ind(end:-1:1));
V = V(:,ind(end:-1:1));

% Check convergence based on the residuals
r1 = A*V - U.*s';
r2 = A'*U - V.*s';

isNotConverged = ~(max(sum(conj(r1).*r1, 1), sum(conj(r2).*r2, 1)) <= ...
    options.tol*s');

if options.disp
    if any(isNotConverged)
        relres = max(sum(conj(r1).*r1, 1), sum(conj(r2).*r2, 1))./s';
        minrelres = min(relres(isNotConverged));
        disp(getString(message('MATLAB:svds:ResidualDecision', nnz(isNotConverged), sprintf('%.1e', minrelres))));
    else
        disp(getString(message('MATLAB:svds:ResidualDecisionAccept')));
    end
end

% Always drop non-converged singular values:
if any(isNotConverged)
    U = U(:, ~isNotConverged);
    s = s(~isNotConverged);
end

if eigsConverged && length(s) < k && sigma > 0 && options.warn
    warning(message('MATLAB:svds:SigmaTooSmall', length(s)));
end

if nargout == 1
    % Never called from SVDS anymore
    U = s;
else
    S = diag(s);
end
