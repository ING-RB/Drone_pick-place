% Internal Only
% matlab.ode.internal.DESolver: used with backend for DESuite based
% solvers such as SUNDIALS

%    Copyright 2023-2025 MathWorks, Inc.

classdef DESolver < matlab.ode.internal.Solver

    properties
        problem matlab.ode.internal.DEProblem % MATLAB interface to DESuite solver
        sol % solution cache struct
        ParametersCell
        EventDefinition
        ode
    end

    properties(Access=private)
        GenericParameters (1,1) logical = false;
    end

    methods

        function obj = DESolver(ODE)
            arguments
                ODE ode
            end
            obj.ode = ODE;
            obj.ID = ODE.SelectedSolver;
            obj.TMax = ODE.InitialTime;
            [obj.problem,obj.ParametersCell,obj.GenericParameters,...
                obj.EventDefinition] = obj.packageProblem(ODE);
        end

        function [t,y,te,ye,ie,s,se] = solve(obj,t1,t2,pps)
            if nargin < 4
                pps = 1;
            end
            t0 = obj.problem.StartTime;
            obj.problem.Refine = pps;
            isAtEnd = nargin < 3 && isscalar(t1);
            if isAtEnd && t1 == t0
                % Solution requested at IC, don't solve
                t = t0;
                y = obj.problem.InitialStates(:);
                if nargout >= 3
                    te = zeros(0,1,'like',t);
                    ye = zeros(numel(y),0,'like',y);
                    ie = zeros(0,1);
                end
                if nargout >= 6
                    s = obj.problem.InitialSensitivity(:);
                    se = zeros(numel(y)*numel(obj.problem.InitialInputs),0);
                end
                return
            end
            if nargin < 3 && ~isscalar(t1) % requested solver steps
                tspan = t1(:).';
                if any(isinf(tspan)) && isempty(obj.problem.InitialStepSize)
                    obj = manualStepSizeGuess(obj,tspan);
                end
                obj.problem.StopTime = tspan(end);
                [~,ss] = solveLoop(obj,tspan);
                [t,y,te,ye,ie,s,se] = unpackSolStruct(ss);
                % solver may return logged events as part of output if
                % solve was called, so remove.
                if ~isempty(t) && ~ismember(t(end),tspan)
                    y(:,end) = NaN;
                end
                if ~isequal(t,t1)
                    % requested solver steps, but the solver returned early
                    % convention is to fill in nans for values not reached.
                    t = t1;
                    y(:,end+1:numel(t)) = nan;
                    s(:,end+1:numel(t)) = nan;
                end
            elseif nargin < 3 && isscalar(t1)
                % solve should return just the value at the endpoint
                tspan = [t0 t1];
                obj.problem.StopTime = t1;
                if any(isinf(tspan)) && isempty(obj.problem.InitialStepSize)
                    obj = manualStepSizeGuess(obj,tspan);
                end
                [~,ss] = solveLoop(obj,tspan);
                [t,y,te,ye,ie,s,se] = unpackSolStruct(ss);
                % only return last element
                t(1:end-1) = [];
                y(:,1:end-1) = [];
                s(:,1:end-1) = [];
            else % natural solver steps
                assert(t1(1) == obj.problem.StartTime);
                obj.problem.StopTime = t2;
                if any(isinf([t1 t2])) && isempty(obj.problem.InitialStepSize)
                    obj = manualStepSizeGuess(obj,[t0 t2]);
                end
                [~,ss] = solveLoop(obj);
                [t,y,te,ye,ie,s,se] = unpackSolStruct(ss);
            end
            t = t.'; % consistency with ODE
            te = te.';
            ie = ie.';
        end

        function [obj,tfarthest] = extend(obj,t)
            t0 = obj.problem.StartTime;
            if isempty(obj.sol)
                tfarthest = t0;
            else
                tfarthest = getTFarthest(obj.sol.x,t0);
            end
            % extend updates solution cache, must be compatible with deval
            % so turn on derivative computations for Hermite interpolation.
            obj.problem.ComputeIData = true;
            if nargin == 1 || t == t0
                % intentionally empty, no work to do
            elseif isempty(obj.sol)
                % if no cache, run solver to t
                obj.problem.StopTime = t;
                obj = extendLoop(obj,t);
                tfarthest = getTFarthest(obj.sol.x,tfarthest);
            elseif tfarthest < t0 && t < tfarthest ...
                    || tfarthest > t0 && t > tfarthest
                % if t is outside of the current range, run solver
                obj.problem.StopTime = t;
                obj.problem.StartTime = tfarthest; % start solver at end of cache
                obj.problem.InitialStates = obj.sol.y(:,end).';
                obj = extendLoop(obj,t);
                tfarthest = getTFarthest(obj.sol.x,tfarthest);
            end
            obj.TMax = tfarthest;
        end

        function [obj,y,yp] = evaluate(obj,t,idx)
            if nargin < 3
                % set idx to everything if not provided
                idx = 1:numel(obj.problem.InitialStates);
            end
            if isempty(t)
                y = zeros(numel(idx),0,'like',obj.problem.InitialStates);
                yp = y;
                return
            end
            if nargout == 3
                [y,yp] = deval(obj.sol,t,idx);
            else
                y = deval(obj.sol,t,idx);
            end
        end

        function [t,y,te,ye,ie,s,se] = getCachedSolution(obj)
            te = zeros(0,1,'like',obj.problem.StartTime);
            ye = zeros(numel(obj.problem.InitialStates),...
                0,'like',obj.problem.InitialStates);
            ie = zeros(0,1);
            % return stacked, ode must reshape
            s = zeros(size(obj.problem.InitialSensitivity,1)*...
                size(obj.problem.InitialSensitivity,2),0);
            se = s;
            if isempty(obj.sol)
                t = obj.problem.StartTime;
                y = obj.problem.InitialStates(:);
                s = obj.problem.InitialSensitivity(:);
            elseif obj.TMax >= obj.problem.StartTime
                t = obj.sol.x(:);
                y = obj.sol.y;
                te = obj.sol.te(:);
                ye = obj.sol.ye;
                ie = obj.sol.ie(:);
                s = obj.sol.s;
                se = obj.sol.se;
            else
                t = flip(obj.sol.x(:),1);
                y = flip(obj.sol.y,2);
                te = flip(obj.sol.te(:),1);
                ye = flip(obj.sol.ye,2);
                ie = flip(obj.sol.ie(:),1);
                s = flip(obj.sol.s,2);
                se = flip(obj.sol.se,2);
            end
        end

    end

    methods(Static)
        function [problem,ParametersCell,GenericParameters,...
                EventDefinition] = packageProblem(ODE)
            problem = matlab.ode.internal.DEProblem;
            % let DESuite handle numeric parameters, otherwise, we need to
            % bind them to the ODEFcn handle
            GenericParameters = false;
            if (isnumeric(ODE.Parameters) && isvector(ODE.Parameters))
                problem.InitialInputs = ODE.Parameters(:);
                problem.TypicalParameters = problem.InitialInputs;
                ParametersCell = {ODE.Parameters};
            elseif isempty(ODE.Parameters)
                ParametersCell = {[]};
            else
                GenericParameters = true;
                ParametersCell = {ODE.Parameters};
            end
            if nargin(ODE.ODEFcn) < 3
                problem.DEFun = @(t,y,~) ODE.ODEFcn(t,y);
            elseif GenericParameters
                problem.DEFun = @(t,y,~) ODE.ODEFcn(t,y,ParametersCell{:});
            else
                problem.DEFun = ODE.ODEFcn;
            end
            problem.StartTime = ODE.InitialTime;
            problem.InitialStates = ODE.InitialValue.';
            problem.AbsTol = ODE.AbsoluteTolerance;
            problem.RelTol = ODE.RelativeTolerance;
            if ~isempty(ODE.NonNegativeVariables)
                problem.NonNegative = ODE.NonNegativeVariables;
            end
            problem = unpackSolverOptionsDE(problem,ODE.SolverOptions);
            problem = setMassDE(problem,ODE,ParametersCell,GenericParameters);
            problem = setJacobianDE(problem,ODE,ParametersCell,GenericParameters);
            [problem,EventDefinition] = setEventsDE(problem,ODE,ParametersCell,GenericParameters);
            problem = setSensitivityDE(problem,ODE,ParametersCell,GenericParameters);
            solType = double(ODE.SelectedSolver);
            if solType == 10 || solType == 11 % CVODES solvers
                % obj.problem.SolverName = 'CVODES'; % default
                problem.IsStiff = solType == 10; % cvodesStiff
                if ~isempty(ODE.MassMatrix) && ~isempty(ODE.MassMatrix.MassMatrix)
                    error(message("MATLAB:ode:CVODESMass",string(ODE.SelectedSolver)))
                end
                % no mass, indicate that the problem is not a DAE to avoid
                % checks
                problem.isDAE = false;
            else
                problem.SolverName = 'IDAS';
            end
        end
    end

    methods(Access=private, Hidden)
        function [obj,sol] = solveLoop(obj,tspan)
            % function to call solver and handle event callback logic.
            if nargin < 2
                % empty tspan indicates solver steps
                tspan = [];
                keepICs = true;
            else
                keepICs = false; % only keep requested steps with events
            end
            sim = matlab.ode.internal.DESimulator(obj.problem);
            % first run with info set up in solve
            sol = run(sim,tspan);
            % Enter event loop if 1. not at end of interval 2. event
            % occurred and 3. integration was stopped due to an event.
            if ~isempty(sol.x) && obj.problem.StopTime ~= sol.x(end) && ...
                    ~isempty(sol.ie) && sol.te(end) == sol.x(end)
                stop = false;
                GOLEFT = sim.MyProblem.StopTime < sim.MyProblem.StartTime;
                while ~stop && sol.x(end) ~= sim.MyProblem.StopTime
                    obj.sol = sol;
                    [obj,sim,stop,telast] = processEventCallback(obj,sim);
                    if stop
                        break;
                    end
                    if ~isempty(tspan)
                        % when requesting solver steps and there was an
                        % event, purify tspan so steps are after event.
                        tspan = updateTSpan(tspan,telast,GOLEFT);
                    end
                    sol1 = run(sim,tspan);
                    sol = obj.concatSolStructs(sol,sol1,keepICs);
                end
            end
        end

        function obj = extendLoop(obj,t)
            % function to extend the solution if the user has provided
            % event based callbacks
            t0 = obj.problem.StartTime;
            GOLEFT = t < t0;
            GORIGHT = t > t0;
            [obj,sim] = runSolverAndUpdateCache(obj);
            tfarthest = getTFarthest(obj.sol.x,t0);
            while (GOLEFT && t < tfarthest || GORIGHT && t > tfarthest) && ...
                    ~isempty(obj.EventDefinition)
                [obj,sim,stop] = processEventCallback(obj,sim);
                if stop
                    break
                end
                [obj,sim] = runSolverAndUpdateCache(obj,sim);
                tfarthest = getTFarthest(obj.sol.x,tfarthest);
            end
            obj.TMax = tfarthest;
        end

        function [obj,sim,stop,telast] = processEventCallback(obj,sim)
            % Executes the callback function for an event to determine if
            % integration should stop and to update parameters if
            % necessary. If an event occurred and parameters change as a
            % result, updates parameters and simulator.
            event = obj.EventDefinition;
            [stop,telast,yelast,ielast] = event.getCallbackInfo(...
                obj.sol.te,obj.sol.ye,obj.sol.ie);
            if ~stop
                [stop,y0,p] = event.execCallbackFcn(...
                    telast,yelast,ielast,obj.ParametersCell{:});
                % reset solver to start at time of last event
                if ~isempty(p)
                    obj.ParametersCell = {p};
                    if obj.GenericParameters
                        % must rebind to each function handle if defined
                        obj = rebindParameters(obj);
                        obj.problem.InitialStates = y0;
                        obj.problem.StartTime = telast;
                        sim = matlab.ode.internal.DESimulator(obj.problem);
                    else
                        obj.problem.InitialInputs = p;
                        sim = reset(sim,telast,y0,p);
                    end
                else
                    sim = reset(sim,telast,y0);
                end
            end
        end

        function sol = concatSolStructs(~,sol,nsol,keepICs)
            % concatenate two solver structs. Note, keepICs should be true
            % for tspan and false for solver steps to avoid repeating
            % the steps
            start = 1;
            if ~keepICs
                start = 2;
            end
            sol.x = [sol.x(1:end-1) nsol.x(start:end)];
            sol.y = [sol.y(:,1:end-1) nsol.y(:,start:end)];
            sol.te = [sol.te nsol.te];
            sol.ye = [sol.ye nsol.ye];
            sol.ie = [sol.ie nsol.ie];
            sol.s = [sol.s(:,1:end-1) nsol.s(:,start:end)];
            sol.se = [sol.se nsol.se];
        end

        function [obj,sim] = runSolverAndUpdateCache(obj,sim)
            % helper to emulate odextend for DESuite based solvers. Caller
            % has already set ICs and stop time. This should run and update
            % the cache - if empty, just assign, if not empty, append to
            % end of cache.
            if nargin < 2
                sim = matlab.ode.internal.DESimulator(obj.problem);
            end
            nsol = run(sim);
            if isempty(obj.sol)
                obj.sol = nsol;
                % add interpolation data where deval expects to find it
                obj.sol.idata.yp = obj.sol.yp;
                % set solver type for deval
                obj.sol.solver = 'sundials';
                if ~isempty(obj.problem.NonNegative)
                    obj.sol.idata.idxNonNegative = obj.problem.NonNegative;
                end
            else % sol cache already exists
                % note, nsol has ICs equal to obj.sol's end points, so
                % exclude
                obj.sol.x = [obj.sol.x(1:end-1) nsol.x];
                obj.sol.y = [obj.sol.y(:,1:end-1) nsol.y];
                obj.sol.te = [obj.sol.te nsol.te];
                obj.sol.ye = [obj.sol.ye nsol.ye];
                obj.sol.ie = [obj.sol.ie nsol.ie];
                obj.sol.s = [obj.sol.s(:,1:end-1) nsol.s];
                obj.sol.se = [obj.sol.se nsol.se];
                obj.sol.idata.yp = [obj.sol.idata.yp(:,1:end-1) nsol.yp];
            end
        end

        function obj = manualStepSizeGuess(obj,tspan)
            % SUNDIALS solvers have mechanism to guess optimal first time
            % step, but don't handle inf inputs. This is called in that
            % case to set a guess for the first time step.
            t0 = tspan(1);
            threshold = obj.problem.AbsTol ./ obj.problem.RelTol;
            y = obj.problem.InitialStates;
            yp = obj.problem.DEFun(t0,y,obj.problem.InitialInputs);
            wt = max(abs(y),threshold);
            rh = 1.25 * norm(yp ./ wt,inf) / sqrt(obj.problem.RelTol);
            obj.problem.InitialStepSize = sign(tspan(2)-tspan(1))/rh;
        end

        function obj = rebindParameters(obj)
            % Bind ParametersCell to function handles that depend on
            % generic parameters
            pcell = obj.ParametersCell;
            obj.problem.DEFun = bindFunction(obj.ode.ODEFcn,pcell);
            if ~isempty(obj.problem.JacobianFun)
                obj.problem.JacobianFun = bindFunction(obj.ode.Jacobian.Jacobian,pcell);
            end
            if ~isempty(obj.problem.TriggerFun)
                E = obj.EventDefinition;
                obj.problem.TriggerFun = bindFunction(@E.evaluateStandard,pcell);
            end
            if ~isempty(obj.problem.MassFun)
                if isequal(string(obj.ode.MassMatrix.StateDependence),"none")
                    obj.problem.MassFun = @(t) obj.ode.MassMatrix.MassMatrix(t,obj.ParametersCell{:});
                else
                    obj.problem.MassFun = @(t,y,~) obj.ode.MassMatrix.MassMatrix(t,y,obj.ParametersCell{:});
                end
            end
        end

    end

end

function [t,y,te,ye,ie,s,se] = unpackSolStruct(sol)
t = sol.x;
y = sol.y;
te = sol.te;
ye = sol.ye;
ie = sol.ie;
s = sol.s;
se = sol.se;
end

function tspan = updateTSpan(tspan,telast,GOLEFT)
% Update tspan to request steps only beyond current
% integration point.
if GOLEFT
    tspan = tspan(tspan < telast);
else
    tspan = tspan(tspan > telast);
end
% keep ICs consistent with where event happened by
% adding the event location to tspan to start
% integration
tspan = [telast tspan];
end

function tf = getTFarthest(t,t0)
if isempty(t)
    tf = t0;
else
    tf = t(end);
end
end

function problem = unpackSolverOptionsDE(problem,opts)
% unpack the SolverOptions class to relevant properties of the
% problem class
problem.MaxStep = opts.MaxStep;
problem.InitialStepSize = opts.InitialStep;
problem.MaxOrder = opts.MaxOrder;
end

function problem = setMassDE(problem,ODE,ParametersCell,GenericParameters)
% function to unpack a mass matrix object into the
% relevant parameters of the desuite problem class
% Functions may have signatures M(t), M(t,y), and M(t,y,p).
% NOTE: mass functions are allowed to vary nargin
if isempty(ODE.MassMatrix)
    return;
end
if ~isempty(ODE.NonNegativeVariables)
    warning(message('MATLAB:ode:MassAndNonneg'));
    problem.NonNegative = [];
end
if isa(ODE.MassMatrix.MassMatrix,'function_handle')
    if GenericParameters
        if isequal(string(ODE.MassMatrix.StateDependence),"none")
            problem.MassFun = @(t,~) ODE.MassMatrix.MassMatrix(t,ParametersCell{:});
        else
            problem.MassFun = @(t,y,~) ODE.MassMatrix.MassMatrix(t,y,ParametersCell{:});
        end
    else
        if isequal(string(ODE.MassMatrix.StateDependence),"none") && ...
                ~isempty(ODE.Parameters) && nargin(ODE.MassMatrix.MassMatrix) > 1
            % Special case for M(t,p)
            problem.MassFun = @(t,~,p) ODE.MassMatrix.MassMatrix(t,p);
        else
            problem.MassFun = ODE.MassMatrix.MassMatrix;
        end
    end
else
    problem.MassMatrix = ODE.MassMatrix.MassMatrix;
end
mvpat = ODE.MassMatrix.SparsityPattern;
if ~isempty(mvpat)
    problem.MvPattern = mvpat;
end
if ~isempty(ODE.MassMatrix.StateDependence) ...
        && ODE.MassMatrix.StateDependence == "strong"
    problem.MStateDependence = true;
end
% Singular can also be "maybe". Do nothing in that case, and
% the solver will check if the equation is a DAE.
if ODE.MassMatrix.Singular == "yes"
    problem.isDAE = true;
elseif ODE.MassMatrix.Singular == "no"
    problem.isDAE = false;
end
% set initial slope only in cases where a mass matrix is used.
problem.InitialSlope = ODE.InitialSlope(:);
end

function problem = setJacobianDE(problem,ODE,ParametersCell,GenericParameters)
% function to unpack a Jacobian object into the
% relevant parameters of the desuite problem class
if isempty(ODE.Jacobian)
    return;
end
if isa(ODE.Jacobian.Jacobian,'function_handle')
    if nargin(ODE.Jacobian.Jacobian) < 3
        J = @(t,y,~) ODE.Jacobian.Jacobian(t,y);
    elseif GenericParameters
        J = @(t,y,~) ODE.Jacobian.Jacobian(t,y,ParametersCell{:});
    else
        J = ODE.Jacobian.Jacobian;
    end
    problem.JacobianFun = J;
    return; % early return, don't set sparsity pattern if it won't be used
else % Jacobian is empty or constant
    problem.JacobianMatrix = ODE.Jacobian.Jacobian;
end
jpat = ODE.Jacobian.SparsityPattern;
if ~isempty(jpat)
    problem.JPattern = jpat;
end
end

function [problem,EventDefinition] = setEventsDE(problem,ODE,ParametersCell,GenericParameters)
% function to unpack an events object into the
% relevant parameters of the desuite problem class
if isempty(ODE.EventDefinition)
    EventDefinition = [];
    return;
end
E = ODE.EventDefinition;
EventDefinition = E;
% trigger fun definition
if isempty(E.EventFcn) || nargin(E.EventFcn) < 3
    EFcn = @(t,y,~) E.evaluateStandard(t,y);
elseif GenericParameters
    EFcn = @(t,y,~) E.evaluateStandard(t,y,ParametersCell{:});
else
    EFcn = @(t,y,p) E.evaluateStandard(t,y,p);
end
problem.TriggerFun = EFcn;
% direction
problem.TriggerDir = double(E.Direction);
% at event
if E.Response == "proceed"
    problem.AtEvent = 0;
else
    problem.AtEvent = 1;
end
end

% Keep arguments same for "set*" methods, but Parameters must not be
% generic here, hence ParametersCell is never used.
function problem = setSensitivityDE(problem,ODE,~,GenericParameters)
if isempty(ODE.Sensitivity)
    return;
end
if GenericParameters
    error(message("MATLAB:ode:SenseNumParam"));
end
if isempty(problem.InitialInputs)
    error(message("MATLAB:ode:SenseParamEmpty"));
end
S = ODE.Sensitivity;
if any(S.ParameterIndices > numel(ODE.Parameters))
    error(message("MATLAB:ode:SenseBadParamIndex"));
end
problem.SensitivityIndices = sort(unique(S.ParameterIndices));
problem.InitialSensitivity = S.InitialValue;
problem.InitialSensitivitySlope = S.InitialSlope;
if isempty(problem.InitialSensitivity)
    % fill in default value if nothing is supplied
    if ~isempty(S.ParameterIndices)
        numSens = numel(S.ParameterIndices);
    else
        numSens = numel(ODE.Parameters);
    end
    problem.InitialSensitivity = zeros(numel(ODE.InitialValue),numSens);
end
SJ = S.Jacobian;
if ~isempty(SJ) && ~isempty(SJ.Jacobian)
    if isnumeric(SJ.Jacobian)
        problem.SensitivityJacobianMatrix = SJ.Jacobian;
    else % function handle
        if nargin(SJ.Jacobian) < 3
            J = @(t,y,~) SJ.Jacobian(t,y);
        else
            J = SJ.Jacobian;
        end
        problem.SensitivityJacobianFun = J;
    end
    return % early return, don't set sparsity pattern
end
if ~isempty(SJ) && ~isempty(SJ.SparsityPattern)
    problem.SensitivityJPattern = SJ.SparsityPattern;
end
end

function fout = bindFunction(fin,paramcell)
% helper for ensuring that the signature of a function handle is correct,
% accounting for number of inputs and whether the problem is implicit
nin = nargin(fin);
if nin < 3 && nin > 0
    fout = @(t,y,~) fin(t,y);
elseif ~isempty(paramcell)
    fout = @(t,y,~) fin(t,y,paramcell{:});
else
    fout = @(t,y,p) fin(t,y,p);
end
end