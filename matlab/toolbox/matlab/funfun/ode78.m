function varargout = ode78(ode,tspan,y0,options,varargin)
%ODE78  Solve non-stiff differential equations, high order method.
%   [TOUT,YOUT] = ODE78(ODEFUN,TSPAN,Y0) integrates the system of
%   differential equations y' = f(t,y) from time TSPAN(1) to TSPAN(end)
%   with initial conditions Y0. Each row in the solution array YOUT
%   corresponds to a time in the column vector TOUT.
%     * ODEFUN is a function handle. For a scalar T and a vector Y,
%       ODEFUN(T,Y) must return a column vector corresponding to f(t,y).
%     * TSPAN is a two-element vector [T0 TFINAL] or a vector with
%       several time points [T0 T1 ... TFINAL]. If you specify more than
%       two time points, ODE78 returns interpolated solutions at the
%       requested times.
%     * YO is a column vector of initial conditions, one for each equation.
%
%   [TOUT,YOUT] = ODE78(ODEFUN,TSPAN,Y0,OPTIONS) specifies integration
%   option values in the fields of a structure, OPTIONS. Create the
%   options structure with <a href="matlab:helpview('matlab','MATLAB_HELP_ODESET')">odeset</a>.
%
%   [TOUT,YOUT,TE,YE,IE] = ODE78(ODEFUN,TSPAN,Y0,OPTIONS) produces
%   additional outputs for events. An event occurs when a specified function
%   of T and Y is equal to zero. See <a href="matlab:helpview('matlab','MATLAB_HELP_EVENTS')">ODE Event Location</a> for details.
%
%   SOL = ODE78(...) returns a solution structure instead of numeric
%   vectors. Use SOL as an input to DEVAL to evaluate the solution at
%   specific points. Use it as an input to ODEXTEND to extend the
%   integration interval.
%
%   ODE78 can solve problems M(t,y)*y' = f(t,y) with mass matrix M that is
%   nonsingular. Use ODESET to set the 'Mass' property to a function handle
%   or the value of the mass matrix. ODE15S and ODE23T can solve problems
%   with singular mass matrices.
%
%   ODE23, ODE45, ODE78, and ODE89 are all single-step solvers that use
%   explicit Runge-Kutta formulas of different orders to estimate the error
%   in each step.
%     * ODE45 is for general use.
%     * ODE23 is useful for moderately stiff problems.
%     * ODE78 and ODE89 may be more efficient than ODE45 on non-stiff problems
%       that are smooth except possibly for a few isolated discontinuities.
%     * ODE89 may be more efficient than ODE78 on very smooth problems, when
%       integrating over long time intervals, or when tolerances are tight.
%     * ODE78 and ODE89 may not be as fast or as accurate as ODE45 in single
%       precision.
%
%   Example
%         opts = odeset('AbsTol',1e-8,'RelTol',1e-6);
%         [t,y] = ode78(@vdp1,[0 20],[2 0],opts);
%         plot(t,y(:,1));
%     solves the system y' = vdp1(t,y), using the specified tolerances, and
%     plots the first component of the solution.
%
%   Class support for inputs TSPAN, Y0, and the result of ODEFUN(T,Y):
%     float: double, single
%
%   See also ODE89, ODE45, ODE23, ODE113, ODE15S, ODE23S, ODE23T, ODE23TB,
%            ODE15I, ODESET, ODEPLOT, ODEPHAS2, ODEPHAS3, ODEPRINT, DEVAL,
%            ODEEXAMPLES, FUNCTION_HANDLE.

%   ODE78 is an implementation of Verner's "Most Efficient" Runge-Kutta
%   8(7) pair with the 7th-order continuous extension.
%
%   Verner, J.H. Numerically optimal Runge–Kutta pairs with interpolants.
%   Numer Algor 53, 383–396 (2010).
%
%   The solution is advanced with the 8th-order result. The 7th-order
%   continuous extension requires 4 additional evaluations of ODEFUN, but
%   only on steps where interpolation is required.

%   Copyright 1984-2024 The MathWorks, Inc.
%#ok<*AGROW>
solver_name = 'ode78';

if nargin < 4
    options = [];
    if nargin < 3
        y0 = [];
        if nargin < 2
            tspan = [];
        end
    end
end

% Stats
nsteps  = 0;
nfailed = 0;
nfevals = 0;

[ode, odeIsFuncHandle, odeTreatAsMFile] = packageAsFuncHandle(ode);

% Output
output_sol = (odeIsFuncHandle && (nargout==1)); % sol = odeXX(...)
output_ty  = (~output_sol && (nargout > 0)); % [t,y,...] = odeXX(...)
% There might be no output requested...

sol = []; f3d = [];
if output_sol
    sol.solver = solver_name;
    sol.extdata.odefun = ode;
    sol.extdata.options = options;
    sol.extdata.varargin = varargin;
end

% Handle solver arguments
[neq,tspan,ntspan,next,t0,tfinal,tdir,y0,f0,odeArgs, ...
    options,threshold,rtol,normcontrol,normy,userhmin,userhmax,htry,htspan,dataType] = ...
    odearguments(odeIsFuncHandle,odeTreatAsMFile,solver_name,ode,tspan,y0,options,varargin);
nfevals = nfevals + 1;
ZERO = zeros(dataType);

% Handle the output
if nargout > 0
    outputFcn = odeget(options,'OutputFcn',[]);
else
    outputFcn = odeget(options,'OutputFcn',@odeplot);
end
outputArgs = {};
if isempty(outputFcn)
    haveOutputFcn = false;
else
    haveOutputFcn = true;
    outputs = odeget(options,'OutputSel',1:neq);
    if isa(outputFcn,'function_handle')
        % With MATLAB 6 syntax pass additional input arguments to outputFcn.
        outputArgs = varargin;
    end
end
refine = max(1,odeget(options,'Refine',8));
if ntspan > 2
    outputAt = 1; % output only at tspan points
elseif refine <= 1
    outputAt = 2; % computed points, no refinement
else
    outputAt = 3; % computed points, with refinement
    S = (1:refine-1) / refine;
end
printstats = strcmp(odeget(options,'Stats','off'),'on');

% Handle the event function
[haveEventFcn,eventFcn,eventArgs,valt,teout,yeout,ieout] = ...
    odeevents(odeIsFuncHandle,ode,t0,y0,options,varargin);

% Handle the mass matrix
[Mtype,M,Mfun] =  odemass(odeIsFuncHandle,ode,t0,y0,options,dataType,varargin);
if Mtype > 0 % non-trivial mass matrix
    Msingular = odeget(options,'MassSingular','no');
    if strcmp(Msingular,'maybe')
        warning(message('MATLAB:ode78:MassSingularAssumedNo'));
    elseif strcmp(Msingular,'yes')
        error(message('MATLAB:ode78:MassSingularYes'));
    end
    % Incorporate the mass matrix into ode and odeArgs.
    [ode,odeArgs] = odemassexplicit(odeIsFuncHandle,Mtype,ode,odeArgs,Mfun,M);
    f0 = ode(t0,y0,odeArgs{:});
    nfevals = nfevals + 1;
    [~,ZERO] = matlab.ode.internal.updateDatatype(dataType,M,solver_name,"mass matrix");
end

% Non-negative solution components
idxNonNegative = odeget(options,'NonNegative',[]);
nonNegative = ~isempty(idxNonNegative);
if nonNegative % modify the derivative function
    [ode,thresholdNonNegative] = odenonnegative(ode,y0,threshold,idxNonNegative);
    f0 = ode(t0,y0,odeArgs{:});
    nfevals = nfevals + 1;
end

t = t0;
y = y0;

% Allocate memory if we're generating output.
nout = 0;
tout = zeros(0,"like",ZERO); yout = zeros(0,"like",ZERO);
if nargout > 0
    if output_sol
        chunk = min(max(100,50*refine),refine+floor((2^11)/neq));
        tout = zeros(1,chunk,"like",ZERO);
        yout = zeros(neq,chunk,"like",ZERO);
        f3d  = zeros(neq,12,chunk,"like",ZERO);
    else
        if ntspan > 2 % output only at tspan points
            tout = zeros(1,ntspan,"like",ZERO);
            yout = zeros(neq,ntspan,"like",ZERO);
        else % alloc in chunks
            chunk = min(max(100,50*refine),refine+floor((2^13)/neq));
            tout = zeros(1,chunk,"like",ZERO);
            yout = zeros(neq,chunk,"like",ZERO);
        end
    end
    nout = 1;
    tout(nout) = t;
    yout(:,nout) = y;
end

% Initialize method parameters.
pow = 1/8;
hminFactor = 16;
tinystep = hminFactor*eps(t);
hmin = max(tinystep,userhmin);
hmax = max(tinystep,userhmax);
if isempty(htry)
    % Compute an initial step size h using y'(t).
    absh = min(hmax,htspan);
    if normcontrol
        rh = (norm(f0) / max(normy,threshold)) / (0.8 * rtol^pow);
    else
        rh = norm(f0 ./ max(abs(y),threshold),inf) / (0.8 * rtol^pow);
    end
    if absh * rh > 1
        absh = 1 / rh;
    end
    absh = max(absh,hmin);
else
    absh = min(hmax,max(hmin,htry));
end

% Initialize the output function.
if haveOutputFcn
    feval(outputFcn,[t tfinal],y(outputs),'init',outputArgs{:});
end

% THE MAIN LOOP

done = false;
while ~done
    
    tinystep = hminFactor*eps(t);
    hmin = max(tinystep,userhmin);
    hmax = max(tinystep,userhmax);
    absh = min(hmax,max(hmin,absh)); % couldn't limit absh until new hmin
    h = tdir * absh;

    % Stretch the step if within 10% of tfinal-t.
    if 1.1*absh >= abs(tfinal - t)
        h = tfinal - t;
        absh = abs(h);
        done = true;
    end

    % LOOP FOR ADVANCING ONE STEP.
    nofailed = true; % no failed attempts
    while true
        if t == t0
            f1 = f0;
        elseif nofailed
            f1 = ode(t,y,odeArgs{:});
            nfevals = nfevals + 1;
        end

        ystage = y + h*0.05*f1;
        f2 = ode(t + 0.05*h,ystage,odeArgs{:});

        ystage = y + h*( ...
            -0.0069931640625*f1 + ...
            0.1135556640625*f2);
        f3 = ode(t + 0.1065625*h,ystage,odeArgs{:});

        ystage = y + h*( ...
            0.0399609375*f1 + ...
            0.1198828125*f3);
        f4 = ode(t + 0.15984375*h,ystage,odeArgs{:});

        ystage = y + h*( ...
            0.36139756280045754*f1 + ...
            -1.3415240667004928*f3 + ...
            1.3701265039000352*f4);
        f5 = ode(t + 0.39*h,ystage,odeArgs{:});

        ystage = y + h*( ...
            0.049047202797202795*f1 + ...
            0.23509720422144048*f4 + ...
            0.18085559298135673*f5);
        f6 = ode(t + 0.465*h,ystage,odeArgs{:});

        ystage = y + h*( ...
            0.06169289044289044*f1 + ...
            0.11236568314640277*f4 + ...
            -0.03885046071451367*f5 + ...
            0.01979188712522046*f6);
        f7 = ode(t + 0.155*h,ystage,odeArgs{:});

        ystage = y + h*( ...
            -1.767630240222327*f1 + ...
            -62.5*f4 + ...
            -6.061889377376669*f5 + ...
            5.6508231982227635*f6 + ...
            65.62169641937624*f7);
        f8 = ode(t + 0.943*h,ystage,odeArgs{:});

        ystage = y + h*( ...
            -1.1809450665549708*f1 + ...
            -41.50473441114321*f4 + ...
            -4.434438319103725*f5 + ...
            4.260408188586133*f6 + ...
            43.75364022446172*f7 + ...
            0.00787142548991231*f8);
        f9 = ode(t + 0.901802041735857*h,ystage,odeArgs{:});

        ystage = y + h*( ...
            -1.2814059994414884*f1 + ...
            -45.047139960139866*f4 + ...
            -4.731362069449577*f5 + ...
            4.514967016593808*f6 + ...
            47.44909557172985*f7 + ...
            0.010592282971116612*f8 + ...
            -0.0057468422638446166*f9);
        f10 = ode(t + 0.909*h,ystage,odeArgs{:});

        ystage = y + h*( ...
            -1.7244701342624853*f1 + ...
            -60.92349008483054*f4 + ...
            -5.951518376222393*f5 + ...
            5.556523730698456*f6 + ...
            63.98301198033305*f7 + ...
            0.014642028250414961*f8 + ...
            0.06460408772358203*f9 + ...
            -0.0793032316900888*f10);
        f11 = ode(t + 0.94*h,ystage,odeArgs{:});

        ystage = y + h*( ...
            -3.301622667747079*f1 + ...
            -118.01127235975251*f4 + ...
            -10.141422388456112*f5 + ...
            9.139311332232058*f6 + ...
            123.37594282840426*f7 + ...
            4.62324437887458*f8 + ...
            -3.3832777380682018*f9 + ...
            4.527592100324618*f10 + ...
            -5.828495485811623*f11);
        f12 = ode(t + h,ystage,odeArgs{:});

        ystage = y + h*( ...
            -3.039515033766309*f1 + ...
            -109.26086808941763*f4 + ...
            -9.290642497400293*f5 + ...
            8.43050498176491*f6 + ...
            114.20100103783314*f7 + ...
            -0.9637271342145479*f8 + ...
            -5.0348840888021895*f9 + ...
            5.958130824002923*f10);
        f13 = ode(t + h,ystage,odeArgs{:});

        fC = 0.04427989419007951*f1 + ...
             0.3541049391724449*f6 + ...
             0.2479692154956438*f7 + ...
             -15.694202038838084*f8 + ...
             25.084064965558564*f9 + ...
             -31.738367786260277*f10 + ...
             22.938283273988784*f11 + ...
             -0.2361324633071542*f12;

        fE = 3.272103901028776e-05*f1 + ...
             0.0005046250618777735*f6 + ...
             -0.00012117235897844563*f7 + ...
             20.142336771313868*f8 + ...
             -5.237178599439828*f9 + ...
             8.156744408794658*f10 + ...
             -22.938283273988784*f11 + ...
             0.2361324633071542*f12 + ...
             -0.36016794372897754*f13;

        nfevals = nfevals + 12;

        ynew = y + h*fC;
        tnew = t + h;
        if done
            tnew = tfinal; % Hit end point exactly.
        end
        h = tnew - t; % Purify h.

        % Estimate the error.
        NNrejectStep = false;
        if normcontrol
            normynew = norm(ynew);
            % If previous step was successful, incorporate normynew, else
            % only use normy because we don't trust normynew.
            if nofailed
                errwt = max(max(normy,normynew),threshold);
            else
                errwt = max(normy,threshold);
            end
            err = absh * (norm(fE) / errwt);
            if nonNegative && (err <= rtol) && any(ynew(idxNonNegative)<0)
                errNN = norm( max(0,-ynew(idxNonNegative)) ) / errwt ;
                if errNN > rtol
                    err = errNN;
                    NNrejectStep = true;
                end
            end
        else
            % If previous step was successful, incorporate ynew into the
            % scaling of the error condition. If not, only use y,
            % since we don't trust ynew.
            if nofailed
                err = absh * norm((fE) ./ max(max(abs(y),abs(ynew)),threshold),inf);
            else
                err = absh * norm((fE) ./ max(abs(y),threshold),inf);
            end
            if nonNegative && (err <= rtol) && any(ynew(idxNonNegative)<0)
                errNN = norm( max(0,-ynew(idxNonNegative)) ./ thresholdNonNegative,inf);
                if errNN > rtol
                    err = errNN;
                    NNrejectStep = true;
                end
            end
        end

        % Accept the solution only if the weighted error is no more than the
        % tolerance rtol.  Estimate an h that will yield an error of rtol on
        % the next step or the next try at taking this step, as the case may be,
        % and use 0.8 of this value to avoid failures.
        if ~(err <= rtol) % Failed step
            nfailed = nfailed + 1;
            if absh <= hmin
                warning(message('MATLAB:ode78:IntegrationTolNotMet',sprintf( '%e',t ),sprintf( '%e',hmin )));
                solver_output = odefinalize(solver_name,sol,...
                    outputFcn,outputArgs,...
                    printstats,[nsteps,nfailed,nfevals],...
                    nout,tout,yout,...
                    haveEventFcn,teout,yeout,ieout,...
                    {f3d,idxNonNegative},...
                    t);
                if nargout > 0
                    varargout = solver_output;
                end
                return
            end

            if nofailed
                nofailed = false;
                if NNrejectStep
                    absh = max(hmin,0.5*absh);
                else
                    absh = max(hmin,absh * max(0.1,0.8*(rtol/err)^pow));
                end
            else
                absh = max(hmin,0.5 * absh);
            end
            h = tdir * absh;
            done = false;
        else % Successful step
            if nonNegative && any(ynew(idxNonNegative)<0)
                ynew(idxNonNegative) = max(ynew(idxNonNegative),0);
                if normcontrol
                    normynew = norm(ynew);
                end
            end
            break
        end
    end
    nsteps = nsteps + 1;
    haveCEStages = false;
    if haveEventFcn
        [f14,f15,f16,f17,nfevals] = ...
            computeCEStages(ode,t,y,h,f1,f6,f7,f8,f9,f10,f11,f12,nfevals,odeArgs);
        haveCEStages = true;
        f = [f1,f6,f7,f8,f9,f10,f11,f12,f14,f15,f16,f17];
        [te,ye,ie,valt,stop] = ...
            odezero(@ntrp78,eventFcn,eventArgs,valt,t,y,tnew,ynew,t0,h,f,idxNonNegative);
        if ~isempty(te)
            if output_sol || (nargout > 2)
                teout = [teout,te];
                yeout = [yeout,ye];
                ieout = [ieout,ie];
            end
            if stop
                done = true;
                tnew = te(end);
                ynew = ye(:,end);
                hnew = tnew - t;
                % Interpolate to update stages for the closer end point.
                taux = t + [ ...
                    0.465, ... % for f6
                    0.155, ... % for f7
                    0.943,... % for f8
                    0.901802041735857, ... % for f9
                    0.909, ... % for f10
                    0.94, ... % for f11
                    1, ... % for f12 and f14
                    0.3110177634953864, ... % for f15
                    0.1725, ... % for f16
                    0.7846 ... % for f17
                    ]*hnew;
                [~,ftmp] = ntrp78(taux,t,y,[],[],h,f,idxNonNegative);
                f6 = ftmp(:,1);
                f7 = ftmp(:,2);
                f8 = ftmp(:,3);
                f9 = ftmp(:,4);
                f10 = ftmp(:,5);
                f11 = ftmp(:,6);
                f12 = ftmp(:,7);
                f14 = ftmp(:,7);
                f15 = ftmp(:,8);
                f16 = ftmp(:,9);
                f17 = ftmp(:,10);
                h = hnew;
            end
        end
    end

    if output_sol
        nout = nout + 1;
        tout(nout) = tnew;
        yout(:,nout) = ynew;
        if ~haveCEStages
            [f14,f15,f16,f17,nfevals] = computeCEStages( ...
                ode,t,y,h,f1,f6,f7,f8,f9,f10,f11,f12,nfevals,odeArgs);
            haveCEStages = true;
        end
        f3d(:,1,nout) = f1;
        f3d(:,2,nout) = f6;
        f3d(:,3,nout) = f7;
        f3d(:,4,nout) = f8;
        f3d(:,5,nout) = f9;
        f3d(:,6,nout) = f10;
        f3d(:,7,nout) = f11;
        f3d(:,8,nout) = f12;
        f3d(:,9,nout) = f14;
        f3d(:,10,nout) = f15;
        f3d(:,11,nout) = f16;
        f3d(:,12,nout) = f17;
    end

    if output_ty || haveOutputFcn
        switch outputAt
            case 2 % computed points, no refinement
                nout_new = 1;
                tout_new = tnew;
                yout_new = ynew;
            case 3 % computed points, with refinement
                tref = t + (tnew-t)*S;
                nout_new = refine;
                tout_new = [tref,tnew];
                if ~haveCEStages
                    [f14,f15,f16,f17,nfevals] = computeCEStages( ...
                        ode,t,y,h,f1,f6,f7,f8,f9,f10,f11,f12,nfevals,odeArgs);
                    % HAVECEStages = true;
                end
                yntrp78 = ntrp78split(tref,t,y,h, ...
                    f1,f6,f7,f8,f9,f10,f11,f12,f14,f15,f16,f17, ...
                    idxNonNegative);
                yout_new = [yntrp78,ynew];
            case 1 % output only at tspan points
                nout_new =  0;
                tout_new = [];
                yout_new = [];
                while next <= ntspan
                    if tdir * (tnew - tspan(next)) < 0
                        if haveEventFcn && stop % output tstop,ystop
                            nout_new = nout_new + 1;
                            tout_new = [tout_new,tnew];
                            yout_new = [yout_new,ynew];
                        end
                        break;
                    end
                    nout_new = nout_new + 1;
                    tout_new = [tout_new,tspan(next)];
                    if tspan(next) == tnew
                        yout_new = [yout_new,ynew];
                    else
                        if ~haveCEStages
                            [f14,f15,f16,f17,nfevals] = computeCEStages( ...
                                ode,t,y,h,f1,f6,f7,f8,f9,f10,f11,f12,nfevals,odeArgs);
                            haveCEStages = true;
                        end
                        yntrp78 = ntrp78split(tspan(next),t,y,h, ...
                            f1,f6,f7,f8,f9,f10,f11,f12,f14,f15,f16,f17, ...
                            idxNonNegative);
                        yout_new = [yout_new,yntrp78];
                    end
                    next = next + 1;
                end
        end

        if nout_new > 0
            if output_ty
                oldnout = nout;
                nout = nout + nout_new;
                idx = oldnout+1:nout;
                tout(idx) = tout_new;
                yout(:,idx) = yout_new;
            end
            if haveOutputFcn
                stop = feval(outputFcn,tout_new,yout_new(outputs,:),'',outputArgs{:});
                if stop
                    done = true;
                end
            end
        end
    end

    if done
        break
    end

    % If there were no failures compute a new h.
    if nofailed
        % Note that absh may shrink by 0.8, and that err may be 0.
        temp = 1.25*(err/rtol)^pow;
        if temp > 0.2
            absh = absh / temp;
        else
            absh = 5.0*absh;
        end
    end

    % Advance the integration one step.
    t = tnew;
    y = ynew;
    if normcontrol
        normy = normynew;
    end

end

solver_output = odefinalize(solver_name,sol,...
    outputFcn,outputArgs,...
    printstats,[nsteps,nfailed,nfevals],...
    nout,tout,yout,...
    haveEventFcn,teout,yeout,ieout,...
    {f3d,idxNonNegative});

if nargout > 0
    varargout = solver_output;
end

%--------------------------------------------------------------------------

function [f14,f15,f16,f17,nfevals] = computeCEStages( ...
    ode,t,y,h,f1,f6,f7,f8,f9,f10,f11,f12,nfevals,odeArgs)
% Compute stages for the order 7 continuous extension.

ystage = y + h*( ...
    0.04427989419007951*f1 + ...
    0.3541049391724449*f6 + ...
    0.2479692154956438*f7 + ...
    -15.694202038838084*f8 + ...
    25.084064965558564*f9 + ...
    -31.738367786260277*f10 + ...
    22.938283273988784*f11 + ...
    -0.2361324633071542*f12);
f14 = ode(t + h,ystage,odeArgs{:});

ystage = y + h*( ...
    0.04620700646754963*f1 + ...
    0.045039041608424805*f6 + ...
    0.23368166977134244*f7 + ...
    37.83901368421068*f8 + ...
    -15.949113289454246*f9 + ...
    23.028368351816102*f10 + ...
    -44.85578507769412*f11 + ...
    -0.06379858768647444*f12 + ...
    -0.012595035543861663*f14);
f15 = ode(t + 0.3110177634953864*h,ystage,odeArgs{:});

ystage = y + h*( ...
    0.05037946855482041*f1 + ...
    0.041098361310460796*f6 + ...
    0.17180541533481958*f7 + ...
    4.614105319981519*f8 + ...
    -1.7916678830853965*f9 + ...
    2.531658930485041*f10 + ...
    -5.324977860205731*f11 +  ...
    -0.03065532595385635*f12 + ...
    -0.005254479979429613*f14 + ...
    -0.08399194644224793*f15);
f16 = ode(t + 0.1725*h,ystage,odeArgs{:});

ystage = y + h*( ...
    0.0408289713299708*f1 + ...
    0.4244479514247632*f6 + ...
    0.23260915312752345*f7 + ...
    2.677982520711806*f8 + ...
    0.7420826657338945*f9 + ...
    0.1460377847941461*f10 + ...
    -3.579344509890565*f11 + ...
    0.11388443896001738*f12 + ...
    0.012677906510331901*f14 + ...
    -0.07443436349946675*f15 + ...
    0.047827480797578516*f16);
f17 = ode(t + 0.7846*h,ystage,odeArgs{:});

nfevals = nfevals + 4;

%--------------------------------------------------------------------------
