function [neqn,nparam,nregions,atol,rtol,nmax,vectorized,printstats] = ...
        bvparguments(solver_name,odefun,bcfun,solinit,options,extras)
%BVPARGUMENTS  Helper function for processing arguments for BVP solvers.
%
%   See also BVP4C, BVP5C, BVPSET.

%   Copyright 2007-2022 The MathWorks, Inc.

% Handle extra arguments
if nargin < 6
    extras = {};
end

% Validate odefun and bcfun (and solver_name)
switch solver_name
case 'bvp5c'  % BVP5C requires function_handles
    if ~isa(odefun,'function_handle')
        error(message('MATLAB:bvparguments:ODEfunNotFunctionHandle', ...
            errIntro(solver_name, options, extras)));
    end
    if ~isa(bcfun,'function_handle')
        error(message('MATLAB:bvparguments:BCfunNotFunctionHandle', ...
            errIntro(solver_name, options, extras)));
    end
    ode = odefun;
    bc  = bcfun;
case 'bvp4c'
    % avoid fevals
    ode = fcnchk(odefun);
    bc  = fcnchk(bcfun);
otherwise
    error(message('MATLAB:bvparguments:SolverNameUnrecognized', solver_name));
end

% Validate initial guess
if ~isstruct(solinit)
    error(message('MATLAB:bvparguments:SolinitNotStruct', ...
        errIntro(solver_name, options, extras)));
elseif ~isfield(solinit,'x')
    error(message('MATLAB:bvparguments:NoXInSolinit', ...
        errIntro(solver_name, options, extras)));
elseif ~isfield(solinit,'y')
    error(message('MATLAB:bvparguments:NoYInSolinit', ...
        errIntro(solver_name, options, extras)));
end

if length(solinit.x) < 2
    error(message('MATLAB:bvparguments:SolinitXNotEnoughPts', ...
        errIntro(solver_name, options, extras)));
end

if ~issorted(solinit.x, 'monotonic')
    error (message('MATLAB:bvparguments:SolinitXNotMonotonic', ...
        errIntro(solver_name, options, extras)));
end

if isempty(solinit.y)
    error(message('MATLAB:bvparguments:SolinitYEmpty', ...
        errIntro(solver_name, options, extras)));
end

if size(solinit.y,2) ~= length(solinit.x)
    error(message('MATLAB:bvparguments:SolXSolYSizeMismatch', ...
        errIntro(solver_name, options, extras)));
end

% Determine problem size
neqn = size(solinit.y,1);
% - unknown parameters
if isfield(solinit,'parameters')
    nparam = numel(solinit.parameters);
else
    nparam = 0;
end
% - multi-point BVPs
interfacePoints = find(diff(solinit.x) == 0);
nregions = 1 + length(interfacePoints);

% Test the outputs of ODEFUN and BCFUN
if nparam > 0
    extras = [solinit.parameters(:), extras];
end
x1 = solinit.x(1);
y1 = solinit.y(:,1);
if nregions == 1
    odeExtras = extras;
    bcExtras = extras;
    ya = solinit.y(:,1);
    yb = solinit.y(:,end);
else
    odeExtras = [1, extras];  % region = 1
    bcExtras = extras;
    ya = solinit.y(:,[1, interfacePoints + 1]); % pass internal interfaces to BC
    yb = solinit.y(:,[interfacePoints,length(solinit.x)]);
end
testODE = ode(x1,y1,odeExtras{:});
testBC = bc(ya,yb,bcExtras{:});
if length(testODE) ~= neqn
    error(message('MATLAB:bvparguments:ODEfunOutputSize', ...
        errIntro(solver_name, options, extras), neqn));
end
if length(testBC) ~= (neqn*nregions + nparam)
    error(message('MATLAB:bvparguments:BCfunOutputSize', ...
        errIntro(solver_name, options, extras),neqn*nregions + nparam));
end

% BVP5C cannot concatenate row vectors with equations for unknown parameters
if solver_name == "bvp5c" && nparam > 0
    if ~iscolumn(testODE)
        error(message('MATLAB:bvparguments:ODEfunOutputSize', ...
            errIntro(solver_name, options, extras), neqn));
    end
    if ~iscolumn(testBC)
        error(message('MATLAB:bvparguments:BCfunOutputSize', ...
            errIntro(solver_name, options, extras), neqn*nregions + nparam));
    end
end

% Extract/validate BVPSET options:
% - tolerances
rtol = bvpget(options,'RelTol',1e-3);
if ~(isscalar(rtol) && (rtol > 0))
    error(message('MATLAB:bvparguments:RelTolNotPos', ...
        errIntro(solver_name, options, extras)));
end
if rtol < 100*eps
    rtol = 100*eps;
    warning(message('MATLAB:bvparguments:RelTolIncrease', ...
        warningIntro(solver_name, options, extras), sprintf('%g',rtol)));
end
atol = bvpget(options,'AbsTol',1e-6);
if isscalar(atol)
    atol = repmat(atol, neqn, 1);
else
    if length(atol) ~= neqn
        error(message('MATLAB:bvparguments:SizeAbsTol', ...
            errIntro(solver_name, options, extras), neqn));
    end
    atol = atol(:);
end
if any(atol<=0)
    error(message('MATLAB:bvparguments:AbsTolNotPos', ...
        errIntro(solver_name, options, extras)));
end

% - max number of meshpoints
nmax = bvpget(options,'Nmax',floor(10000/neqn));

% - vectorized
vectorized = bvpget(options,'Vectorized','off') == "on";

% 'vectorized' ODEFUN must return column vectors
if vectorized
    if ~iscolumn(testODE)
        error(message('MATLAB:bvparguments:ODEfunOutputSize', ...
            errIntro(solver_name, options, extras), neqn));
    end
end

% - printstats
printstats = bvpget(options,'Stats','off') == "on";

end  % bvparguments

%%%%%%%%%%%%%% local functions %%%%%%%%%%%%%%
function str = errIntro(solver_name, options, extras)
[solverNameUpper, optionalArgumentsStr] = genIntroMessage(solver_name, options, extras);
str = getString(message('MATLAB:bvparguments:ErrorCallingFun', ...
    solverNameUpper,optionalArgumentsStr));
end

function str = warningIntro(solver_name, options, extras)
[solverNameUpper, optionalArgumentsStr] = genIntroMessage(solver_name, options, extras);
str = getString(message('MATLAB:bvparguments:WarningCallingFun', ...
    solverNameUpper,optionalArgumentsStr));
end

function [nameStr, optStr] = genIntroMessage(solver_name, options, extras)
% error/warning introductory messages
nameStr = upper(solver_name);
if isempty(options)
    optStr = '';
else
    optStr = ',OPTIONS';
end
if ~isempty(extras)
    optStr = strcat(optStr,',P1,P2...');
end
end