function  M = select_taylor_degree(A,b,t,prec,n,isrealA,force_estm)
%SELECT_TAYLOR_DEGREE   Select degree of Taylor approximation.
%   M = SELECT_TAYLOR_DEGREE(A,b,t,prec,n,isrealA,shift,force_estm)
%   forms a matrix M for use in determining the truncated Taylor series
%   degree in EXPMV and EXPMV_TSPAN.
%   Other input arguments:
%   prec = class of A.
%   n = dimension of A.
%   isrealA (logical) = real A or not.
%   force_estm (logical) = force use of norm estimator or not.

%   Copyright 2023 The MathWorks, Inc.

p_max = 8;
m_max = 55;
theta = getParameters(prec);

if ~force_estm
    if isfloat(A)
        normA = abs(t)*norm(A,1);
    else
        normA = abs(t)*normAm(A,1,n,isrealA,prec);  % Estimate 1-norm.
    end
end

if ~force_estm && normA <= 4*theta(m_max)*p_max*(p_max + 3)/(m_max*size(b,2))
    % Base choice of m on normA, not the alpha_p.
    c = normA;
    alpha = c*ones(p_max-1,1);
else
    eta = zeros(p_max,1);
    alpha = zeros(p_max-1,1);
    for p = 1:p_max
        c = normAm(A,p+1,n,isrealA,prec);
        c = abs(t)*c^(1/(p+1));
        eta(p) = c;
    end
    for p = 1:p_max-1
        alpha(p) = max(eta(p),eta(p+1));
    end
end
M = zeros(m_max,p_max-1);
for p = 2:p_max
    for m = p*(p-1)-1 : m_max
        M(m,p-1) = alpha(p-1)/theta(m);
    end
end
