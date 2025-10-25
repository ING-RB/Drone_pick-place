function Z = mpower(X,Y)
%^  Matrix power.
%   Z = X^y is X to the y power if y is a scalar and X is square. If y
%   is an integer greater than one, the power is computed by repeated
%   squaring. For other values of y the calculation involves
%   eigenvalues and eigenvectors.
%
%   Z = x^Y is x to the Y power if Y is a square matrix and x is a scalar.
%   Computed using eigenvalues and eigenvectors.
%
%   Z = X^Y, where both X and Y are matrices, is an error.
%
%   C = MPOWER(A,B) is called for the syntax 'A ^ B' when A or B is an object.
%
%   See <a href="matlab:helpview('matlab','MATLAB_OPS')">MATLAB Operators and Special Characters</a> for more details.
%
%   See also POWER.

%   Copyright 1984-2024 The MathWorks, Inc.

if isscalar(X) && isscalar(Y)
    Z = X.^Y;
else
    if isinteger(X) || isinteger(Y)
        error(message('MATLAB:mpower:integerNotSupported'));
    end

    if ~ismatrix(X) || ~ismatrix(Y)
        error(message('MATLAB:mpower:inputsMustBe2D'));
    end

    if isa(X,'single') || isa(Y, 'single')
        try
            X = single(X);
            Y = single(Y);
        catch err
            if (strcmp(err.identifier, 'MATLAB:unimplementedSparseType'))
                error(message('MATLAB:mpower:sparseSingleNotSupported'))
            else
                rethrow(err);
            end
        end
    else
        X = double(X);
        Y = double(Y);
    end

    if isscalar(Y) && isreal(Y) && isfinite(Y) && round(Y) == Y ...
            && size(X,1) == size(X,2)
        Z = integerMpower(X,Y);
    else
        Z = generalMpower(X,Y);
    end
end

function Z = integerMpower(X,y)
if y == 0
    prototype = real(zeros("like", X)); %always real
    if anynan(X)
        Z = NaN(size(X),"like",prototype);
    else
        Z = eye(size(X),"like",prototype);
    end
else
    % X and y can be sparse
    % Z = X^y for integer y. Use repeated squaring.
    % For example: A^13 = A^1 * A^4 * A^8
    p = abs(y);
    if y < 0
        D = matlab.internal.math.nowarn.inv(X);
    else
        D = X;
    end
    first = true;
    while p > 0
        if rem(p,2) == 1 %if odd
            if first
                Z = D;  % hit first time. D*I
                first = false;
            else
                Z = D*Z;
            end
        end
        p = fix(p/2);
        if p ~= 0
            D = D*D;
        end
    end
end

function Z = generalMpower(X,Y)
if isscalar(Y) && size(X,1) == size(X,2)
    % If y is not a real integer-valued scalar, use eigenvalues
    % X and y should never be sparse.
    fullX = full(X);
    [V,d] = eig(fullX,'vector');
    if ishermitian(fullX) || ishermitian(fullX,'skew')
        Z = (V.*(d.^Y).')*V';
    else
        Vfact = matlab.internal.decomposition.DenseLU(V);
        rtol = 1e-2; % tolerance for rcond check
        if isreal(Y) && isfinite(Y) && rcond(Vfact) < rtol
            % Schur based algorithm for real scalar with fractional part
            Z = mpower_schur(fullX,Y);
        else
            Z = solve(Vfact, (V.*(d.^Y).')', true)';
        end
    end
    if issparse(X)
        Z = sparse(Z);
    end
elseif isscalar(X) && size(Y,1) == size(Y,2)
    % If x is a scalar and Y is a matrix, use eigenvalues.
    % x and Y should never be sparse.
    [V,d] = eig(full(Y),'vector');
    Z = matlab.internal.math.nowarn.mrdivide(V.*(X.^d).',V);
    if issparse(X)
        Z = sparse(Z);
    end
else
    Me = MException(message('MATLAB:mpower:notScalarAndSquareMatrix'));
    throwAsCaller(Me);
end

function [X,exitflag] = mpower_schur(A,p)
%MPOWER_SCHUR   Matrix power for real scalar power.
%   X = MPOWER_SCHUR(A,P) is A to the power P, where A is a square
%   matrix and P is a real number.
%
%   [X,EXITFLAG] = MPOWER_SCHUR(A,P) returns a scalar EXITFLAG that describes
%   the exit condition of MPOWER_SCHUR:
%   EXITFLAG = 0: successful completion of algorithm.
%   EXITFLAG = 1: too many matrix square roots needed.
%                 Computed X may still be accurate, however.
%
%   See also LOGM, EXPM, FUNM.

%   Reference: N. J. Higham and L. Lin, An Improved Schur--Pade Algorithm
%   for Fractional Powers of a Matrix and their Frechet Derivatives, SIAM
%   J. Matrix Anal. Appl. 34, 1341-1360, 2013

% Initialization.
n = size(A,1);
m = 0;
maxsqrt = 100;
exitflag = 0;

% Reduce range to -1 <= p <= 1.
pint = 0;
pfrac = p;
if p > 1
    pint = floor(p);
    pfrac = p - pint;
elseif p < -1
    pint = ceil(p);
    pfrac = p - pint;
end

% If A not already upper triangular
hasQ = ~istriu(A);
if ~hasQ
    T = A;
else
    [Q, T] = schur(A,'complex');
end

diagT = diag(T);

if n == 2
    X = powerm2by2(T,pfrac);
else % n > 2.
    T_old = T;
    q = 0;
    xvals = [ % Max norm(X) for degree m Pade approximant to (I-X)^p.
        1.512666672122460e-005    % m = 1
        2.236550782529778e-003    % m = 2
        1.882832775783885e-002    % m = 3
        6.036100693089764e-002    % m = 4
        1.239372725584911e-001    % m = 5
        1.998030690604271e-001    % m = 6
        2.787629930862099e-001];  % m = 7
    
    foundm = false;
    s0 = min_sqrts(diagT, xvals, maxsqrt);
    nsq = s0;
    for s = 1:nsq
        T = sqrtm_tri(T);
    end
    
    I = eye(n, class(T));
    TmI = T - I;
    d2 = normAm(TmI,2).^(1/2);
    d3 = normAm(TmI,3).^(1/3);
    alpha2 = max(d2,d3);
    if alpha2 <= xvals(2)
        m = find(alpha2 <= xvals(1:2),1);
        foundm = true;
    end
    
    while ~foundm
        more = 0; % more square roots
        if nsq > s0
            d3 = normAm(TmI,3)^(1/3);
        end
        d4 = normAm(TmI,4)^(1/4);
        alpha3 = max(d3,d4);
        if alpha3 <= xvals(7)
            j = find( alpha3 <= xvals(3:7),1) + 2;
            if j <= 6
                m = j; break
            else
                if alpha3/2 <= xvals(5) && q < 2
                    more = 1;
                    q = q+1;
                end
            end
        end
        if ~more
            d5 = normAm(TmI,5)^(1/5);
            alpha4 = max(d4,d5);
            eta = min(alpha3,alpha4);
            if eta <= xvals(7)
                m = find(eta <= xvals(6:7),1) + 5;
                break
            end
        end
        if nsq == maxsqrt
            exitflag = 1;
            m = 13;
            break
        end
        T = sqrtm_tri(T);
        TmI = T - I; 
        nsq = nsq + 1;
    end
    
    % Compute accurate superdiagonal of T^(1/2^s).
    for i = 1:n-1
        T(i:i+1,i:i+1) = powerm2by2(T_old(i:i+1,i:i+1),1/2^nsq);
    end
    
    % Compute accurate diagonal of I - T^(1/2^s).
    R = I - T;
    d = sqrt_power_1(diag(T_old),nsq);
    R(1:n+1:end) = -d;
    
    % Compute the [m/m] Pade approximant of the matrix power T^p = (I-R)^p
    % by evaluating a continued fraction representation.
    j = 2*m;
    cj = coeff(pfrac,j);
    Sj = cj*R;
    for j = 2*m-1:-1:1  % bottom-up
        cj = coeff(pfrac,j);
        Sjp1 = Sj;
        Sj = cj * matlab.internal.math.nowarn.mldivide(I + Sjp1, R);
    end
    X = I + Sj;
    
    % Squaring phase, with directly computed diagonal and superdiagonal.
    for s = 0:nsq
        if s ~= 0
            X = X*X; % squaring
        end
        for i = 1:n-1
            Tii = T_old(i:i+1,i:i+1);
            X(i:i+1,i:i+1) = powerm2by2(Tii,pfrac/(2^(nsq-s)));
        end
    end
end
if hasQ
    X = Q*X*Q';
end
if ~isreal(X) && isreal(A)
    X = make_real(X); % Remove imaginary part if within roundoff
end
if pint ~= 0
    X = integerMpower(A,pint)*X;   % A^p = A^pint * A^pfrac
end

function ss = min_sqrts(d, xvals, maxsqrt)
%MIN_SQRTS Minimal number of square roots needed.
ss = 0;
if norm(d,1) == 0
    return;
end
while norm(d-1,inf) > xvals(7) && ss < maxsqrt
    d = sqrt(d);
    ss = ss+1;
end
ss = min(ss, maxsqrt);

function c = coeff(p,i)
%COEFF The ith coefficient in the continued fraction representation
%   of the [m/m] Pade approximation for (1-x)^p.
if i == 1
    c = -p;
else
    jj = i/2;
    if jj == round(jj)
        c = (-jj + p) / (2*(2*jj-1));
    else
        jj = floor(jj);
        c = (-jj - p) / (2*(2*jj+1));
    end
end
    
function r = sqrt_power_1(a,n)
%SQRT_POWER_1    Accurate computation of a^(1/2^n)-1.
%  SQRT_POWER_1(A,N) computes a^(1/2^n)-1 accurately.
%
%  A. H. Al-Mohy, A more accurate Briggs method for the logarithm,
%  Numer. Algorithms, 59(3), 393-402, 2012.
if n == 0
    r = a-1;
else
    n0 = n;
    if angle(a) >= pi/2
        a = sqrt(a);
        n0 = n-1;
    end
    z0 = a - 1;
    a = sqrt(a);
    r = 1 + a;
    for i=1:n0-1
        a = sqrt(a);
        r = r.*(1+a);
    end
    r = z0./r;
end

function X = powerm2by2(A,p)
%powerm2by2 Power of 2-by-2 upper triangular matrix.
%   POWERM2BY2(A,p) is the 2 x 2 upper triangular matrix A to the 
%   real power p.
a1 = A(1,1);
a2 = A(2,2);
a1p = a1^p;
a2p = a2^p;
X = diag([a1p a2p]);

if a1 == a2
    X(1,2) = p.*A(1,2).*a1.^(p-1);
else
    z = (a2-a1)/(a2+a1);
    if (isreal(a1) && isreal(a2)) || check_condition(z)
        X(1,2) = A(1,2) .* (a2p - a1p) ./ (a2 - a1);
    else % Close eigenvalues.
        loga1 = log(a1);
        loga2 = log(a2);
        w = atanh(z) + 1i*pi*unwinding(loga2-loga1);
        dd = 2 .* exp(p.*(loga1+loga2)./2) .* sinh(p.*w) ./ (a2-a1);
        X(1,2) = A(1,2) .* dd;
    end
end
