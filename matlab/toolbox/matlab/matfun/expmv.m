function X = expmv(A,b,tvals)
%EXPMV  Matrix exponential times vector.
%   F = EXPMV(A,b,t) computes expm(t*A)*b without explicitly forming the
%   matrix exponential expm(t*A), where A is an n-by-n matrix, b is an
%   n-by-1 column vector, and t is a scalar. The output F is an n-by-1
%   column vector.
%
%   F = EXPMV(AFUN,b,t) accepts a function handle AFUN instead of the
%   matrix A. AFUN(FLAG, X) accepts a matrix input X and returns the
%   following values for the indicated FLAG:
%
%       FLAG      returns
%      ---------------------------
%      'real'     true if A is real, false otherwise
%      'notransp' A  * X
%      'transp'   A' * X
%
%   In all of the following syntaxes, you can replace A by AFUN.
%
%   F = EXPMV(A,b) is the same as EXPMV(A,b,1).
%
%   F = EXPMV(A,b,tvals) computes expm(t*A)*b without explicitly forming
%   expm(t*A) for each element t in tvals, where tvals is a vector of
%   length m. The output F is an n-by-m matrix such that each column of F
%   is
%
%      F(:,j) = expm(tvals(j)*A)*b, for j = 1:m.
%
%   For equally spaced tvals, such as a time vector with a fixed time step,
%   expmv uses an efficient algorithm which reuses information. The MATLAB
%   function isuniform is used to check whether tvals is equally spaced.
%
%   See also expm, isuniform.

%   Reference: A. H. Al-Mohy and N. J. Higham. Computing the action of the
%   matrix exponential, with an application to exponential integrators.
%   SIAM J. Sci. Comput., 33(2):488-511, 2011.
%
%   Awad H. Al-Mohy and Nicholas J. Higham.
%   Copyright 2023-2024 The MathWorks, Inc.

if ismatrix(A) && isfloat(A)
    % Check matrix and right-hand side vector inputs have appropriate sizes.
    n = size(A,1);
    if size(A,2) ~= n
        error(message('MATLAB:expmv:mustBeSquare'));
    end
    if ~isfloat(b) || ~iscolumn(b)
        error(message('MATLAB:expmv:nonColumnVector'));
    end
    if size(b,1) ~= n
        error(message('MATLAB:expmv:sizeMustMatch'));
    end
    prec = class(A);
    isrealA = isreal(A);
    % For matrix A, we always shift
    mu = trace(A)/n;
    A = A - mu*eye(n,"like",A);
elseif isa(A, 'function_handle') % Function.
    if ~isfloat(b) || ~iscolumn(b)
        error(message('MATLAB:expmv:nonColumnVector'));
    end
    % Determine class of A by forming y = A*ones(n,1):
    % A is same type as y, as single*double is single.
    n = size(b,1);
    temp = A('notransp', ones(n,1));
    if ~isfloat(temp)
        error(message('MATLAB:expmv:functionHandleMustReturnFloat'));
    end
    if ~iscolumn(b) || size(temp,1) ~= n
        error(message('MATLAB:expmv:functionHandleMustReturnSameSize'));
    end
    prec = class(temp);
    % check is A is considered as real.
    isrealA = A('real',[]);
    % no shift for function handle.
    mu = 0;
else
    error(message('MATLAB:expmv:ANotMatrixorFunction'));
end

if nargin < 3
    tvals = 1;
elseif ~isvector(tvals) || ~isfloat(tvals) || ~isreal(tvals)
    error(message('MATLAB:expmv:nonFloatVector'));
end

% Set tolerence
if prec == "single"
    tol = 2^(-24);
else
    % default to double precision
    tol = 2^(-53);
end

% Check if tvals is equally space
isUni = false;
h = NaN;
if numel(tvals) > 2
    [isUni, h] = isuniform(tvals);
end

% Begin calculation
if ~isUni || h == 0
    % loop through each element of tvals
    if isempty(tvals)
       x1 = expmv_1(A,mu,b,zeros(class(tvals)),[],tol,prec,n,isrealA);
       X = zeros(n,0,class(x1));
    elseif isscalar(tvals) || h == 0
       X = expmv_1(A,mu,b,tvals(1),[],tol,prec,n,isrealA);
       if h == 0 % repeated points
           X = repmat(X, 1, numel(tvals));
       end
    else
       X = expmv_loop(A,mu,b,tvals,tol,prec,n,isrealA);
    end
else
    if isfloat(A)
        normA = norm(A,1);
    else
        normA = normAm(A,1,n,isrealA,prec);  % Estimate the 1-norm.
    end

    force_estimate = false;
    temp = (tvals(end) - tvals(1))*normA; %make sense for uniform data only
    if prec == "single" || (prec == "double" && temp > 63.152)
        force_estimate = true;
    end

    %  M is used to determine scaling and polynomial degree.
    M = select_taylor_degree(A,b,1,prec,n,isrealA,force_estimate);

    numtvals = numel(tvals);
    m_max = size(M,1);
    [~, s] = degree_selector(tvals(end)-tvals(1), M, m_max);
    q = numtvals - 1;

    xk = expmv_1(A,mu,b,tvals(1),M,tol,prec,n,isrealA);
    if norm(xk, 1) == 0
        % The first iteration most likely suffered from underflow
        % Switch to compute each column independently.
        X = expmv_loop(A,mu,b,tvals,tol,prec,n,isrealA);
    else
        X = zeros(n, numtvals, "like", xk);
        X(:,1) = xk;
        if q <= s
            for k = 2:numtvals
                xk = expmv_1(A,mu,xk,h,M,tol,prec,n,isrealA);
                X(:,k) = xk;
            end
        else
            d = floor(q/s);
            j = floor(q/d);
            r = q-d*j;
            z = xk;
            m_opt = degree_selector(d, M, m_max);
            dr = d;
            for i = 1:j+1
                if i > j
                    dr = r;
                end
                K = zeros(n, m_opt+1, "like", z);
                K(:,1) = z;
                m = 0;
                for k = 1:dr
                    f = z;
                    c1 = norm(z,inf);
                    for p = 1:m_opt
                        if p > m
                            if isfloat(A)
                                K(:,p+1) = (h/p)*A*K(:,p);
                            else
                                K(:,p+1) = (h/p)*A('notransp',K(:,p));
                            end
                        end
                        temp = (k^p)*K(:,p+1);
                        f = f + temp;
                        c2 = norm(temp,inf);
                        if  c1 + c2 <= tol*norm(f,inf)
                            break
                        end
                        c1 = c2;
                    end
                    m = max(m,p); % m is the computed Columns Of K
                    X(:,k+(i-1)*d+1) = exp(k*h*mu)*f;
                end
                if i <= j
                    z = X(:,i*d+1);
                end
            end
        end
    end
end

%---------- Local function -------------
function X = expmv_loop(A,mu,b,tvals,tol,prec,n,isrealA)
x1 = expmv_1(A,mu,b,tvals(1),[],tol,prec,n,isrealA);
X = zeros(n,numel(tvals),"like",x1);
X(:,1) = x1;
for k = 2:numel(tvals)
    X(:,k) = expmv_1(A,mu,b,tvals(k),[],tol,prec,n,isrealA);
end

%---------------------------------------
function [m, ss] = degree_selector(t,M,m_max)
C = (ceil(abs(t)*M))' .* (1:m_max);
C (C == 0) = inf;
% cost is the overall cost.
[cost, m] = min(min(C));
if cost == inf
    cost = 0;
end
ss = max(cost/m,1);