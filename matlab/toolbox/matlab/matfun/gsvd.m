function [U,V,X,C,S] = gsvd(A,B,flag)
%GSVD   Generalized Singular Value Decomposition.
%   [U,V,X,C,S] = GSVD(A,B) returns unitary matrices U and V,
%   a (usually) square matrix X, and nonnegative diagonal matrices
%   C and S so that
%
%       A = U*C*X'
%       B = V*S*X'
%       C'*C + S'*S = I
%
%   A and B must have the same number of columns, but may have
%   different numbers of rows.  If A is m-by-p and B is n-by-p, then
%   U is m-by-m, V is n-by-n and X is p-by-q where q is the numerical rank
%   of [A; B].
%
%   The nonzero elements of S are always on its main diagonal.  The nonzero
%   elements of C are on the diagonal diag(C,max(0,q-m)). Thus, if m >= q,
%   the nonzero elements are on the main diagonal of C.  The diagonal
%   elements are ordered so that the generalized singular values are
%   nondecreasing.
%
%   SIGMA = GSVD(A,B) returns the vector of generalized singular
%   values, sqrt(diag(C'*C)./diag(S'*S)).
%
%   [U,V,X,C,S] = GSVD(A,B,"econ") with three input arguments and either m
%   or n >= p, produces the "economy-sized" decomposition where the
%   resulting U and V have at most p columns, and C and S have at most p
%   rows. The generalized singular values are diag(C)./diag(S).
%
%   [U,V,X,C,S] = GSVD(A,B,0) is equivalent to GSVD(A,B,"econ"). This
%   syntax is not recommended, use GSVD(A,B,"econ") instead.
%
%   When I = eye(size(A)), the generalized singular values, gsvd(A,I),
%   are equal to the ordinary singular values, svd(A), but they are
%   sorted in the opposite order.  Their reciprocals are gsvd(I,A).
%
%   No assumptions are made about the individual ranks of A or B.  The
%   matrix X has full rank, and has as many columns as the numerical rank
%   of matrix [A; B]. Additionally, svd(X) has the same singular values as
%   svd([A; B]), except for those that are numerically zero.
%
%   Class support for inputs A,B:
%      float: double, single
%
%   See also SVD.

%   Copyright 1984-2024 The MathWorks, Inc.

[m,p]  = size(A);
[n,pb] = size(B);
if pb ~= p
    error(message('MATLAB:gsvd:MatrixColMismatch'))
end

useQA = false;
useQB = false;
if nargin > 2
    zeroFlag = isnumeric(flag) && isscalar(flag) && flag == 0;
    econFlag = ( (ischar(flag) && isrow(flag)) || (isstring(flag) && isscalar(flag)) ) && ...
            strncmpi(flag, 'econ', strlength(flag));
    if ~zeroFlag && ~econFlag
        error(message('MATLAB:gsvd:InvalidFlag'));
    end
    
    % Economy-sized.
    useQA = m > p;
    useQB = n > p;
    if useQA
        [QA,A] = qr(A,'econ');
        m = p;
    end
    if useQB
        [QB,B] = qr(B,'econ');
        n = p;
    end
end

[Q,R,perm] = qr([A;B],0);

% Determine numerical rank r of R and cut Q to only rank r.
if isempty(R)
    q = 0;
else
    tol = max(m+n, p) * eps(abs(R(1,1)));
    q = sum(abs(diagk(R, 0)) > tol);
end
if q < size(Q, 2)
    Q = Q(:, 1:q);
    R = R(1:q, :);
end

R(:, perm) = R;

[U,V,Z,C,S] = csd(Q(1:m,:),Q(m+1:m+n,:));

if nargout < 2
    % Vector of generalized singular values.
    U = [zeros(q-m,1,"like",C); diagk(C,max(0,q-m))]./ ...
        [diagk(S,0); zeros(q-n,1,"like",S)];
else
    % Full composition.
    X = R'*Z;
    if useQA
        U = QA*U;
    end
    if useQB
        V = QB*V;
    end
end


function [U,V,Z,C,S] = csd(Q1,Q2)
% CSD  Cosine-Sine Decomposition
% [U,V,Z,C,S] = csd(Q1,Q2)
%
% Given Q1 and Q2 such that Q1'*Q1 + Q2'*Q2 = I, the
% C-S Decomposition is a joint factorization of the form
%    Q1 = U*C*Z' and Q2=V*S*Z'
% where U, V, and Z are orthogonal matrices and C and S
% are diagonal matrices (not necessarily square) satisfying
%    C'*C + S'*S = I

[m,p] = size(Q1);
n = size(Q2,1);

if m < n
    [V,U,Z,S,C] = csd(Q2,Q1);
    j = p:-1:1; C = C(:,j); S = S(:,j); Z = Z(:,j);
    m = min(m,p); i = m:-1:1; C(1:m,:) = C(i,:); U(:,1:m) = U(:,i);
    n = min(n,p); i = n:-1:1; S(1:n,:) = S(i,:); V(:,1:n) = V(:,i);
    return
end
% Henceforth, n <= m. Note also m+n >= p since [Q1; Q2] came from an
% economy-sized QR.

if m == 1 && p > 1
    % Early return, to avoid hard-to-understand treatments to make the
    % general algorithm treat this correctly.
    % This case is only hit for m == 1,  n == 1, and p == 2.
    Z = [Q2; Q1]';
    U = real(ones("like", Z));
    V = U;
    C = cast([0 1], "like", U);
    S = cast([1 0], "like", U);
    return;
end

[U,C,Z] = svd(Q1);

q = min(m,p);
i = 1:q;
j = q:-1:1;
C(i,i) = C(j,j);
U(:,i) = U(:,j);
Z(:,i) = Z(:,j);
S = Q2*Z;

if q == 1
    k = 0;
elseif m < p
    k = n;
else
    k = max([0; find(diag(C) <= 1/sqrt(2))]);
end
[V,~] = qr(S(:,1:k));
S = V'*S;
r = min(k,m);
S(:,1:r) = diagf(S(:,1:r));

if k < min(n,p)
    r = min(n,p);
    i = k+1:n;
    j = k+1:r;
    [UT,ST,VT] = svd(S(i,j));
    if k > 0
        S(1:k,j) = 0;
    end
    S(i,j) = ST;
    C(:,j) = C(:,j)*VT;
    V(:,i) = V(:,i)*UT;
    Z(:,j) = Z(:,j)*VT;
    i = k+1:q;
    [Q,R] = qr(C(i,j));
    C(i,j) = diagf(R);
    U(:,i) = U(:,i)*Q;
end

if m < p
    % Diagonalize final block of S and permute blocks.
    q = min([nnz(abs(diagk(C,0))>10*m*eps(class(C))), ...
        nnz(abs(diagk(S,0))>10*n*eps(class(C))), ...
        nnz(max(abs(S(:,m+1:p)),[],2)<sqrt(eps(class(C))))]);
    
    % maxq: maximum size of q such that the expression used later on,
    %        i = [q+1:q+p-m, 1:q, q+p-m+1:n],
    % is still a valid permutation.
    maxq = m+n-p;
    q = q + nnz(max(abs(S(:,q+1:maxq)),[],1)>sqrt(eps(class(C))));
    
    i = q+1:n;
    j = m+1:p;
    % At this point, S(i,j) should have orthogonal columns and the
    % elements of S(:,q+1:p) outside of S(i,j) should be negligible.
    [Q,R] = qr(S(i,j));
    S(:,q+1:p) = 0;
    S(i,j) = diagf(R);
    V(:,i) = V(:,i)*Q;
    if n > 1
        i = [q+1:q+p-m, 1:q, q+p-m+1:n];
    else
        i = 1;
    end
    j = [m+1:p 1:m];
    C = C(:,j);
    S = S(i,j);
    Z = Z(:,j);
    V = V(:,i);
end

if n < p
    % Final block of S is negligible.
    S(:,n+1:p) = 0;
end

% Make sure C and S are real and positive.
[U,C] = diagp(U,C,max(0,p-m));
C = real(C);
[V,S] = diagp(V,S,0);
S = real(S);


% Guarantee some standards that may only be true up to round-off at this
% point: c./s must be sorted in ascending order, must have c, s <= 1, if
% one of c, s is exactly 0 make the other exactly 1.

% Get indices to extract diagonal values out of C and S matrix. Also, for
% blocks that are always identity matrices, set diagonal to exactly one.
if m>=p && n>=p
    % C = [diag(c); zeros(m-p, p)], S = [diag(s); zeros(n-p, p)]
    rowsC = 1:p;
    rowsS = 1:p;
    cols = 1:p;
elseif m>=p && n<p
    % C = [blkdiag(diag(c), eye(p-n)); zeros(m-p, p)],
    % S = [diag(s), zeros(n, p-n)]
    rowsC = 1:n;
    rowsS = 1:n;
    cols = 1:n;

    ind = n+1:p;
    C(ind+(ind-1)*size(C, 1)) = 1;
elseif m<p && n<p
    % C = [zeros(m, p-m), blkdiag(diag(c), eye(p-n))], 
    % S = [blkdiag(eye(p-m), diag(s)), zeros(n, p-n)]
    rowsC = 1:m+n-p;
    rowsS = p-m+1:n;
    cols = p-m+1:n;

    indR = m+n-p+1:m;
    indC = n+1:p;
    C(indR+(indC-1)*size(C, 1)) = 1;

    indR = 1:p-m;
    indC = 1:p-m;
    S(indR+(indC-1)*size(S, 1)) = 1;
end
% Case m<p && n>=p isn't hit because we switch input order there.
% If it existed, it would be doing
% C = [zeros(m, p-m), diag(c)], S = [blkdiag(eye(p-m), diag(s)); zeros(n-p, p)]
% Also note: length(cols) == length(rowsC) == length(rowsS) == min([m,n,p,m+n-p])

% Extract parts of c, s diagonal which aren't structurally always 0 or 1.
c = C(rowsC+(cols-1)*size(C, 1));
s = S(rowsS+(cols-1)*size(S, 1));

% Renormalize the values of c and s. cs is already 1 up to round-off.
% This ensures c, s <= 1 and means that cases where the ordering doesn't
% doesn't match up (e.g., c = [1 1+eps], s = [eps 2*eps]) are cleared up.
cs = hypot(c, s);
c = c./cs;
s = s./cs;

if ~issorted(c./s,'ascend')
    % Sort generalized singular values to be ascending. Could sort based on
    % c and s separately in a more complicated way, but c./s is what the doc
    % actually promises to be ascending.
    [~, perm] = sort(c./s);
    
    % Permute diagonal values
    c = c(perm);
    s = s(perm);

    % Permute U, V, Z to correspond to this change.
    U(:, rowsC) = U(:, rowsC(1)-1+perm);
    V(:, rowsS) = V(:, rowsS(1)-1+perm);
    Z(:, cols) = Z(:, cols(1)-1+perm);
end

% Update with the new diagonal values
C(rowsC+(cols-1)*size(C, 1)) = c;
S(rowsS+(cols-1)*size(S, 1)) = s;

% ------------------------

function D = diagk(X,k)
% DIAGK  K-th matrix diagonal.
% DIAGK(X,k) is the k-th diagonal of X, even if X is a vector.
D = matlab.internal.math.diagExtract(X,k);

% ------------------------

function X = diagf(X)
% DIAGF  Diagonal force.
% X = DIAGF(X) zeros all the elements off the main diagonal of X.
X = triu(tril(X));

% ------------------------

function [Y,X] = diagp(Y,X,k)
% DIAGP  Diagonal positive.
% [Y,X] = diagp(Y,X,k) scales the columns of Y and the rows of X by
% unimodular factors to make the k-th diagonal of X real and positive.
D = diagk(X,k);
j = find(real(D) < 0 | imag(D) ~= 0);
D = diag(conj(D(j))./abs(D(j)));
Y(:,j) = Y(:,j)*D';
X(j,:) = D*X(j,:);
X = X+0; % use "+0" to set possible -0 elements to 0
