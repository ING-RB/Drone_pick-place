function [y0,yp0,resnrm] = decic(odefun,t0,y0,fixed_y0,yp0,fixed_yp0,...
                                 options,varargin)
%DECIC  Compute consistent initial conditions for ODE15I.
%   [Y0MOD,YP0MOD] = DECIC(ODEFUN,T0,Y0,FIXED_Y0,YP0,FIXED_YP0) uses the input
%   Y0,YP0 as initial guesses for an iteration to find output values such
%   that ODEFUN(T0,Y0MOD,YP0MOD) = 0. ODEFUN is a function handle.  T0 is 
%   a scalar, Y0 and YP0 are column vectors. FIXED_Y0 and FIXED_YP0 are vectors 
%   of zeros and ones. DECIC changes as few components of the guess as possible. 
%   You can specify that certain components are to be held fixed by setting 
%   FIXED_Y0(i) = 1 if no change is permitted in the guess for Y0(i) and 0 
%   otherwise. An empty array for FIXED_Y0 is interpreted as allowing changes 
%   in all entries. FIXED_YP0 is handled similarly. 
%
%   You cannot fix more than length(Y0) components. Depending on the problem,
%   it may not be possible to fix this many. It also may not be possible to
%   fix certain components of Y0 or YP0. It is recommended that you fix no
%   more components than necessary. 
% 
%   [Y0MOD,YP0MOD] = DECIC(ODEFUN,T0,Y0,FIXED_Y0,YP0,FIXED_YP0,OPTIONS)
%   computes as above with default values of integration tolerances replaced 
%   by the values in OPTIONS, a structure created with the ODESET function. 
%
%   [Y0MOD,YP0MOD,RESNRM] = DECIC(ODEFUN,T0,Y0,FIXED_Y0,YP0,FIXED_YP0...)
%   returns the norm of ODEFUN(T0,Y0MOD,YP0MOD) as RESNRM. If the norm 
%   seems unduly large, use OPTIONS to specify smaller RelTol (1e-3 by default).
%
%   See also ODE15I, ODESET, IHB1DAE, IBURGERSODE, FUNCTION_HANDLE.

%   Jacek Kierzenka and Lawrence F. Shampine
%   Copyright 1984-2024 The MathWorks, Inc.

neq = length(y0);
if isempty(fixed_y0)
    free_y = 1:neq;
else
    free_y = find(fixed_y0 == 0);
end
if isempty(fixed_yp0)
    free_yp = 1:neq;
else
    free_yp = find(fixed_yp0 == 0);
end
if length(free_y) + length(free_yp) < neq
    error(message('MATLAB:decic:TooManySpecified',sprintf('%i', neq)));
end

if nargin < 7
    options = [];
end

rtol = odeget(options,'RelTol',1e-3);
if (length(rtol) ~= 1) || (rtol <= 0)
    error(message('MATLAB:decic:OptRelTolNotPosScalar'));
end
if rtol < 100 * eps
    rtol = 100 * eps;
    warning(message('MATLAB:decic:RelTolIncrease',sprintf('%g',rtol)));
end
atol = odeget(options,'AbsTol',1e-6);
if any(atol <= 0)
    error(message('MATLAB:decic:OptAbsTolNotPos'));
end

y0 = y0(:);
yp0 = yp0(:);
odeArgs = varargin;
res = odefun(t0,y0,yp0,odeArgs{:});

% Initialize the partial derivatives
[Jac,dfdy,dfdyp,Jconstant,dfdy_options,dfdyp_options] = ...
    ode15ipdinit(odefun,t0,y0,yp0,res,options,odeArgs);

resnrm0 = norm(res);

for counter = 1:10

    % compute Jacobian info for chord iterations
    if ~Jconstant || (Jconstant && counter == 1)
        [d_rank,Qfunc,R,E,S] = getJacInfoForIter(dfdy,dfdyp,neq,free_y,free_yp);
    end

    for chord = 1:3
        [dy,dyp] = sls(res,neq,free_y,free_yp,d_rank,Qfunc,R,E,S);

        % If the increments are too big, limit the change
        % in norm to a factor of 2--trust region.
        nrmv = max(norm([y0; yp0]),norm(atol));
        nrmdv = norm([dy; dyp]);
        if nrmdv > 2*nrmv
            factor = 2*nrmv/nrmdv;
            dy = factor*dy;
            dyp = factor*dyp;
            nrmdv = factor*nrmdv;
        end
        y0 = y0 + dy;
        yp0 = yp0 + dyp;
        res = odefun(t0,y0,yp0,odeArgs{:});
        resnrm = norm(res);

        % Test for convergence.  The norm of the residual must
        % be no greater than the initial guess and the norm of
        % the increments must be small in a relative sense.
        if (resnrm <= resnrm0) && (nrmdv <= 1e-3*rtol*nrmv)
            return;
        end
    end

    [dfdy,dfdyp,dfdy_options,dfdyp_options] = ...
        ode15ipdupdate(Jac,odefun,t0,y0,yp0,res,dfdy,dfdyp,...
        dfdy_options,dfdyp_options,odeArgs);

end

error(message('MATLAB:decic:ConvergenceFail'));
end

%---------------------------------------------------------------------------

function [d_rank,Qfunc,R,E,S] = getJacInfoForIter(dfdy,dfdyp,neq,free_y,free_yp)
% compute information that will be constant across chord iterations

% default since S is not defined for all branches
S = 0;

fixed = (neq - length(free_y)) + (neq - length(free_yp));

if isempty(free_y)  % Solve 0 = res + dfdyp*dyp
    [Qfunc, R, E, d_rank] = implicitQR(dfdyp);
    rankdef = neq - d_rank;
    if rankdef > 0
        if rankdef <= fixed
            error(message('MATLAB:decic:TooManyFixed',sprintf('%i',rankdef)));
        else
            error(message('MATLAB:decic:IndexGTOne'));
        end
    end
    return
end

if isempty(free_yp)  % Solve 0 = res + dfdy*dy
    [Qfunc, R, E, d_rank] = implicitQR(dfdy);
    rankdef = neq - d_rank;
    if rankdef > 0
        if rankdef <= fixed
            error(message('MATLAB:decic:TooManyFixed',sprintf('%i',rankdef)));
        else
            error(message('MATLAB:decic:IndexGTOne'));
        end
    end
    return
end

% Eliminate variables that are not free.
dfdy = dfdy(:,free_y);
dfdyp = dfdyp(:,free_yp);

[Qfunc, R, E, d_rank] = implicitQR(dfdyp);
if d_rank ~= neq
    S = Qfunc(dfdy);
    Srank = qrank(S(d_rank+1:end,:));
    rankdef = neq - (d_rank + Srank);
    if rankdef > 0
        if rankdef <= fixed
            error(message('MATLAB:decic:TooManyFixed',sprintf('%i',rankdef)));
        else
            error(message('MATLAB:decic:IndexGTOne'));
        end
    end
end
end

function [dy,dyp] = sls(res,neq,free_y,free_yp,rank,Qfunc,R,E,S)
% Solve the underdetermined system
%           0 = res + dfdyp*dyp + dfdy*dy
% A solution is obtained with as many components as
% possible of (transformed) dy and dyp set to zero.

dy = zeros(neq,1);
dyp = zeros(neq,1);

d = -Qfunc(res);

if isempty(free_y)  % Solve 0 = res + dfdyp*dyp
    dyp(E) = R \ d;
    return
end

if isempty(free_yp)  % Solve 0 = res + dfdy*dy   
    dy(E) = R \ d;
    return
end

if rank == neq
    dy(free_y) = 0;
    dyp(free_yp(E)) = R \ d;
else
    w = S(rank+1:end,:) \ d(rank+1:end);
    w1p = R(1:rank,1:rank) \ (d(1:rank) - S(1:rank,:) * w);
    dy(free_y) = w;
    nfree_yp = length(free_yp);
    dyp(free_yp(E)) = [w1p; zeros(nfree_yp-rank,1)];
end
end

%---------------------------------------------------------------------------

function rank = qrank(A)
% Get rank via QR factorization
if issparse(A)
    defaulttol = -2;
    R = matlab.internal.math.sparseQRnoQ(A, true, defaulttol, zeros(size(A, 1), 0));
else
    [~,R,~] = qr(A,"econ","vector"); % request permutation (nargout >= 3) so qrank is consistent
end
tol = max(size(A),[],2)*eps*abs(R(1,1));
rank = nnz(abs(diag(R)) > tol);  % Account for R that are neq x 1.
end

function [Qfunc, R, perm, sizeR] = implicitQR(A, sizeR)
% Compute the QR decomposition of A, and return a function handle that
% applies Q (which is much cheaper than explicitly storing Q for large and
% sparse A). Also computes sizeR, the number of non-zero columns in R.

if issparse(A)
    % Compute QR decomposition, and return Householder vectors and
    % coefficients to represent Q.
    [H, tau, pinv, R, perm] = matlab.internal.math.implicitSparseQR(A);
else
    [Q,R,perm] = qr(A,"vector");
end

% If sizeR was not defined yet, detect it from R
if nargin == 1
    % Explicitly check for singularity by finding the last nonzero on
    % the diagonal of R
    tol = max(size(A),[],2)*eps*abs(R(1,1)); 
    sizeR = find(abs(diag(R)) > tol,1,'last');
    if isempty(sizeR)
        % Occurs only when R is all zeros
        sizeR = 0;
    end
end

% Initialize function handle applying Q and Q' as needed.
if issparse(A)
    Qfunc = @(x) sparseQHandle(H, tau, pinv, x);
else
    Qfunc = @(x) matmulHandle(Q, x);
end

end

function y = sparseQHandle(H, tau, pinv, x)
% The built-in applies full mxm matrix Q. We need to pad with zeros or
% truncate to get the required dimensions.
% Applies Q(:, 1:sizeR)*x or Q(:, 1:sizeR)'*x, using Householder vectors
% representing Q
transp = true;
if isreal(H) && isreal(tau) && ~isreal(x)
    % Real Q applied to complex x not supported in built-in
    y = matlab.internal.math.applyHouseholder(H, tau, pinv, real(x), transp) + ...
        1i*matlab.internal.math.applyHouseholder(H, tau, pinv, imag(x), transp);
else
    y = matlab.internal.math.applyHouseholder(H, tau, pinv, x, transp);
end

end

function b = matmulHandle(A,X)
% matmul and return full
b = A'*X;
b = full(b); % otherwise, if A is a sparse vector, b is also sparse
end