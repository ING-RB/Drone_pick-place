function [neq,tspan,ntspan,next,t0,tfinal,tdir,y0,f0,args, ...
    options,threshold,rtol,normcontrol,normy,hmin,hmax,htry,htspan, ...
    dataType ] =   ...
    odearguments(odeIsFuncHandle,odeTreatAsMFile,solver,ode,tspan,y0,options,extras)
%ODEARGUMENTS  Helper function that processes arguments for all ODE solvers.
%
%   See also ODE113, ODE15I, ODE15S, ODE23, ODE23S, ODE23T, ODE23TB, ODE45.

%   Mike Karr, Jacek Kierzenka
%   Copyright 1984-2024 The MathWorks, Inc.

if solver == "ode15i"
    odeIsFuncHandle = true;   % no MATLAB v. 5 legacy for ODE15I
end

if odeIsFuncHandle  % function handles used
    if isempty(tspan) || isempty(y0)
        error(message('MATLAB:odearguments:TspanOrY0NotSupplied',solver));
    end
    if length(tspan) < 2
        error(message('MATLAB:odearguments:SizeTspan',solver));
    end
    t0 = tspan(1);
    htspan = abs(tspan(2) - t0);
    tspan = tspan(:);
    ntspan = length(tspan);
    next = 2;       % next entry in tspan
    tfinal = tspan(end);
    args = extras;                 % use f(t,y,p1,p2...)
else  % ode-file used   (ignored when solver == ODE15I)
    % Get default tspan and y0 from the function if none are specified.
    if isempty(tspan) || isempty(y0)
        if odeTreatAsMFile && (nargout(ode) < 3 && nargout(ode) ~= -1)
            error(message('MATLAB:odearguments:NoDefaultParams', ...
                funstring(ode),solver,funstring(ode)));
        end
        [def_tspan,def_y0,def_options] = ode([],[],'init',extras{:});
        if isempty(tspan)
            tspan = def_tspan;
        end
        if isempty(y0)
            y0 = def_y0;
        end
        options = odeset(def_options,options);
    end
    tspan = tspan(:);
    ntspan = length(tspan);
    if ntspan == 1    % Integrate from 0 to tspan
        t0 = 0;
        next = 1;       % Next entry in tspan.
    else
        t0 = tspan(1);
        next = 2;       % next entry in tspan
    end
    htspan = abs(tspan(next) - t0);
    tfinal = tspan(end);

    % The input arguments of f determine the args to use to evaluate f.
    if odeTreatAsMFile
        if (nargin(ode) == 2)
            args = {};                   % f(t,y)
        else
            args = [{''} extras];        % f(t,y,'',p1,p2...)
        end
    else  % MEX-files, etc.
        try
            args = [{''} extras];        % try f(t,y,'',p1,p2...)
            ode(tspan(1),y0(:),args{:});
        catch
            args = {};                   % use f(t,y) only
        end
    end
end

y0 = y0(:);
neq = length(y0);

% Test that tspan is internally consistent.
if anynan(tspan)
    error(message('MATLAB:odearguments:TspanNaNValues'));
end

if t0 == tfinal
    error(message('MATLAB:odearguments:TspanEndpointsNotDistinct'));
end

tdir = sign(tfinal - t0);
if ~issorted(tspan, 'monotonic')
    error(message('MATLAB:odearguments:TspanNotMonotonic'));
end

% ODE15I sets args{1} to yp0.
f0 = ode(t0,y0,args{:});
if ~iscolumn(f0)
    error(message('MATLAB:odearguments:FoMustReturnCol',funstring(ode)));
end
if size(f0,1) ~= neq
    error(message('MATLAB:odearguments:SizeIC',funstring(ode),size(f0,1),neq,funstring(ode)));
end

% Determine the dominant data type
classT0 = class(t0);
classY0 = class(y0);
classF0 = class(f0);
if solver == "ode15i"
    classYP0 = class(args{1});  % ODE15I sets args{1} to yp0.
    dataType = superiorfloat(t0,y0,args{1},f0);
    if ~(strcmp(classT0,dataType) && strcmp(classY0,dataType) && ...
            strcmp(classF0,dataType) && strcmp(classYP0,dataType))
        input1 = '''t0'', ''y0'', ''yp0''';
        input2 = '''f(t0,y0,yp0)''';
        warning(message('MATLAB:odearguments:InconsistentDataType',input1,input2,solver));
    end
else
    dataType = superiorfloat(t0,y0,f0);
    if ~(strcmp(classT0,dataType) && strcmp(classY0,dataType) && ...
            strcmp(classF0,dataType))
        input1 = '''t0'', ''y0''';
        input2 = '''f(t0,y0)''';
        warning(message('MATLAB:odearguments:InconsistentDataType',input1,input2,solver));
    end
end

% Get the error control options, and set defaults.
rtol = odeget(options,'RelTol',1e-3);
if ~isscalar(rtol) || rtol <= 0
    error(message('MATLAB:odearguments:RelTolNotPosScalar'));
end

epsTol = eps(dataType);
if rtol < 100 * epsTol
    rtol = 100 * epsTol;
    warning(message('MATLAB:odearguments:RelTolIncrease',sprintf('%g',rtol)))
end

atol = odeget(options,'AbsTol',1e-6);
if any(atol <= 0)
    error(message('MATLAB:odearguments:AbsTolNotPos'));
end

normcontrol = odeget(options,'NormControl','off') == "on";
if normcontrol
    if ~isscalar(atol)
        error(message('MATLAB:odearguments:NonScalarAbsTol'));
    end
    normy = norm(y0);
else
    if ~isscalar(atol) && length(atol) ~= neq
        error(message('MATLAB:odearguments:SizeAbsTolInconsistent'));
    end
    atol = atol(:);
    normy = [];
end
threshold = atol ./ rtol;

% Analyze MinStep and MaxStep inputs

% For *finite* intervals, safehmax can be interpreted as a "tiny" step.
safehmax = 16.0*epsTol*max(abs(t0),abs(tfinal));  % 'inf' for tfinal = inf
tlen = abs(tfinal-t0);
hmax = odeget(options,'MaxStep');
useDefaultHMax = isempty(hmax);

if useDefaultHMax 
    % By default, hmax is 1/10th of the interval.
    hmax = max(0.1*tlen,safehmax);
else
    if hmax <= 0
        error(message('MATLAB:odearguments:MaxStepLEzero'));
    end
    % hmax should not be longer than the interval.
    hmax = min(tlen,hmax);
end

hmin = odeget(options,'MinStep');

if isempty(hmin)
    % The solver can always ignore hmin = 0.
    hmin = 0;
else
    if hmin <= 0
        error(message('MATLAB:odearguments:MinStepLEzero'));
    end
    % hmin should not be longer than the interval.
    hmin = min(tlen,hmin);
    if useDefaultHMax
        % Generally hmax will be 1/10th of the interval here. Make sure
        % that's not smaller than hmin.
        hmax = max(hmin,hmax);
    else
        % When both MinStep and MaxStep are supplied by the user, ensure
        % that MaxStep >= MinStep.
        if hmax < hmin
            error(message('MATLAB:odearguments:InconsistentMinStep'));
        end
    end
end

htry = abs(odeget(options,'InitialStep',[]));
if isempty(htry)
    if hmax == hmin
        % Fixed size integration.
        htry = hmin;
    end
elseif htry <= 0
    error(message('MATLAB:odearguments:InitialStepLEzero'));
end
