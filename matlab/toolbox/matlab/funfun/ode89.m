function varargout = ode89(ode,tspan,y0,options,varargin)
%ODE89  Solve non-stiff differential equations, high order method.
%   [TOUT,YOUT] = ODE89(ODEFUN,TSPAN,Y0) integrates the system of
%   differential equations y' = f(t,y) from time TSPAN(1) to TSPAN(end)
%   with initial conditions Y0. Each row in the solution array YOUT
%   corresponds to a time in the column vector TOUT.
%     * ODEFUN is a function handle. For a scalar T and a vector Y,
%       ODEFUN(T,Y) must return a column vector corresponding to f(t,y).
%     * TSPAN is a two-element vector [T0 TFINAL] or a vector with
%       several time points [T0 T1 ... TFINAL]. If you specify more than
%       two time points, ODE89 returns interpolated solutions at the
%       requested times.
%     * YO is a column vector of initial conditions, one for each equation.
%
%   [TOUT,YOUT] = ODE89(ODEFUN,TSPAN,Y0,OPTIONS) specifies integration
%   option values in the fields of a structure, OPTIONS. Create the
%   options structure with <a href="matlab:helpview('matlab','MATLAB_HELP_ODESET')">odeset</a>.
%
%   [TOUT,YOUT,TE,YE,IE] = ODE89(ODEFUN,TSPAN,Y0,OPTIONS) produces
%   additional outputs for events. An event occurs when a specified function
%   of T and Y is equal to zero. See <a href="matlab:helpview('matlab','MATLAB_HELP_EVENTS')">ODE Event Location</a> for details.
%
%   SOL = ODE89(...) returns a solution structure instead of numeric
%   vectors. Use SOL as an input to DEVAL to evaluate the solution at
%   specific points. Use it as an input to ODEXTEND to extend the
%   integration interval.
%
%   ODE89 can solve problems M(t,y)*y' = f(t,y) with mass matrix M that is
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
%         opts = odeset('AbsTol',1e-10,'RelTol',1e-8);
%         [t,y] = ode89(@vdp1,[0 20],[2 0],opts);
%         plot(t,y(:,1));
%     solves the system y' = vdp1(t,y), using the specified tolerances, and
%     plots the first component of the solution.
%
%   Class support for inputs TSPAN, Y0, and the result of ODEFUN(T,Y):
%     float: double, single
%
%   See also ODE78, ODE45, ODE23, ODE113, ODE15S, ODE23S, ODE23T, ODE23TB,
%            ODE15I, ODESET, ODEPLOT, ODEPHAS2, ODEPHAS3, ODEPRINT, DEVAL,
%            ODEEXAMPLES, FUNCTION_HANDLE.

%   ODE89 is an implementation of Verner's "Most Robust" Runge-Kutta 9(8)
%   pair with the 8th-order continuous extension.
%
%   Verner, J.H. Numerically optimal Runge–Kutta pairs with interpolants.
%   Numer Algor 53, 383–396 (2010).
%
%   The solution is advanced with the 9th-order result. The 8th-order
%   continuous extension requires 5 additional evaluations of ODEFUN, but
%   only on steps where interpolation is required.


%   Copyright 1984-2024 The MathWorks, Inc.
%#ok<*AGROW>
solver_name = 'ode89';

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
[Mtype,M,Mfun] = odemass(odeIsFuncHandle,ode,t0,y0,options,dataType,varargin);
if Mtype > 0 % non-trivial mass matrix
    Msingular = odeget(options,'MassSingular','no');
    if strcmp(Msingular,'maybe')
        warning(message('MATLAB:ode89:MassSingularAssumedNo'));
    elseif strcmp(Msingular,'yes')
        error(message('MATLAB:ode89:MassSingularYes'));
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
pow = 1/9;
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

        ystage = y + h*0.04*f1;
        f2 = ode(t + 0.04*h,ystage,odeArgs{:});

        ystage = y + h*( ...
            -0.01988527319182291*f1 + ...
            0.11637263332969652*f2);
        f3 = ode(t + 0.09648736013787361*h,ystage,odeArgs{:});

        ystage = y + h*( ...
            0.0361827600517026*f1 + ...
            0.10854828015510781*f3);
        f4 = ode(t + 0.1447310402068104*h,ystage,odeArgs{:});

        ystage = y + h*( ...
            2.2721142642901775*f1 + ...
            -8.526886447976398*f3 + ...
            6.830772183686221*f4);
        f5 = ode(t + 0.576*h,ystage,odeArgs{:});

        ystage = y + h*( ...
            0.050943855353893744*f1 + ...
            0.1755865049809071*f4 + ...
            0.0007022961270757468*f5);
        f6 = ode(t + 0.2272326564618766*h,ystage,odeArgs{:});

        ystage = y + h*( ...
            0.1424783668683285*f1 + ...
            -0.35417994346686843*f4 + ...
            0.07595315450295101*f5 + ...
            0.6765157656337123*f6);
        f7 = ode(t + 0.5407673435381234*h,ystage,odeArgs{:});

        ystage = y + h*( ...
            0.07111111111111111*f1 + ...
            0.32799092876058983*f6 + ...
            0.24089796012829906*f7);
        f8 = ode(t + 0.64*h,ystage,odeArgs{:});

        ystage = y + h*( ...
            0.07125*f1 + ...
            0.32688424515752457*f6 + ...
            0.11561575484247544*f7 + ...
            -0.03375*f8);
        f9 = ode(t + 0.48*h,ystage,odeArgs{:});

        ystage = y + h*( ...
            0.048226773224658105*f1 + ...
            0.039485599804954*f6 + ...
            0.10588511619346581*f7 + ...
            -0.021520063204743093*f8 + ...
            -0.10453742601833482*f9);
        f10 = ode(t + 0.06754*h,ystage,odeArgs{:});

        ystage = y + h*( ...
            -0.026091134357549235*f1 + ...
            0.03333333333333333*f6 + ...
            -0.1652504006638105*f7 + ...
            0.03434664118368617*f8 + ...
            0.1595758283215209*f9 + ...
            0.21408573218281934*f10);
        f11 = ode(t + 0.25*h,ystage,odeArgs{:});

        ystage = y + h*( ...
            -0.03628423396255659*f1 + ...
            -1.0961675974272087*f6 + ...
            0.1826035504321331*f7 + ...
            0.07082254444170684*f8 + ...
            -0.02313647018482431*f9 + ...
            0.27112047263209327*f10 + ...
            1.3081337494229808*f11);
        f12 = ode(t + 0.6770920153543243*h,ystage,odeArgs{:});

        ystage = y + h*( ...
            -0.5074635056416975*f1 + ...
            -6.631342198657237*f6 + ...
            -0.2527480100908801*f7 + ...
            -0.49526123800360955*f8 + ...
            0.2932525545253887*f9 + ...
            1.440108693768281*f10 + ...
            6.237934498647056*f11 + ...
            0.7270192054526987*f12);
        f13 = ode(t + 0.8115*h,ystage,odeArgs{:});

        ystage = y + h*( ...
            0.6130118256955932*f1 + ...
            9.088803891640463*f6 + ...
            -0.40737881562934486*f7 + ...
            1.7907333894903747*f8 + ...
            0.714927166761755*f9 + ...
            -1.438580857841723*f10 + ...
            -8.26332931206474*f11 + ...
            -1.5375705708088652*f12 + ...
            0.34538328275648716*f13);
        f14 = ode(t + 0.906*h,ystage,odeArgs{:});

        ystage = y + h*( ...
            -1.2116979103438739*f1 + ...
            -19.055818715595954*f6 + ...
            1.2630606753898752*f7 + ...
            -6.913916969178458*f8 + ...
            -0.676462266509498*f9 + ...
            3.367860445026608*f10 + ...
            18.00675164312591*f11 + ...
            6.83882892679428*f12 + ...
            -1.0315164519219504*f13 + ...
            0.41291062321306227*f14);
        f15 = ode(t + h,ystage,odeArgs{:});

        ystage = y + h*( ...
            2.1573890074940536*f1 + ...
            23.807122198095804*f6 + ...
            0.8862779249216556*f7 + ...
            13.139130397598764*f8 + ...
            -2.6044157092877147*f9 + ...
            -5.193859949783873*f10 + ...
            -20.412340711541507*f11 + ...
            -12.300856252505723*f12 + ...
            1.5215530950085394*f13);
        f16 = ode(t + h,ystage,odeArgs{:});

        nfevals = nfevals + 15;

        fC = 0.014588852784055396*f1 + ...
             0.0020241978878893325*f8 + ...
             0.21780470845697167*f9 + ...
             0.12748953408543898*f10 + ...
             0.2244617745463132*f11 + ...
             0.1787254491259903*f12 + ...
             0.07594344758096558*f13 + ...
             0.12948458791975614*f14 + ...
             0.029477447612619417*f15;

        fE = 0.005757813768188949*f1 + ...
             1.0675934530948108*f8 + ...
             -0.14099636134393978*f9 + ...
             -0.014411715396914925*f10 + ...
             0.030796961251883033*f11 + ...
             -1.1613152578179067*f12 + ...
             0.32221113486118586*f13 + ...
             -0.12948458791975614*f14 + ...
             -0.029477447612619417*f15 + ...
             0.04932600711506839*f16;

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
                warning(message('MATLAB:ode89:IntegrationTolNotMet',sprintf( '%e',t ),sprintf( '%e',hmin )));
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
        [f17,f18,f19,f20,f21,nfevals] = ...
            computeCEStages(ode,t,y,h,f1,f8,f9,f10,f11,f12,f13,f14,f15,nfevals,odeArgs);
        haveCEStages = true;
        f = [f1,f8,f9,f10,f11,f12,f13,f14,f15,f17,f18,f19,f20,f21];
        [te,ye,ie,valt,stop] = ...
            odezero(@ntrp89,eventFcn,eventArgs,valt,t,y,tnew,ynew,t0,h,f,idxNonNegative);
        if ~isempty(te)
            if output_sol || (nargout > 2)
                teout = [teout,te];
                yeout = [yeout,ye];
                ieout = [ieout,ie];
            end
            if stop
                % Stop on a terminal event.
                done = true;
                tnew = te(end);
                ynew = ye(:,end);
                hnew = tnew - t;
                % Interpolate to update stages for the closer end point.
                taux = t + [ ...
                    0.64, ... % for f8
                    0.48, ... % for f9
                    0.06754, ... % for f10
                    0.25, ... % for f11
                    0.6770920153543243, ... % for f12
                    0.8115, ... % for f13
                    0.906, ... % for f14
                    1, ... % for f15 and f17
                    0.7421010083583088, ... % for f18
                    0.888, ... % for f19
                    0.696, ... % for f20
                    0.487 ... % for f21
                    ]*hnew;
                [~,ftmp] = ntrp89(taux,t,y,[],[],h,f,idxNonNegative);
                f8 = ftmp(:,1);
                f9 = ftmp(:,2);
                f10 = ftmp(:,3);
                f11 = ftmp(:,4);
                f12 = ftmp(:,5);
                f13 = ftmp(:,6);
                f14 = ftmp(:,7);
                f15 = ftmp(:,8);
                f17 = ftmp(:,8);
                f18 = ftmp(:,9);
                f19 = ftmp(:,10);
                f20 = ftmp(:,11);
                f21 = ftmp(:,12);
                h = hnew;
            end
        end
    end

    if output_sol
        nout = nout + 1;
        tout(nout) = tnew;
        yout(:,nout) = ynew;
        if ~haveCEStages
            [f17,f18,f19,f20,f21,nfevals] = computeCEStages( ...
                ode,t,y,h,f1,f8,f9,f10,f11,f12,f13,f14,f15,nfevals,odeArgs);
            haveCEStages = true;
        end
        f3d(:,1,nout) = f1;
        f3d(:,2,nout) = f8;
        f3d(:,3,nout) = f9;
        f3d(:,4,nout) = f10;
        f3d(:,5,nout) = f11;
        f3d(:,6,nout) = f12;
        f3d(:,7,nout) = f13;
        f3d(:,8,nout) = f14;
        f3d(:,9,nout) = f15;
        f3d(:,10,nout) = f17;
        f3d(:,11,nout) = f18;
        f3d(:,12,nout) = f19;
        f3d(:,13,nout) = f20;
        f3d(:,14,nout) = f21;
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
                    [f17,f18,f19,f20,f21,nfevals] = computeCEStages( ...
                        ode,t,y,h,f1,f8,f9,f10,f11,f12,f13,f14,f15,nfevals,odeArgs);
                    % HAVECEStages = true;
                end
                yntrp89 = ntrp89split(tref,t,y,h, ...
                    f1,f8,f9,f10,f11,f12,f13,f14,f15,f17,f18,f19,f20,f21, ...
                    idxNonNegative);
                yout_new = [yntrp89,ynew];
            case 1 % output only at tspan points
                nout_new = 0;
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
                            [f17,f18,f19,f20,f21,nfevals] = computeCEStages( ...
                                ode,t,y,h,f1,f8,f9,f10,f11,f12,f13,f14,f15,nfevals,odeArgs);
                            haveCEStages = true;
                        end
                        yntrp89 = ntrp89split(tspan(next),t,y,h, ...
                            f1,f8,f9,f10,f11,f12,f13,f14,f15,f17,f18,f19,f20,f21, ...
                            idxNonNegative);
                        yout_new = [yout_new,yntrp89];
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

function [f17,f18,f19,f20,f21,nfevals] = computeCEStages( ...
    ode,t,y,h,f1,f8,f9,f10,f11,f12,f13,f14,f15,nfevals,odeArgs)
% Compute stages for the order 8 continuous extension.
% CE for the 8th order CE "most robust" pair.

ystage = y + h*( ...
    0.014588852784055396*f1 + ...
    0.0020241978878893325*f8 + ...
    0.21780470845697167*f9 + ...
    0.12748953408543898*f10 + ...
    0.2244617745463132*f11 + ...
    0.1787254491259903*f12 + ...
    0.07594344758096558*f13 + ...
    0.12948458791975614*f14 + ...
    0.029477447612619417*f15);
f17 = ode(t + h,ystage,odeArgs{:});

ystage = y + h*( ...
    0.015601405261088616*f1 + ...
    0.26811643933275847*f8 + ...
    0.1883053124587791*f9 + ...
    0.12491991374610308*f10 + ...
    0.2302302127814522*f11 + ...
    -0.13603122161327985*f12 + ...
    0.07488659971306953*f13 + ...
    -0.02812840029795629*f14 + ...
    -0.023144557264819496*f15 + ...
    0.027345304241113474*f17);
f18 = ode(t + 0.7421010083583088*h,ystage,odeArgs{:});

ystage = y + h*( ...
    0.013111957218440684*f1 + ...
    -0.1464024265969827*f8 + ...
    0.2471264389666796*f9 + ...
    0.13113752030800324*f10 + ...
    0.21705603469825827*f11 + ...
    0.286753671376032*f12 + ...
    0.02323311339149422*f13 + ...
    0.05250677264199396*f14 + ...
    0.0028339515860099506*f15 + ...
    -0.008502403851995712*f17 + ...
    0.06914537026206649*f18);
f19 = ode(t + 0.888*h,ystage,odeArgs{:});

ystage = y + h*( ...
    0.013989212133617684*f1 + ...
    -0.031574065179505*f8 + ...
    0.2271812513272158*f9 + ...
    0.12894864109967866*f10 + ...
    0.2216682589135277*f11 + ...
    0.19483682365424806*f12 + ...
    0.05740088404417653*f13 + ...
    0.09008366542675955*f14 + ...
    0.015791532088442122*f15 + ...
    -0.018991315059091858*f17 + ...
    -0.08830926811918835*f18 + ...
    -0.11502562032988092*f19);
f20 = ode(t + 0.696*h,ystage,odeArgs{:});

ystage = y + h*( ...
    0.016151472919007624*f1 + ...
    0.08098685003242906*f8 + ...
    0.12769162943069304*f9 + ...
    0.12348143593834805*f10 + ...
    0.233985125914011*f11 + ...
    -0.06595995683357368*f12 + ...
    -0.02565276859406433*f13 + ...
    -0.1258973463819247*f14 + ...
    -0.04307672490364844*f15 + ...
    0.04973042479196705*f17 + ...
    0.10004735401793927*f18 + ...
    0.13786588067636232*f19 + ...
    -0.12235337700754625*f20);
f21 = ode(t + 0.487*h,ystage,odeArgs{:});

nfevals = nfevals + 5;

%--------------------------------------------------------------------------
