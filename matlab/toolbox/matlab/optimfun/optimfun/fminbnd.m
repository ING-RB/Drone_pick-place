function [xf,fval,exitflag,output] = fminbnd(funfcn,ax,bx,options,varargin)
%FMINBND Single-variable bounded nonlinear function minimization.
%   X = FMINBND(FUN,x1,x2) attempts to find  a local minimizer X of the function 
%   FUN in the interval x1 < X < x2.  FUN is a function handle.  FUN accepts 
%   scalar input X and returns a scalar function value F evaluated at X.
%
%   X = FMINBND(FUN,x1,x2,OPTIONS) minimizes with the default optimization
%   parameters replaced by values in the structure OPTIONS, created with
%   the OPTIMSET function. See OPTIMSET for details. FMINBND uses these
%   options: Display, TolX, MaxFunEval, MaxIter, FunValCheck, PlotFcns, 
%   and OutputFcn.
%
%   X = FMINBND(PROBLEM) finds the minimum for PROBLEM. PROBLEM is a
%   structure with the function FUN in PROBLEM.objective, the interval
%   in PROBLEM.x1 and PROBLEM.x2, the options structure in PROBLEM.options,
%   and solver name 'fminbnd' in PROBLEM.solver. 
%
%   [X,FVAL] = FMINBND(...) also returns the value of the objective function,
%   FVAL, computed in FUN, at X.
%
%   [X,FVAL,EXITFLAG] = FMINBND(...) also returns an EXITFLAG that
%   describes the exit condition. Possible values of EXITFLAG and the
%   corresponding exit conditions are
%
%    1  FMINBND converged with a solution X based on OPTIONS.TolX.
%    0  Maximum number of function evaluations or iterations reached.
%   -1  Algorithm terminated by the output function.
%   -2  Bounds are inconsistent (that is, ax > bx).
%
%   [X,FVAL,EXITFLAG,OUTPUT] = FMINBND(...) also returns a structure
%   OUTPUT with the number of iterations taken in OUTPUT.iterations, the
%   number of function evaluations in OUTPUT.funcCount, the algorithm name 
%   in OUTPUT.algorithm, and the exit message in OUTPUT.message.
%
%   Examples
%     FUN can be specified using @:
%        X = fminbnd(@cos,3,4)
%      computes pi to a few decimal places and gives a message upon termination.
%        [X,FVAL,EXITFLAG] = fminbnd(@cos,3,4,optimset('TolX',1e-12,'Display','off'))
%      computes pi to about 12 decimal places, suppresses output, returns the
%      function value at x, and returns an EXITFLAG of 1.
%
%     FUN can be an anonymous function:
%        X = fminbnd(@(x) sin(x)+3,2,5)
%
%     FUN can be a parameterized function.  Use an anonymous function to
%     capture the problem-dependent parameters:
%        f = @(x,c) (x-c).^2;  % The parameterized function.
%        c = 1.5;              % The parameter.
%        X = fminbnd(@(x) f(x,c),0,1)
%
%   See also OPTIMSET, FMINSEARCH, FZERO, FUNCTION_HANDLE.

%   References:
%   "Algorithms for Minimization Without Derivatives",
%   R. P. Brent, Prentice-Hall, 1973, Dover, 2002.
%
%   "Computer Methods for Mathematical Computations",
%   Forsythe, Malcolm, and Moler, Prentice-Hall, 1976.

%   Original coding by Duane Hanselman, University of Maine.
%   Copyright 1984-2023 The MathWorks, Inc.

% If just 'defaults' passed in, return the default options in X
if nargin==1 && nargout <= 1 && strcmpi(funfcn,'defaults')
    xf = getDefaultOpt();
    return
end

% initialization
allOptionsDefault = nargin < 4 || isempty(options);
buildOutputStruct = nargout > 3;

% Detect problem structure input
problemInput = false;
if nargin == 1
    if isstruct(funfcn) 
        problemInput = true;
        [funfcn,ax,bx,options] = matlab.internal.optimfun.utils.separateOptimStruct(funfcn);
        allOptionsDefault = isempty(options);
    else % Single input and non-structure.
        error('MATLAB:fminbnd:InputArg',...
            getString(message('MATLAB:optimfun:fminbnd:InputArg')));
    end
end

if nargin < 3 && ~problemInput
    error('MATLAB:fminbnd:NotEnoughInputs',...
        getString(message('MATLAB:optimfun:fminbnd:NotEnoughInputs')));
end

% Check for non-double, non-scalar, or non-finite bounds
isBoundValidFcn = @(x) isa(x, 'double') && isscalar(x) && isfinite(x);
if ~(isBoundValidFcn(ax) && isBoundValidFcn(bx))
    error('MATLAB:fminbnd:InvalidBoundInput',...
        getString(message('MATLAB:optimfun:fminbnd:InvalidBoundInput')));
end

if allOptionsDefault
    print = 1; % 'notify' Display
    tol = 1e-4;
    funValCheck = false;
    maxfun = 500;
    maxiter = 500;
    havecallback = false;
else
    defaultopt = getDefaultOpt();
    optimgetFlag = 'fast';
    % Check that options is a struct
    if ~isempty(options) && ~isstruct(options)
        error('MATLAB:fminbnd:ArgNotStruct',...
            getString(message('MATLAB:optimfun:commonMessages:ArgNotStruct', 4)));
    end

    printtype = optimget(options,'Display',defaultopt,optimgetFlag);
    tol = optimget(options,'TolX',defaultopt,optimgetFlag);
    funValCheck = strcmp(optimget(options,'FunValCheck',defaultopt,optimgetFlag),'on');

    maxfun = optimget(options,'MaxFunEvals',defaultopt,optimgetFlag);
    maxiter = optimget(options,'MaxIter',defaultopt,optimgetFlag);

    % Check that MaxFunEvals and MaxIter are scalar double values;
    % Their default values for some solvers are strings
    if ischar(maxfun) || isstring(maxfun)
        error('MATLAB:fminbnd:CharMaxFunEvals',...
            getString(message('MATLAB:optimfun:fminbnd:CharMaxFunEvals')));
    end
    if ischar(maxiter) || isstring(maxiter)
        error('MATLAB:fminbnd:CharMaxIter',...
            getString(message('MATLAB:optimfun:fminbnd:CharMaxIter')));
    end

    % Setup ObjectiveSenseManager internal option
    createOuputFcnWrapper = true;
    options = optim.internal.utils.ObjectiveSenseManager.setup(options,createOuputFcnWrapper);

    switch printtype
        case {'notify','notify-detailed'}
            print = 1;
        case {'none','off'}
            print = 0;
        case {'iter','iter-detailed'}
            print = 3;
        case {'final','final-detailed'}
            print = 2;
        otherwise
            print = 1;
    end
    
    % Handle the output
    outputfcn = optimget(options,'OutputFcn',defaultopt,optimgetFlag);
    if isempty(outputfcn)
        haveoutputfcn = false;
    else
        haveoutputfcn = true;
        % Parse OutputFcn which is needed to support cell array syntax for OutputFcn.
        outputfcn = matlab.internal.optimfun.utils.createCellArrayOfFunctions(outputfcn,'OutputFcn');
    end
    % Handle the plot
    plotfcns = optimget(options,'PlotFcns',defaultopt,optimgetFlag);
    if isempty(plotfcns)
        haveplotfcn = false;
    else
        haveplotfcn = true;
        % Parse PlotFcns which is needed to support cell array syntax for PlotFcns.
        plotfcns = matlab.internal.optimfun.utils.createCellArrayOfFunctions(plotfcns,'PlotFcns');
    end
    havecallback = haveoutputfcn || haveplotfcn;
end

% Initialize parameters
funccount = 0;
iter = 0;
xf = [];
fx = [];

% checkbounds
if ax > bx
    exitflag = -2;
    xf=[]; fval = [];
    if buildOutputStruct || print > 0
        msg=getString(message('MATLAB:optimfun:fminbnd:ExitingLowerBoundExceedsUpperBound'));
        if print > 0
            disp(' ')
            disp(msg)
        end
        output.iterations = 0;
        output.funcCount = 0;
        output.algorithm = 'golden section search, parabolic interpolation';
        output.message = msg;
    end
    % Have not initialized OutputFcn; do not need to call it before returning
    return
end

% Assume we'll converge
exitflag = 1;

header = ' Func-count     x          f(x)         Procedure';
procedure='       initial';

% Convert to function handle as needed.
if ~isa(funfcn,'function_handle')
    % Convert to function handle as needed.
    funfcn = fcnchk(funfcn,length(varargin)); %#ok<DFCNCHK> 
end

if funValCheck
    % Add a wrapper function to check for NaN/complex values. Syntax should
    % support calls that look like this: f = funfcn(x,varargin{:});
    funfcn = @(x, varargin) matlab.internal.optimfun.utils.checkfun(x, funfcn, "fminbnd", varargin{:});
end

% Initialize the output and plot functions.
if havecallback
    [xOutputfcn, optimValues, stop] = callOutputAndPlotFcns(outputfcn,plotfcns,xf,'init',funccount,iter, ...
        fx,procedure,varargin{:});
    if stop
        [xf,fval,exitflag,output] = cleanUpInterrupt(xOutputfcn,optimValues);
        if  print > 0
            disp(output.message)
        end
        return;
    end
end

% Compute the start point
seps = sqrt(eps);
c = 0.5*(3.0 - sqrt(5.0));
a = ax;
b = bx;
v = a + c*(b-a);
w = v;
xf = v;
d = 0.0;
e = 0.0;
x= xf;
fx = funfcn(x,varargin{:});
funccount = funccount + 1;

% Check that the objective value is a scalar
if numel(fx) ~= 1
   error('MATLAB:fminbnd:NonScalarObj',...
    getString(message('MATLAB:optimfun:fminbnd:NonScalarObj')));
end
if ~isUnderlyingType(fx,'float')
    error(message('MATLAB:optimfun:commonMessages:ObjMustBeFloat'));
end

% Display the start point if required
if print > 2
    disp(' ')
    disp(header)
    fvalDisplay = options.ObjectiveSenseManager.updateFval(fx);
    fprintf('%5.0f   %12.6g %12.6g %s\n',funccount,xf,fvalDisplay,procedure)
end

% OutputFcn and PlotFcns call
% Last x passed to outputfcn/plotfcns; has the input x's shape
if havecallback
    [xOutputfcn, optimValues, stop] = callOutputAndPlotFcns(outputfcn,plotfcns,xf,'iter',funccount,iter, ...
        fx,procedure,varargin{:});
    if stop  % Stop per user request.
        [xf,fval,exitflag,output] = cleanUpInterrupt(xOutputfcn,optimValues);
        if  print > 0
            disp(output.message)
        end
        return;
    end
end

fv = fx;
fw = fx;
xm = 0.5*(a+b);
tol1 = seps*abs(xf) + tol/3.0;
tol2 = 2.0*tol1;

% Main loop
while ( abs(xf-xm) > (tol2 - 0.5*(b-a)) )
    gs = 1;
    % Is a parabolic fit possible
    if abs(e) > tol1
        % Yes, so fit parabola
        gs = 0;
        r = (xf-w)*(fx-fv);
        q = (xf-v)*(fx-fw);
        p = (xf-v)*q-(xf-w)*r;
        q = 2.0*(q-r);
        if q > 0.0
            p = -p;
        end
        q = abs(q);
        r = e;
        e = d;

        % Is the parabola acceptable
        if ( (abs(p)<abs(0.5*q*r)) && (p>q*(a-xf)) && (p<q*(b-xf)) )

            % Yes, parabolic interpolation step
            d = p/q;
            x = xf+d;
            procedure = '       parabolic';

            % f must not be evaluated too close to ax or bx
            if ((x-a) < tol2) || ((b-x) < tol2)
                si = sign(xm-xf) + ((xm-xf) == 0);
                d = tol1*si;
            end
        else
            % Not acceptable, must do a golden section step
            gs=1;
        end
    end
    if gs
        % A golden-section step is required
        if xf >= xm
            e = a-xf;
        else
            e = b-xf;
        end
        d = c*e;
        procedure = '       golden';
    end

    % The function must not be evaluated too close to xf
    si = sign(d) + (d == 0);
    x = xf + si * max( abs(d), tol1 );
    fu = funfcn(x,varargin{:});
    funccount = funccount + 1;

    iter = iter + 1;
    if print > 2
        fvalDisplay = options.ObjectiveSenseManager.updateFval(fu);
        fprintf('%5.0f   %12.6g %12.6g %s\n',funccount, x, fvalDisplay, procedure);
    end
    % OutputFcn and PlotFcns call
    if havecallback
        [xOutputfcn, optimValues, stop] = callOutputAndPlotFcns(outputfcn,plotfcns,x,'iter',funccount,iter, ...
            fu,procedure,varargin{:});
        if stop  % Stop per user request.
            [xf,fval,exitflag,output] = cleanUpInterrupt(xOutputfcn,optimValues);
            if  print > 0
                disp(output.message);
            end
            return;
        end
    end

    % Update a, b, v, w, x, xm, tol1, tol2
    if fu <= fx
        if x >= xf
            a = xf;
        else
            b = xf;
        end
        v = w;
        fv = fw;
        w = xf;
        fw = fx;
        xf = x;
        fx = fu;
    else % fu > fx
        if x < xf
            a = x;
        else
            b = x;
        end
        if ( (fu <= fw) || (w == xf) )
            v = w;
            fv = fw;
            w = x;
            fw = fu;
        elseif ( (fu <= fv) || (v == xf) || (v == w) )
            v = x;
            fv = fu;
        end
    end
    xm = 0.5*(a+b);
    tol1 = seps*abs(xf) + tol/3.0; tol2 = 2.0*tol1;

    if funccount >= maxfun || iter >= maxiter
        exitflag = 0;
        break
    end
end % while

fval = fx;
if buildOutputStruct || print > 0
    output.iterations = iter;
    output.funcCount = funccount;
    output.algorithm = 'golden section search, parabolic interpolation';
    msg = terminate(xf,exitflag,fval,funccount,maxfun,iter,maxiter,tol,print);
    output.message = msg;
end
% OutputFcn and PlotFcns call
if havecallback
    callOutputAndPlotFcns(outputfcn,plotfcns,xf,'done',funccount,iter,fval,procedure,varargin{:});
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function msg = terminate(~,exitflag,finalf,funccount,maxfun,~,~,tol,print)

switch exitflag
    case 1
        msg = ...
            getString(message('MATLAB:optimfun:fminbnd:OptimizationTerminatedXSatisfiesCriteria', sprintf('%e',tol)));
        print = print > 1; % Convert to logical; only print msg if not 'off' or 'notify'
    case 0
        print = print > 0; % Convert to logical
        if funccount >= maxfun
            msg = getString(message('MATLAB:optimfun:fminbnd:ExitingMaxFunctionEvals', sprintf('%f',finalf)));
        else
            msg = getString(message('MATLAB:optimfun:fminbnd:ExitingMaxIterations', sprintf('%f',finalf)));
        end
end
if print
    disp(' ')
    disp(msg)
end
%--------------------------------------------------------------------------
function [xOutputfcn, optimValues, stop] = callOutputAndPlotFcns(outputfcn,plotfcns,x,state,funccount,iter,  ...
    f,procedure,varargin)
% CALLOUTPUTANDPLOTFCNS assigns values to the struct OptimValues and then calls the
% outputfcn/plotfcns.  outputfcn and plotfcns are assumed to not be string
% objects but can be strings or handles.
%
% state - can have the values 'init','iter', or 'done'.

% For the 'done' state we do not check the value of 'stop' because the
% optimization is already done.
optimValues.funccount = funccount;
optimValues.iteration = iter;
optimValues.fval = f;
optimValues.procedure = procedure;

xOutputfcn = x;  % Set xOutputfcn to be x
stop = false;
state = char(state); % in case string objects are ever passed in the future
% Call output functions
if ~isempty(outputfcn)
    switch state
        case {'iter','init'}
            stop = matlab.internal.optimfun.utils.callAllOptimOutputFcns(outputfcn,xOutputfcn,optimValues,state,varargin{:}) || stop;
        case 'done'
            matlab.internal.optimfun.utils.callAllOptimOutputFcns(outputfcn,xOutputfcn,optimValues,state,varargin{:});
    end
end
% Call plot functions
if ~isempty(plotfcns)
    switch state
        case {'iter','init'}
            stop = matlab.internal.optimfun.utils.callAllOptimPlotFcns(plotfcns,xOutputfcn,optimValues,state,varargin{:}) || stop;
        case 'done'
            matlab.internal.optimfun.utils.callAllOptimPlotFcns(plotfcns,xOutputfcn,optimValues,state,varargin{:});

    end
end

%--------------------------------------------------------------------------
function [x,FVAL,EXITFLAG,OUTPUT] = cleanUpInterrupt(xOutputfcn,optimValues)
% CLEANUPINTERRUPT updates or sets all the output arguments of FMINBND when the optimization
% is interrupted.

% Call plot function driver to finalize the plot function figure window. If
% no plot functions have been specified or the plot function figure no
% longer exists, this call just returns.
matlab.internal.optimfun.utils.callAllOptimPlotFcns('cleanuponstopsignal');

x = xOutputfcn;
FVAL = optimValues.fval;
EXITFLAG = -1;
OUTPUT.iterations = optimValues.iteration;
OUTPUT.funcCount = optimValues.funccount;
OUTPUT.algorithm = 'golden section search, parabolic interpolation';
OUTPUT.message = getString(message('MATLAB:optimfun:fminbnd:OptimizationTerminatedPrematurelyByUser'));

%--------------------------------------------------------------------------
function defaultopt = getDefaultOpt()
    defaultopt = struct( ...
    'Display','notify', ...
    'FunValCheck','off', ...
    'MaxFunEvals',500, ...
    'MaxIter',500, ...
    'OutputFcn',[], ...
    'PlotFcns',[], ...
    'TolX',1e-4);
