function f = expmv_1(A,mu,b,t,M,tol,prec,n,isrealA)
%EXPMV_1   Matrix exponential times vector.
%   F = EXPMV_1(A,mu,b,t,M,tol,prec,n,isrealA) computes EXPM(t*A)*b without
%   explicitly forming EXPM(t*(A + mu*I).  Other input arguments:
%   mu = scalar shift applied to A.
%   M = matrix used to determine scaling and polynomial degree.
%   tol = convergence tolerance.
%   prec = class of A.
%   n = dimension of A.
%   isrealA (logical) = real A or not.

%   Copyright 2023 The MathWorks, Inc.

if isempty(M)
    tt = 1;
    M = select_taylor_degree(A,b,t,prec,n,isrealA,false);
else
    tt = t;
end

s = 1;
if t == 0
    m = 0;
else
    [m_max, p] = size(M);
    C = (ceil(abs(tt)*M))' .* (1:m_max);
    C (C == 0) = inf;
    if p > 1
        [cost, m] = min(min(C)); % cost is the overall cost.
    else
        [cost, m] = min(C);  % When C is one column. Happens if p_max = 2.
    end
    if cost == inf
        cost = 0;
    end
    s = max(cost/m,1);
end
eta = 1;
if isfloat(A)
    % shift
    eta = exp(t*mu/s);
end
f = b;
% For some matrix t*A with very large norm, s can be larger than the for loop
% maximum iteration limit and trigger a warning. We cap the number of iteration to avoid for loop index limit
% warning here.
maxiter = min(intmax('int64')-1, s);
for i = 1:maxiter
    c1 = norm(b,inf);
    for k = 1:m
        if isfloat(A)
            b = (t/(s*k))*(A*b);
        else
            % function handle A
            b = (t/(s*k))*A('notransp',b);
        end
        f =  f + b;
        c2 = norm(b,inf);
        if c1 + c2 <= tol*norm(f,inf)
            break
        end
        c1 = c2;
    end
    f = eta*f;
    if norm(f,1) == 0 || anynan(f)
        break;
    end
    b = f;
end
