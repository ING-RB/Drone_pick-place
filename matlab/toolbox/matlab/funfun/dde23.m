function sol = dde23(ddefun,lags,history,tspan,options,varargin) 
%DDE23  Solve delay differential equations (DDEs) with constant delays.
%   SOL = DDE23(DDEFUN,LAGS,HISTORY,TSPAN) integrates a system of DDEs 
%   y'(t) = f(t,y(t),y(t - tau_1),...,y(t - tau_k)). The constant, positive 
%   delays tau_1,...,tau_k are input as the vector LAGS. DDEFUN is a function 
%   handle. DDEFUN(T,Y,Z) must return a column vector corresponding to 
%   f(t,y(t),y(t - tau_1),...,y(t - tau_k)). In the call to DDEFUN, a scalar T 
%   is the current t, a column vector Y approximates y(t), and a column Z(:,j) 
%   approximates y(t - tau_j) for delay tau_j = LAGS(J).  The DDEs are 
%   integrated from T0=TSPAN(1) to TF=TSPAN(end) where T0 < TF. The solution 
%   at t <= T0 is specified by HISTORY in one of three ways: HISTORY can be 
%   a function handle, where for a scalar T, HISTORY(T) returns a column 
%   vector y(t). If y(t) is constant, HISTORY can be this column vector. 
%   If this call to DDE23 continues a previous integration to T0, HISTORY 
%   can be the solution SOL from that call.
%
%   DDE23 produces a solution that is continuous on [T0,TF]. The solution is
%   evaluated at points TINT using the output SOL of DDE23 and the function
%   DEVAL: YINT = DEVAL(SOL,TINT). The output SOL is a structure with 
%       SOL.x  -- mesh selected by DDE23
%       SOL.y  -- approximation to y(t) at the mesh points of SOL.x
%       SOL.yp -- approximation to y'(t) at the mesh points of SOL.x
%       SOL.solver -- 'dde23'
%
%   SOL = DDE23(DDEFUN,LAGS,HISTORY,TSPAN,OPTIONS) solves as above with default
%   parameters replaced by values in OPTIONS, a structure created with the
%   DDESET function. See DDESET for details. Commonly used options are
%   scalar relative error tolerance 'RelTol' (1e-3 by default) and vector of
%   absolute error tolerances 'AbsTol' (all components 1e-6 by default).
%
%   DDE23 can solve problems with discontinuities in the solution prior to T0
%   (the history) or discontinuities in coefficients of the equations at known
%   values of t after T0 if the locations of these discontinuities are
%   provided in a vector as the value of the 'Jumps' option.
%
%   By default the initial value of the solution is the value returned by
%   HISTORY at T0. A different initial value can be supplied as the value of
%   the 'InitialY' property. 
%
%   With the 'Events' property in OPTIONS set to a function handle EVENTS, 
%   DDE23 solves as above while also finding where event functions 
%   g(t,y(t),y(t - tau_1),...,y(t - tau_k)) are zero. For each function 
%   you specify whether the integration is to terminate at a zero and whether 
%   the direction of the zero crossing matters. These are the three column 
%   vectors returned by EVENTS: [VALUE,ISTERMINAL,DIRECTION] = EVENTS(T,Y,Z). 
%   For the I-th event function: VALUE(I) is the value of the function, 
%   ISTERMINAL(I) = 1 if the integration is to terminate at a zero of this 
%   event function and 0 otherwise. DIRECTION(I) = 0 if all zeros are to
%   be computed (the default), +1 if only zeros where the event function is
%   increasing, and -1 if only zeros where the event function is decreasing. 
%   The field SOL.xe is a row vector of times at which events occur. Columns
%   of SOL.ye are the corresponding solutions, and indices in vector SOL.ie
%   specify which event occurred.   
%   
%   Example    
%         sol = dde23(@ddex1de,[1, 0.2],@ddex1hist,[0, 5]);
%     solves a DDE on the interval [0, 5] with lags 1 and 0.2 and delay
%     differential equations computed by the function ddex1de. The history 
%     is evaluated for t <= 0 by the function ddex1hist. The solution is
%     evaluated at 100 equally spaced points in [0 5]  
%         tint = linspace(0,5);
%         yint = deval(sol,tint);
%     and plotted with 
%         plot(tint,yint);
%     DDEX1 shows how this problem can be coded using subfunctions. For
%     another example see DDEX2.  
%
%   Class support for inputs TSPAN, LAGS, HISTORY, and the result of DDEFUN(T,Y,Z):
%     float: double, single
%
%   See also DDESET, DDEGET, DEVAL.

%   DDE23 tracks discontinuities and integrates with the explicit Runge-Kutta
%   (2,3) pair and interpolant of ODE23. It uses iteration to take steps
%   longer than the lags.

%   Details are to be found in Solving DDEs in MATLAB, L.F. Shampine and
%   S. Thompson, Applied Numerical Mathematics, 37 (2001). 

%   Jacek Kierzenka, Lawrence F. Shampine and Skip Thompson
%   Copyright 1984-2024 The MathWorks, Inc.

import matlab.ode.internal.dde.lagvals;
solver_name = 'dde23';

if nargin < 5
    options = [];
end

% Stats
nsteps   = 0;
nfailed  = 0;
nfevals  = 0;

if issparse(tspan)
    tspan = full(tspan);
end
t0 = tspan(1);
tfinal = tspan(end);   % Ignore all entries of tspan except first and last.
if tfinal <= t0
    error(message('MATLAB:dde23:TspandEndLTtspan1'))
end

% package function handles
[ddefun, odeIsFuncHandle, ~] = packageAsFuncHandle(ddefun);
if isa(history,'char') || isa(history,'string')
    history = str2func(history);
end

% Output
output_sol = odeIsFuncHandle && nargout == 1; % sol = odeXX(...)
output_ty = isstruct(options) && ...
    isfield(options,"OutputTY") && options.OutputTY; % options signals output type, this will change what's in the struct
output_sol = output_sol && ~output_ty; % turn off output_sol if keeping ty

% turn off expected deval warning
ws = warning('off','MATLAB:deval:NonuniqueSolution');
cleanObj = onCleanup(@() warning(ws));

if isnumeric(history)
    temp = history;
elseif isstruct(history)
    if history.x(end) ~= t0
        error(message('MATLAB:dde23:NotContinueFromHistoryEnd'))
    end
    temp = history.y(:,end);
else
    temp = history(t0,varargin{:});
end
sol.solver = solver_name;
if isstruct(history) % sol struct was passed in
    sol.history = history.history;
else
    sol.history = history;
end
y0 = temp(:);
maxlevel = 4;
initialy = ddeget(options,'InitialY',[]);
if ~isempty(initialy)
    y0 = initialy(:);
    maxlevel = 5;
end

neq = length(y0);

% If solving a DDE, locate potential discontinuities. We need to step to each of
% the points of potential lack of smoothness. Because we start at t0, we can
% remove it from discont.  The solver always steps to tfinal, so it is
% convenient to add it to discont.
if isempty(lags)
    discont = tfinal;
    minlag = Inf;
else
    lags = lags(:)';
    minlag = min(lags);
    if minlag <= 0
        error(message('MATLAB:dde23:NotPosLags'))
    end
    vl = t0;
    maxlag = max(lags);
    if isstruct(history)
        indices = find( history.discont < (t0 - maxlag) );
        if ~isempty(indices)
            ndex = indices(end);
            sol.discont = history.discont(1:ndex);
            vl = [history.discont(ndex+1:end) t0];
        end
    end
    jumps = ddeget(options,'Jumps',[]);
    if ~isempty(jumps)
        indices = find( ((t0 - maxlag) <= jumps) & (jumps <= tfinal) );
        if ~isempty(indices)
            jumps = jumps(indices);
            vl = sort([vl jumps(:)']);
            maxlevel = 5;
        end
    end
    discont = vl;
    try
        for level = 2:maxlevel
            % use implicit expansion to combine vl and lags
            vlp1 = vl' + sort(lags);
            vl = vlp1(vlp1 <= tfinal);
            vl = vl(:)';
            if isempty(vl)
                break;
            end
            if numel(vl) > 1 % Purge duplicates in vl.
                vl = sort(vl);
                indices = find(abs(diff(vl)) <= 10*eps(vl(1:end-1))) + 1;
                vl(indices) = [];
            end
            discont = [discont vl]; %#ok<AGROW>
        end
        if numel(discont) > 1
            discont = sort(discont); % Purge duplicates.
            indices = find(abs(diff(discont)) <= 10*eps(discont(1:end-1))) + 1;
            discont(indices) = [];
        end
    catch ME
        if (ME.identifier == "MATLAB:array:SizeLimitExceeded")
            error(message('MATLAB:dde23:LargeDelaysTryDDESD'))
        else
            % effective CC here because this is rethrowing unknown exception
            rethrow(ME);
        end
    end
end
if isstruct(history)
    sol.discont = [history.discont discont];
else
    sol.discont = discont;
end

% Add tfinal to the list of discontinuities if it is not already included.  This
% is a programming convenience and is not added to sol.discont.
if abs(tfinal - discont(end)) <= 10*eps(tfinal)
    discont(end) = tfinal;
else
    discont = [discont tfinal];
end

% Discard t0 and discontinuities in the history.
indices = discont <= t0;
discont(indices) = [];
nextdsc = 1;

% Initialize method parameters.
pow = 1/3;
B = [
    1/2         0               2/9
    0           3/4             1/3
    0           0               4/9
    0           0               0
    ];
E = [-5/72; 1/12; 1/9; -1/8];

% Evaluate initial history at t0 - lags.
Z0 = lagvals(t0,[],lags,history,t0,y0,[],varargin{:});

f0 = ddefun(t0,y0,Z0,varargin{:});
nfevals = nfevals + 1;
[m,n] = size(f0);
if n > 1
    error(message('MATLAB:dde23:DDEOutputNotCol'));
elseif m ~= neq
    error(message('MATLAB:dde23:DDELengthMismatchHistory'));
end

% Determine the dominant data type
classT0 = class(t0);
classY0 = class(y0);
classZ0 = class(Z0);   % class y(t0-lags)
classF0 = class(f0);
dataType = superiorfloat(t0,y0,Z0,f0);
if ~( strcmp(classT0,dataType) && strcmp(classY0,dataType) && ...
        strcmp(classZ0,dataType) && strcmp(classF0,dataType))
    warning(message('MATLAB:dde23:InconsistentDataType'));
end
% create prototype
protoType = ones(dataType);

% Get options, and set defaults.
rtol = ddeget(options,'RelTol',1e-3);
if (length(rtol) ~= 1) || (rtol <= 0)
    error(message('MATLAB:dde23:OptRelTolNotPosScalar'));
end
if rtol < 100 * eps("like", protoType)
    rtol = 100 * eps("like", protoType);
    warning(message('MATLAB:dde23:RelTolIncrease', sprintf( '%g', rtol )))
end

atol = ddeget(options,'AbsTol',1e-6);
if any(atol <= 0)
    error(message('MATLAB:dde23:OptAbsTolNotPos'));
end

normcontrol = strcmp(ddeget(options,'NormControl','off'),'on');

if normcontrol
    if length(atol) ~= 1
        error(message('MATLAB:dde23:NonScalarAbstolNormControl'));
    end
    normy = norm(y0);
else
    if (length(atol) ~= 1) && (length(atol) ~= neq)
        error(message('MATLAB:dde23:AbsTolSize', funstring( ddefun ), neq));
    end
    atol = atol(:);
end
threshold = atol / rtol;

% By default, hmax is 1/10 of the interval of integration.
tlen = tfinal - t0;
hmax = ddeget(options,'MaxStep');
if isempty(hmax)
    useDefaultHMax = true;
    hmax = 0.1*(tlen);
else
    useDefaultHMax = false;
end
hmax = min(tlen, hmax);
if hmax <= 0
    error(message('MATLAB:dde23:OptMaxStepNotPos'));
end

userhmin = odeget(options,'MinStep'); % note this is odeget
if isempty(userhmin)
    % The solver can always ignore hmin = 0.
    userhmin = 0;
else
    if userhmin <= 0
        error(message('MATLAB:odearguments:MinStepLEzero'));
    end
    % hmin should not be longer than the interval.
    userhmin = min(tlen,userhmin);
    if useDefaultHMax
        % Generally hmax will be 1/10th of the interval here. Make sure
        % that's not smaller than hmin.
        hmax = max(userhmin,hmax);
    else
        % When both MinStep and MaxStep are supplied by the user, ensure
        % that MaxStep >= MinStep.
        if hmax < userhmin
            error(message('MATLAB:odearguments:InconsistentMinStep'));
        end
    end
end

htry = ddeget(options,'InitialStep',[]);
if htry <= 0
    error(message('MATLAB:dde23:OptInitialStepNotPos'));
end
if isempty(htry)
    if hmax == userhmin
        % fixed step
        htry = userhmin;
    end
end

f = zeros(neq,4,dataType);

if nargout > 0
    nout = 1;
else % no output for plotting
    nout = 0;
end
tout = cast(t0, "like", protoType);
yout = cast(y0, "like", protoType);
ypout = cast(f0, "like", protoType);

events = ddeget(options,'Events',[]);
haveeventfun = ~isempty(events);
if haveeventfun
    valt = events(t0,y0,Z0,varargin{:});
end
teout = [];
yeout = [];
ieout = [];

% Handle the output
if nargout > 0
    outputFcn = ddeget(options,'OutputFcn',[]);
else
    outputFcn = ddeget(options,'OutputFcn',@odeplot);
end
outputArgs = {};
if isempty(outputFcn)
    haveOutputFcn = false;
else
    haveOutputFcn = true;
    outputs = ddeget(options,'OutputSel',1:neq);
    outputArgs = varargin;
end
refine = max(1,ddeget(options,'Refine',1));
ntspan = numel(tspan);
if ntspan > 2
    outputAt = 1;         % output only at tspan points
elseif refine <= 1
    outputAt = 2;         % computed points, no refinement
else
    outputAt = 3;         % computed points, with refinement
    S = (1:refine-1) / refine;
end
printstats = ddeget(options,'Stats','off') == "on";

hmax0 = hmax; % save hmax value at start.
tinystep = 16*eps(t0);
hmin = max(tinystep,userhmin);
hmax = max(tinystep,hmax0);
if isempty(htry)
    % Compute an initial step size h using y'(t).
    h = min(hmax, tfinal - t0);
    if normcontrol
        rh = (norm(f0) / max(normy,threshold)) / (0.8 * rtol^pow);
    else
        rh = norm(f0 ./ max(abs(y0),threshold),inf) / (0.8 * rtol^pow);
    end
    if h * rh > 1
        h = 1 / rh;
    end
    h = max(h, hmin);
else
    h = min(hmax, max(hmin, htry));
end
% Make sure that the first step is explicit so that the code can
% properly initialize the interpolant.
h = min(h,0.5*minlag);

% Initialize the output function.
if haveOutputFcn
    feval(outputFcn,[t0 tfinal],y0(outputs),'init',outputArgs{:});
end
next = 2;

% Initialize solver solution memory. This will be used for interpolating
% solver history during solve. When output is not the natural solver steps,
% these will not coincide, and we must keep the history separate. 
keepSeparateSolverHistory = ~output_sol || outputAt == 1 || outputAt == 3;
t_solver = t0;
y_solver = y0;
yp_solver = f0;

% THE MAIN LOOP
t = t0;
y = y0;
f(:,1) = f0;

done = false;
while ~done

    % By default, hmin is a small number such that t+hmin is only slightly
    % different than t.  It might be 0 if t is 0.
    tinystep = 16*eps(t);
    hmin = max(tinystep,userhmin);
    hmax = max(tinystep,hmax0);
    h = min(hmax, max(hmin, h));    % couldn't limit h until new hmin

    % Adjust step size to hit discontinuity. tfinal = discont(end).
    hitdsc = false;
    distance = discont(nextdsc) - t;
    if min(1.1*h,hmax) >= distance          % stretch
        h = distance;
        hitdsc = true;
    elseif 2*h >= distance                  % look-ahead
        h = distance/2;
    end
    if ~hitdsc && (minlag < h) && (h < 2*minlag)
        h = minlag;
    end

    % LOOP FOR ADVANCING ONE STEP.
    nofailed = true;                      % no failed attempts
    while true
        hB = h * B;
        t1 = t + 0.5*h;
        t2 = t + 0.75*h;
        tnew = t + h;
        if hitdsc
            tnew = discont(nextdsc);          % hit discontinuity exactly
        end
        h = tnew - t;                       % purify h

        % If a lagged argument falls in the current step, we evaluate the
        % formula by iteration. Extrapolation is used for the evaluation
        % of the history terms in the first iteration and the tnew,ynew,
        % ypnew of the current iteration are used in the evaluation of
        % these terms in the next iteration.
        if minlag < h
            maxit = 5;
        else
            maxit = 1;
        end
        X = t_solver;
        Y = y_solver;
        YP = yp_solver;
        itfail = false;
        for iter = 1:maxit
            Z = lagvals(t1,[],lags,history,X,Y,YP,varargin{:});
            f(:,2) = ddefun(t1,y+f*hB(:,1),Z,varargin{:});
            Z = lagvals(t2,[],lags,history,X,Y,YP,varargin{:});
            f(:,3) = ddefun(t2,y+f*hB(:,2),Z,varargin{:});
            ynew = y + f*hB(:,3);
            Z = lagvals(tnew,[],lags,history,X,Y,YP,varargin{:});
            f(:,4) = ddefun(tnew,ynew,Z,varargin{:});
            nfevals = nfevals + 3;
            if maxit > 1
                if iter > 1
                    if normcontrol
                        errit = norm(ynew - last_y) /  max(max(normy,norm(ynew)),threshold);
                    else
                        errit = norm((ynew - last_y) ./  max(max(abs(y),abs(ynew)),threshold),inf);
                    end
                    if errit <= 0.1*rtol
                        break;
                    end
                end
                % Use the tentative solution at tnew in the evaluation of the
                % history terms of the next iteration.
                X =  [t_solver, tnew];
                Y =  [y_solver, ynew];
                YP = [yp_solver, f(:,4)];
                last_y = ynew;
                itfail = (iter == maxit);
            end
        end

        if itfail
            nfailed = nfailed + 1;
            if h <= hmin
                warning(message('MATLAB:dde23:IntegrationTolNotMet', sprintf( '%e', t ), sprintf( '%e', hmin )));
                sol = odefinalize(solver_name, sol,...
                    outputFcn, outputArgs,...
                    printstats, [nsteps, nfailed, nfevals],...
                    nout, tout, yout,...
                    haveeventfun, teout, yeout, ieout,...
                    {history,ypout},...
                    t);
                return;
            else
                h = 0.5*h;
                if h < 2*minlag
                    h = minlag;
                end
                hitdsc = false;
            end
        else
            % Estimate the error.
            if normcontrol
                normynew = norm(ynew);
                err = h * (norm(f * E) / max(max(normy,normynew),threshold));
            else
                err = h * norm((f * E) ./ max(max(abs(y),abs(ynew)),threshold),inf);
            end

            % Accept the solution only if the weighted error is no more than the
            % tolerance rtol.  Estimate an h that will yield an error of rtol on
            % the next step or the next try at taking this step, as the case may be,
            % and use 0.8 of this value to avoid failures.
            if err > rtol   % Failed step
                nfailed = nfailed + 1;
                if h <= hmin
                    warning(message('MATLAB:dde23:IntegrationTolNotMet', sprintf( '%e', t ), sprintf( '%e', hmin )));
                    sol = odefinalize(solver_name, sol,...
                        outputFcn, outputArgs,...
                        printstats, [nsteps, nfailed, nfevals],...
                        nout, tout, yout,...
                        haveeventfun, teout, yeout, ieout,...
                        {history,ypout},...
                        t);
                    return;
                else
                    if nofailed
                        nofailed = false;
                        h = max(hmin, h * max(0.5, 0.8*(rtol/err)^pow));
                    else
                        h = max(hmin, 0.5*h);
                    end
                    hitdsc = false;
                end
            else      % Successful step
                break
            end
        end
    end
    nsteps = nsteps + 1;

    if haveeventfun
        X =  [t_solver, tnew];
        Y =  [y_solver, ynew];
        YP = [yp_solver, f(:,4)];
        eventargs = [{events,lags,history,X,Y,YP},varargin];
        [te,ye,ie,valt,stop] = odezero(@ntrp3h,@events_aux,eventargs,valt,...
            t,y,tnew,ynew,t0,f(:,1),f(:,4)); 

        if ~isempty(te)
            teout = [teout, te]; %#ok<AGROW>
            yeout = [yeout, ye]; %#ok<AGROW>
            ieout = [ieout, ie]; %#ok<AGROW>
            if stop
                % Stop on a terminal event after the initial point.
                % Make the output arrays end there.  Must compute
                % the slope to obtain the same interpolant for the
                % shorter step.
                [~,f(:,4)] = ntrp3h(te(end),t,y,tnew,ynew,f(:,1),f(:,4));
                tnew = te(end);
                ynew = ye(:,end);
                done = true;
            end
        end
    end

    % X, Y, YP may be sharing the data with t_solver, y_solver, and yp_solver.
    % Assign arbitrary values to them to break the links and
    % avoid unnecessary copy on write when storing the ouput below.
    X = 0; Y = 0; YP = 0;     %#ok<NASGU>
    % also break solver link before changing output arrays if they are
    % shared with the solver arrays.
    if ~keepSeparateSolverHistory
        t_solver = 0; y_solver = 0; yp_solver = 0;
    end

    % Store the output
    if output_sol
        nout = nout + 1;
        tout = [tout, tnew];      %#ok<AGROW>
        yout = [yout, ynew];      %#ok<AGROW>
        ypout = [ypout, f(:,4)];  %#ok<AGROW>
    end

    if output_ty || haveOutputFcn
        switch outputAt
            case 2       % computed points, no refinement
                nout_new = 1;
                tout_new = tnew;
                yout_new = ynew;
                ypout_new = f(:,4);
            case 3       % computed points, with refinement
                tref = t + (tnew-t)*S;
                nout_new = refine;
                tout_new = [tref, tnew];
                % interpolate refined values in step
                [yout_new,ypout_new] = ntrp3h(tref,t,y,tnew,ynew,f(:,1),f(:,4));
                % add step from solver
                yout_new = [yout_new, ynew]; %#ok<AGROW>
                ypout_new = [ypout_new f(:,4)]; %#ok<AGROW>
            case 1       % output only at tspan points
                nout_new =  0;
                tout_new = [];
                yout_new = [];
                ypout_new = [];
                while next <= ntspan
                    if tnew < tspan(next)
                        if haveeventfun && stop     % output tstop,ystop
                            nout_new = nout_new + 1;
                            tout_new = [tout_new, tnew]; %#ok<AGROW>
                            yout_new = [yout_new, ynew]; %#ok<AGROW>
                            ypout_new = [ypout_new f(:,4)]; %#ok<AGROW>
                        end
                        break;
                    end
                    nout_new = nout_new + 1;
                    tout_new = [tout_new, tspan(next)]; %#ok<AGROW>
                    if tspan(next) == tnew
                        yout_new = [yout_new, ynew]; %#ok<AGROW>
                        ypout_new = [ypout_new, f(:,4)]; %#ok<AGROW>
                    else
                        [yint,ypint] = ntrp3h(tspan(next),t,y,tnew,ynew,f(:,1),f(:,4));
                        yout_new = [yout_new, yint]; %#ok<AGROW>
                        ypout_new = [ypout_new, ypint]; %#ok<AGROW>
                    end
                    next = next + 1;
                end
        end
        % write out the new values
        if output_ty % already wrote out for sol struct
            nout = nout + nout_new;
            tout = [tout tout_new]; %#ok<AGROW>
            yout = [yout yout_new]; %#ok<AGROW>
            ypout = [ypout ypout_new]; %#ok<AGROW>
        end
        if haveOutputFcn && nout_new > 0
            stop = feval(outputFcn,tout_new,yout_new(outputs,:),'',outputArgs{:});
            if stop  % Stop per user request.
                done = true;
            end
        end
    end

    if ~done
        % Have we hit tfinal = discont(end)?
        if hitdsc
            nextdsc = nextdsc + 1;
            done = nextdsc > numel(discont);
        end
        if ~done
            % Advance the integration one step.
            t = tnew;
            y = ynew;
            if normcontrol
                normy = normynew;
            end
            f(:,1) = f(:,4);                      % BS(2,3) is FSAL.
            % fill in new history. If solver steps are kept separate, add
            % onto solver history, otherwise, share with output arrays.
            % Note we should break link with *out before changing *_solver
            % when memory is shared. 
            if keepSeparateSolverHistory
                t_solver = [t_solver tnew]; %#ok<AGROW>
                y_solver = [y_solver ynew]; %#ok<AGROW>
                yp_solver = [yp_solver f(:,4)]; %#ok<AGROW>
            else % *_solver and *_out coincide
                t_solver = tout;
                y_solver = yout;
                yp_solver = ypout;
            end

            % If there were no failures, compute a new h.
            if nofailed && ~itfail
                % Note that h may shrink by 0.8, and that err may be 0.
                temp = 1.25*(err/rtol)^pow;
                if temp > 0.2
                    h = h / temp;
                else
                    h = 5*h;
                end
                h = min(max(hmin,h),hmax);
            end

        end

    end

end

% Successful integration
sol = odefinalize(solver_name, sol,...
    outputFcn, outputArgs,...
    printstats, [nsteps, nfailed, nfevals],...
    nout, tout, yout,...
    haveeventfun, teout, yeout, ieout,...
    {history,ypout});

end

%---------------------------------------------------------------------------

function [vtry,isterminal,direction] = events_aux(ttry,ytry,eventfun,...
    lags,history,X,Y,YP,varargin)
% Auxiliary function used by ODEZERO to detect events.
Z = matlab.ode.internal.dde.lagvals(ttry,[],lags,history,X,Y,YP,varargin{:});
[vtry,isterminal,direction] = eventfun(ttry,ytry,Z,varargin{:});
end