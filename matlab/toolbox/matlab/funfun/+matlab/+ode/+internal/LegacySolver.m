%matlab.ode.internal.LegacySolver  Solver object to use existing MATLAB ODE solvers.

%    Copyright 2023-2024 MathWorks, Inc.

classdef LegacySolver < matlab.ode.internal.Solver
    properties (Access = private)
        SolverFcn
        Options
        UsesParameters = false
        ODEFcn
        InitialTime
        InitialValue
        ParametersCell
        EventDefinition
        DelayDefinition
        UserSuppliedInitialStep
        IsImplicit = false
        sol
        NeedSolStruct
    end
    methods
        function obj = LegacySolver(ODE)
            arguments
                ODE ode
            end
            [obj.ODEFcn,obj.Options,obj.InitialTime,obj.InitialValue,...
                obj.ParametersCell,obj.IsImplicit,obj.DelayDefinition] ...
                = obj.packageProblem(ODE);
            obj.ID = ODE.SelectedSolver;
            obj.SolverFcn = str2func(char(obj.ID));
            obj.UsesParameters = ODE.usesParameters;
            obj.EventDefinition = ODE.EventDefinition;
            obj.TMax = ODE.InitialTime;
            obj.UserSuppliedInitialStep = ~isempty(obj.Options.InitialStep);
            obj.NeedSolStruct = ~isempty(obj.DelayDefinition);
        end
        function [obj,tfarthest] = extend(obj,t)
            % Extend the internal solution cache to t, if possible.
            % Returns the actual farthest point reached, which might not be
            % all the way to the input value in the case of terminal events
            % or integration failures. The solver is only required to
            % extend on one direction, either t > t0 or t < t0, never both
            % in the same instance.
            if isempty(obj.sol)
                tfarthest = obj.InitialTime;
            else
                tfarthest = obj.sol.x(end);
            end
            % We don't support OutputFcn with solutionFcn.
            obj.Options.OutputFcn = [];
            obj.Options.OutputSel = [];
            if nargin == 1 || t == obj.InitialTime
                % Nothing to do.
            elseif ~isempty(obj.EventDefinition) && ...
                    any(obj.EventDefinition.Response ~= matlab.ode.EventAction.proceed)
                obj = extendLoop(obj,t);
                tfarthest = obj.sol.x(end);
            elseif isempty(obj.sol)
                obj.sol = obj.runSolver(obj.InitialTime,t);
                tfarthest = obj.sol.x(end);
            elseif (tfarthest < obj.InitialTime && t < tfarthest) || ...
                    (tfarthest > obj.InitialTime && t > tfarthest)
                obj = obj.setInitialStep(obj.sol.x);
                obj = extendsol(obj,t,[]);
                tfarthest = obj.sol.x(end);
            end
            obj.TMax = tfarthest;
        end
        function [obj,y,yp] = evaluate(obj,t,idx)
            % Evaluate using the internal solution cache at time value t,
            % where t can be an array of any size or shape. If not all
            % solution components are needed, the desired components can be
            % supplied in the optional third input. Columns y(:,k) and
            % yp(:,k) are the solution and derivative, respectively, at
            % time t(k). The ODE class will ensure that the solution has
            % been extended to cover the range of t values.
            if isempty(t)
                % DEVAL can't handle empty t.
                if nargin == 3
                    y = zeros(numel(idx),0,"like",obj.InitialValue);
                    yp = y;
                else
                    y = zeros(numel(obj.InitialValue),0,"like",obj.InitialValue);
                    yp = y;
                end
            elseif nargout == 3
                if nargin == 3
                    [y,yp] = deval(obj.sol,t,idx);
                else
                    [y,yp] = deval(obj.sol,t);
                end
            else
                if nargin == 3
                    y = deval(obj.sol,t,idx);
                else
                    y = deval(obj.sol,t);
                end
            end
        end
        function [t,y,te,ye,ie] = solve(obj,t1,t2,pps)
            % Solve at specified points t1 or over an interval [t1,t2].
            HAS_CALLBACK_EVENTS = ~isempty(obj.EventDefinition) && ...
                any(obj.EventDefinition.Response == matlab.ode.EventAction.callback);
            if nargin < 3
                % Solve at specified points.
                if isscalar(t1) && t1 == obj.InitialTime
                    if isfield(obj.Options,"Mass") &&~isempty(obj.Options.Mass)...
                            && ~strcmp(obj.Options.MassSingular,"no")
                        error(message("MATLAB:ode:NotEnoughPointsWithSingularMass"));
                    end
                    t = obj.InitialTime;
                    y = obj.InitialValue;
                    if nargout >= 3
                        te = zeros(0,1,"like",t);
                        ye = zeros(numel(y),0,"like",y);
                        ie = zeros(0,1);
                    end
                elseif HAS_CALLBACK_EVENTS
                    [t,y,te,ye,ie] = obj.eventLoopSpecifiedTimes(t1);
                elseif nargout < 3
                    [~,t,y] = obj.solveAt(t1);
                else
                    [~,t,y,te,ye,ie] = obj.solveAt(t1);
                end
                % If integration failure or event stoppage, fill out t with
                % missing abscissas and pad y with NaNs.
                nt = numel(t);
                if nt < numel(t1)
                    t1 = t1(nt+1:end);
                    t = [t;t1(:)];
                    y = [y,nan(size(y,1),numel(t1))];
                end
            else
                % Solve on interval.
                obj.Options.Refine = pps;
                if HAS_CALLBACK_EVENTS
                    [t,y,te,ye,ie] = eventLoopInterval(obj,t2);
                elseif nargout > 2
                    [~,t,y,te,ye,ie] = solveTo(obj,t2);
                else
                    [t,y] = obj.runSolver(obj.InitialTime,t2);
                    y = y.';
                end
            end
        end
        function [t,y,te,ye,ie] = getCachedSolution(obj)
            te = zeros(0,1,"like",obj.InitialTime);
            ye = zeros(numel(obj.InitialValue),0,"like",obj.InitialValue);
            ie = zeros(0,1);
            if isempty(obj.sol)
                t = obj.InitialTime;
                y = obj.InitialValue;
            elseif obj.TMax >= obj.InitialTime
                t = obj.sol.x(:);
                y = obj.sol.y;
                if isfield(obj.sol,"xe")
                    te = obj.sol.xe(:);
                    ye = obj.sol.ye;
                    ie = obj.sol.ie(:);
                end
            else
                t = flip(obj.sol.x(:),1);
                y = flip(obj.sol.y,2);
                if isfield(obj.sol,"xe")
                    te = flip(obj.sol.xe(:),1);
                    ye = flip(obj.sol.ye,2);
                    ie = flip(obj.sol.ie(:),1);
                end
            end
        end
    end
    methods(Static)
        function [odefun,opts,t0,y0,params,isImplicit,DelayDef] = packageProblem(ODE)
            usesParameters = ODE.usesParameters;
            isImplicit = (ODE.SelectedSolver == matlab.ode.SolverID.ode15i);
            isDelay = ismember(ODE.SelectedSolver, ["dde23" "ddesd" "ddensd"]);
            isNDDE = (ODE.SelectedSolver == matlab.ode.SolverID.ddensd);
            isStandard = ~isImplicit && ~isDelay;
            if isStandard
                nargs = 3;
            elseif isImplicit
                nargs = 4;
            elseif isNDDE
                nargs = 5;
            else
                nargs = 4; 
            end
            odefun = packageFunctionParam(ODE.ODEFcn,nargs,usesParameters);
            t0 = ODE.InitialTime;
            y0 = ODE.InitialValue(:);
            if usesParameters
                params = {ODE.Parameters};
            else
                params = {};
            end
            opts = struct;
            opts.AbsTol = ODE.AbsoluteTolerance(:).';
            opts.RelTol = ODE.RelativeTolerance;
            opts.InitialSlope = ODE.InitialSlope(:);
            opts.InitialStep = ODE.SolverOptions.InitialStep;
            opts.MaxStep = ODE.SolverOptions.MaxStep;
            opts.NonNegative = ODE.NonNegativeVariables;
            if ~ismember(ODE.SelectedSolver,[matlab.ode.SolverID.cvodesstiff,...
                    matlab.ode.SolverID.cvodesNonstiff,matlab.ode.SolverID.idas])
                opts.NormControl = ODE.SolverOptions.NormControl;
                opts = setOutputFcn(opts,ODE,usesParameters);
                opts.OutputSel = ODE.SolverOptions.OutputSelection;
                opts.MinStep = ODE.SolverOptions.MinStep;
            end
            if ODE.SelectedSolver == matlab.ode.SolverID.ode15s
                opts.MaxOrder = ODE.SolverOptions.MaxOrder;
                opts.BDF = ODE.SolverOptions.BDF;
                opts.Vectorized = char(ODE.SolverOptions.Vectorization);
            elseif ODE.SelectedSolver == matlab.ode.SolverID.ode15i
                opts.MaxOrder = ODE.SolverOptions.MaxOrder;
                % Options set up so that vectorized is a cell array.
                opts.Vectorized = cellfun(@char,ODE.SolverOptions.Vectorization,...
                    UniformOutput=false);
            elseif isa(ODE.SolverOptions,"matlab.ode.internal.LegacyStiffSolverOptions")
                opts.Vectorized = char(ODE.SolverOptions.Vectorization);
            end
            opts = setJacobian(opts,ODE,usesParameters,isImplicit);
            opts = setMassMatrix(opts,ODE,usesParameters);
            opts = setEvents(opts,ODE,isImplicit || ~isempty(ODE.DelayDefinition));
            % DelayDefinition is updated to correctly use parameters with
            % function handles
            [DelayDef,opts] = setDelay(opts,ODE,usesParameters);
        end
        function [eqn,opts] = packageProblemForCIC(ODE)
            eqn = packageEqnAsImplicit(ODE);
            opts = packageOptsForCIC(ODE);
        end
    end
    methods (Access = private)
        function obj = setInitialStep(obj,t,isRefined)
            % If the user has not specified an initial step size, and if
            % there are enough elements in t, put a reasonable value in
            % obj.Options.InitialStep.
            if ~obj.UserSuppliedInitialStep
                if nargin < 3
                    rfactor = ones("like",t);
                elseif isRefined
                    rfactor = cast(obj.Options.Refine,"like",t);
                end
                % Clear any initial step sizes we may have introduced
                % before. If we do nothing else, this will result in the
                % default initial step size being used.
                obj.Options.InitialStep = [];
                % Now see if we can provide a larger initial step for
                % the sake of efficiency.
                if numel(t) >= 3
                    h = abs(t(end-1) - t(end-2))*rfactor;
                    if h > 1e5*eps(t(end))
                        obj.Options.InitialStep = h;
                    end
                end
            end
        end
        function [obj,tfarthest] = extendLoop(obj,t)
            % Extend the internal solution cache to t, if possible, in the
            % presence of possible callback events. Returns the actual
            % farthest point reached, which might not be all the way to the
            % input value in the case of terminal events or integration
            % failures. The solver is only required to extend on one
            % direction, either t > t0 or t < t0, never both in the same
            % instance.
            GOINGLEFT = t < obj.InitialTime;
            GOINGRIGHT = t > obj.InitialTime;
            if isempty(obj.sol)
                tfarthest = obj.InitialTime;
            else
                tfarthest = obj.sol.x(end);
            end
            if nargin == 1 || t == obj.InitialTime
                % Nothing to do.
            elseif isempty(obj.sol)
                obj.sol = obj.runSolver(obj.InitialTime,t);
                tfarthest = obj.sol.x(end);
            else
                obj = obj.setInitialStep(obj.sol.x);
                obj = extendsol(obj,t,[]);
                tfarthest = obj.sol.x(end);
            end
            if isfield(obj.sol,"xe")
                te = obj.sol.xe;
                ye = obj.sol.ye;
                ie = obj.sol.ie;
                ne = length(obj.sol.xe);
            else
                te = zeros(1,0,"like",obj.sol.x);
                ye = zeros(size(obj.sol.y,1),0,"like",obj.sol.y);
                ie = zeros(1,0);
                ne = 0;
            end
            while GOINGLEFT && t < tfarthest || GOINGRIGHT && t > tfarthest
                [stop,telast,yelast,ielast] = obj.EventDefinition.getCallbackInfo(te,ye,ie);
                if stop
                    % Stoppage was not caused by a callback event.
                    break
                end
                [stop,obj.InitialValue,p] = obj.EventDefinition.execCallbackFcn( ...
                    telast,yelast,ielast,obj.ParametersCell{:});
                % Update properties.
                obj.InitialTime = telast;
                obj.TMax = tfarthest;
                if ~isempty(obj.ParametersCell)
                    obj.ParametersCell = {p};
                end
                if stop
                    % The callback function told us to stop.
                    break
                end
                obj = obj.setInitialStep(obj.sol.x);
                if ~obj.IsImplicit
                    ic = obj.InitialValue;
                else % implicit
                    % with updated values for the extension, run decic to
                    % be sure that the ICs are consistent
                    ic = zeros(numel(obj.InitialValue),2);
                    [ic(:,1), ic(:,2)] = ...
                        decic(obj.ODEFcn,telast,obj.InitialValue,[],...
                        ic(:,1),[],obj.Options,obj.ParametersCell{:});
                end
                obj = extendsol(obj,t,ic);
                tfarthest = obj.sol.x(end);
                te = obj.sol.xe(ne+1:end);
                ye = obj.sol.ye(:,ne+1:end);
                ie = obj.sol.ie(ne+1:end);
                ne = ne + length(te);
            end
            obj.TMax = tfarthest;
        end
        function [t,y,te,ye,ie] = eventLoopInterval(obj,tfinal)
            % Run the event loop with outputs at solver steps.
            if tfinal < obj.InitialTime
                % Can't really have isnan(t), but can't be too careful.
                tfinalReachedAt = @(t)~(t > tfinal);
            else
                tfinalReachedAt = @(t)~(t < tfinal);
            end
            [obj,t,y,te,ye,ie] = solveTo(obj,tfinal);
            % cast in case t is single but tfinal is double.
            tfinal = cast(tfinal,"like",t);
            while true
                if tfinalReachedAt(t(end))
                    % We're done because the integration reached the
                    % tfinal.
                    break
                end
                [stop,telast,yelast,ielast] = obj.EventDefinition.getCallbackInfo(te,ye,ie);
                if stop
                    % We're done because the stoppage wasn't a callback
                    % event.
                    break
                end
                [stop,obj.InitialValue,p] = obj.EventDefinition.execCallbackFcn( ...
                    telast,yelast,ielast,obj.ParametersCell{:});
                if stop
                    % We're done because the callback function has
                    % instructed us to stop.
                    break
                end
                % Update object properties to start from here.
                obj.InitialTime = telast;
                if ~isempty(obj.ParametersCell)
                    obj.ParametersCell = {p};
                end
                CONTINUOUS = isequal(yelast,obj.InitialValue);
                obj = obj.setInitialStep(t,true);
                obj.TMax = telast;
                [obj,t1,y1,te1,ye1,ie1] = runFromExtension(obj,tfinal);
                if CONTINUOUS && numel(t1) > 1 % if numel t1 == 1, just write in last value
                    % The first element of t1 is telast, which is
                    % already in the t array.
                    t = [t;t1(2:end)]; %#ok<AGROW>
                    % The first column of y1 is already the last column of y.
                    y = [y,y1(:,2:end)]; %#ok<AGROW>
                else
                    t = [t;t1]; %#ok<AGROW>
                    y = [y,y1]; %#ok<AGROW>
                end
                te = [te;te1]; %#ok<AGROW>
                ye = [ye,ye1]; %#ok<AGROW>
                ie = [ie;ie1]; %#ok<AGROW>
            end
        end
        function [t,y,te,ye,ie,sols] = solveOn2(obj,tfinal)
            % Solve at t0 and tfinal. We need this because current solvers
            % don't support scalar tspan inputs, and they return solver
            % steps with two-element tspan inputs. This function calls the
            % solvers with three inputs unless the interval is so small
            % that the points coalesce.
            %
            % This function can be used in an event loop. If the
            % integration is stopped early, whether for failure or terminal
            % event, then the t and y outputs will just be t0 and y0.
            mid = mean([obj.InitialTime,tfinal]);
            if mid == obj.InitialTime || mid == tfinal || ...
                    ~isempty(odeget(obj.Options,'OutputFcn'))
                % Vanishingly small interval will only return endpoints,
                % anyway, and when an output function is used, using a
                % 3-point tspan will change the behavior or the underyling
                % solver.
                tspan = [obj.InitialTime,tfinal];
            else
                tspan = [obj.InitialTime,mid,tfinal];
            end
            sols = [];
            if nargout < 3
                [t,y] = obj.runSolver(tspan,[]);
            elseif nargout == 5
                [t,y,te,ye,ie] = obj.runSolver(tspan,[]);
                ye = ye.';
            else
                [t,y,te,ye,ie,sols] = obj.runSolver(tspan,[]);
                ye = ye.';
            end
            y = y.';
            % cast in case tfinal is double and t is single.
            tfinal = cast(tfinal,"like",t);
            if (tfinal < obj.InitialTime && t(end) > tfinal) || ...
                    (tfinal > obj.InitialTime && t(end) < tfinal)
                t = t(1);
                y = y(:,1);
            else
                t = [t(1);t(end)];
                y = [y(:,1),y(:,end)];
            end
        end
        function [obj,t,y,te,ye,ie] = solveTo(obj,tfinal)
            % Solve on the interval [t0,tfinal].
            if ~obj.NeedSolStruct
                [t,y,te,ye,ie] = obj.runSolver(obj.InitialTime,tfinal);
            else
                [t,y,te,ye,ie,obj.sol] = obj.runSolver(obj.InitialTime,tfinal);
            end
            y = y.';
            ye = ye.';
        end
        function [obj,t,y,te,ye,ie] = solveAt(obj,tspan)
            % Solve at specified points. If the integration is stopped by
            % an integration failure or terminal event, t and y will be
            % shortened to include only the points in tspan that were
            % reached. If there is an early stoppage BETWEEN requested
            % output points, the data at the stoppage point is NOT included
            % included in the t or y output. If the stoppage is due to an
            % event, the data can be found in the event output; otherwise,
            % the solution data at the point of stoppage is lost. This
            % utility can be used in an event loop.
            obj.Options.OutputTY = true; % for DDE solvers
            if numel(tspan) <= 2
                if nargout < 4
                    [t,y] = solveOn2(obj,tspan(end));
                elseif ~obj.NeedSolStruct
                    [t,y,te,ye,ie] = solveOn2(obj,tspan(end));
                else
                    [t,y,te,ye,ie,obj.sol] = solveOn2(obj,tspan(end));
                end
                if isscalar(tspan)
                    if isscalar(t)
                        % didn't reach tspan(end)
                        t = zeros(0,1,"like",t);
                        y = zeros(size(y,1),0,"like",y);
                    else
                        t = t(end);
                        y = y(:,end);
                    end
                end
            else
                if nargout < 4
                    [t,y,stats] = obj.runSolver(tspan,[]);
                elseif ~obj.NeedSolStruct
                    [t,y,te,ye,ie,stats] = obj.runSolver(tspan,[]);
                    ye = ye.';
                else
                    [t,y,te,ye,ie,obj.sol,stats] = obj.runSolver(tspan,[]);
                    ye = ye.';
                end
                y = y.';
                nt = numel(t);
                if tspan(end) < tspan(1) % Going left
                    TRIM1 = stats(7) > tspan(nt); % Last point not requested.
                else % Going right
                    TRIM1 = stats(7) < tspan(nt); % Last point not requested.
                end
                if TRIM1
                    t = t(1:nt-1);
                    y = y(:,1:nt-1);
                end
            end
        end
        function [t,y,te,ye,ie] = eventLoopSpecifiedTimes(obj,tspan)
            % Solve with potential callback events, returning outputs at
            % specified times.
            GOINGLEFT = tspan(end) < obj.InitialTime;
            % isBeyond(a,b) means a comes after b in the integration.
            if GOINGLEFT
                isBeyond = @lt;
            else
                isBeyond = @gt;
            end
            % Make tspan a column vector if it isn't already.
            tspan = tspan(:);
            % Push obj.InitialTime onto tspan if it isn't already there.
            PUSHED_T0 = isscalar(tspan) || (tspan(1) ~= obj.InitialTime);
            if PUSHED_T0
                tspan = [obj.InitialTime;tspan];
            end
            npoints = numel(tspan);
            obj.Options.OutputTY = true; % make sure DDE gives right output
            % Prime the loop. First call to solve.
            [obj,t,y,te,ye,ie] = solveAt(obj,tspan);
            te1 = te;
            ye1 = ye;
            ie1 = ie;
            while true
                if numel(t) == npoints
                    % We're done because we've computed the solution
                    % at all the requested points.
                    break
                end
                [stop,telast,yelast,ielast] = obj.EventDefinition.getCallbackInfo(te1,ye1,ie1);
                if stop
                    % Either there were no events to check, or the
                    % integration didn't stop on a callback event.
                    break
                end
                [stop,obj.InitialValue,p] = obj.EventDefinition.execCallbackFcn( ...
                    telast,yelast,ielast,obj.ParametersCell{:});
                % Update properties.
                obj.InitialTime = telast;
                if ~isempty(obj.ParametersCell)
                    obj.ParametersCell = {p};
                end
                if stop
                    % Callback function has instructed us to halt the
                    % integration.
                    break
                end
                % Remove points already reached, except possibly for tlast
                % itself, if it happens to be a requested output point.
                tspan = tspan(~isBeyond(telast,tspan));
                % If telast is not at the beginning of tspan, we will need
                % to push it on, because that's the new initial time.
                PUSH_TELAST = isBeyond(tspan(1),telast);
                if PUSH_TELAST
                    % Integration restarts from telast, so push it on.
                    tspan = [telast;tspan]; %#ok<AGROW>
                end
                % Integrate from telast.
                obj.TMax = telast;
                [obj,t1,y1,te1,ye1,ie1] = runFromExtension(obj,tspan);
                if PUSH_TELAST
                    % Remove telast from tspan;
                    tspan = tspan(2:end);
                elseif ~isequal(yelast,obj.InitialValue)
                    % We didn't push telast on to tspan because output was
                    % requested at telast. But if the user changed the
                    % value of y at the interface with their callback
                    % function, this is a point of discontinuity, so there
                    % are two answers, a left-hand and right-hand limit. We
                    % return the one closer to the initial time, i.e. we
                    % return yelast. This differs from deval, which returns
                    % an average. However, if we return yelast, the user
                    % should be able to reconstruct the other limit with
                    % their callback function if they need it. If we were
                    % to return an average, rather, it would destroy
                    % information.
                    if GOINGLEFT
                        warning(message("MATLAB:ode:RightLimitReturned",sprintf('%g',telast)));
                    else
                        warning(message("MATLAB:ode:LeftLimitReturned",sprintf('%g',telast)));
                    end
                end
                % t1(1) = tlast. Omit the data at t1(1) and y1(:,1) because
                % either t(end) == tlast, in which case we have this output
                % already, or tlast is not a requested output point.
                t = [t;t1(2:end)]; %#ok<AGROW>
                y = [y,y1(:,2:end)]; %#ok<AGROW>
                te = [te;te1]; %#ok<AGROW>
                ye = [ye,ye1]; %#ok<AGROW>
                ie = [ie;ie1]; %#ok<AGROW>
            end
            if PUSHED_T0
                % Remove the unrequested results at t0.
                t = t(2:end);
                y = y(:,2:end);
            end
        end
        function [obj,t1,y1,te1,ye1,ie1] = runFromExtension(obj,t)
            % function to call from extend loops to call into solver. DDE
            % solvers use extendsol to keep track of history over solution,
            % while ODE solvers just continue with ICs from the last event.
            if ~obj.NeedSolStruct
                if isscalar(t)
                    solvefun = @solveTo;
                else
                    solvefun = @solveAt;
                end
                [~,t1,y1,te1,ye1,ie1] = solvefun(obj,t);
            else
                obj = obj.setInitialStep(obj.sol.x);
                obj = extendsol(obj,t,obj.InitialValue);
                [t1,y1,te1,ye1,ie1] = unpackSolStruct(obj.sol,true);
                y1 = y1.';
                ye1 = ye1.';
                % if at end of interval, remove final events to avoid
                % double counting
                if t1(end) == t(end) && te1 ~= t(end)
                    te1 = []; ye1 = []; ie1= [];
                end
            end
        end
        function obj = extendsol(obj,t,y0)
            % Method to extend. Most solvers have odextend, but the DDE
            % solvers extend via the solver function itself
            p = obj.ParametersCell(:)';
            if isempty(obj.DelayDefinition)
                obj.sol = odextend(obj.sol,obj.ODEFcn,t,y0,obj.Options, ...
                    obj.ParametersCell{:});
            elseif obj.ID == matlab.ode.SolverID.ddensd
                obj.Options.InitialY = y0;
                obj.sol = obj.SolverFcn(obj.ODEFcn, obj.DelayDefinition.ValueDelay, ...
                    obj.DelayDefinition.SlopeDelay, obj.sol, ...
                    [obj.TMax ; t], obj.Options, p{:});
            else
                obj.Options.InitialY = y0;
                obj.sol = obj.SolverFcn(obj.ODEFcn, obj.DelayDefinition.ValueDelay, ...
                    obj.sol, [obj.TMax ; t], obj.Options, p{:});
            end
        end
        function varargout = runSolver(obj,t1,t2)
            % helper function that packages info and from LegacySolver
            % class as an argument list to pass to solver
            tspan = [t1,t2];
            nout = nargout;
            p = obj.ParametersCell(:)';
            if obj.IsImplicit
                [varargout{1:nout}] = obj.SolverFcn(obj.ODEFcn,tspan, ...
                    obj.InitialValue, obj.Options.InitialSlope, ...
                    obj.Options, p{:});
            elseif ~isempty(obj.DelayDefinition) ...
                    && (obj.ID == matlab.ode.SolverID.ddensd)
                if isfield(obj.Options,"Refine") && obj.Options.Refine ~= 1
                    obj.Options.OutputTY = true; % request special output
                end
                history = obj.DelayDefinition.History;
                if isempty(history)
                    % used for IVP
                    history = obj.Options.History;
                end
                out = obj.SolverFcn(obj.ODEFcn, obj.DelayDefinition.ValueDelay, ...
                        obj.DelayDefinition.SlopeDelay, history, ... 
                        tspan, obj.Options, p{:});
                if nout > 1
                    [varargout{1:nout}] = unpackSolStruct(out);
                else
                    varargout{1} = out;
                end
            elseif ~isempty(obj.DelayDefinition) % dde23 or ddesd
                if isfield(obj.Options,"Refine") && obj.Options.Refine ~= 1
                    obj.Options.OutputTY = true; % request special output
                end
                out = obj.SolverFcn(obj.ODEFcn, obj.DelayDefinition.ValueDelay, ...
                            obj.DelayDefinition.History, tspan, obj.Options, p{:});
                if nout > 1
                    [varargout{1:nout}] = unpackSolStruct(out);
                else
                    varargout{1} = out;
                end
            else % standard
                [varargout{1:nout}] = obj.SolverFcn(obj.ODEFcn, tspan, ...
                    obj.InitialValue, obj.Options, p{:});
            end
        end
    end
end

% Helpers for setting up options object for LegacySolver
function opts = setJacobian(opts,ODE,useParam,isImplicit)
    if isempty(ODE.Jacobian)
        return
    else
        if isa(ODE.Jacobian.Jacobian,'function_handle')
            nArgs = nargin(ODE.Jacobian.Jacobian);
            if ~isImplicit && nArgs < 3 && useParam
                J = @(t,y,~)ODE.Jacobian.Jacobian(t,y);
            elseif isImplicit && nArgs < 4 && useParam
                J = @(t,y,yp,~)ODE.Jacobian.Jacobian(t,y,yp);
            else
                J = ODE.Jacobian.Jacobian;
            end
        else
            J = ODE.Jacobian.Jacobian;
        end
        opts.Jacobian = J;
        opts.JPattern = ODE.Jacobian.SparsityPattern;
    end
end

function opts = setMassMatrix(opts,ODE,useParam)
    if isempty(ODE.MassMatrix)
        return
    elseif ~isa(ODE.MassMatrix.MassMatrix,'function_handle')
        opts.Mass = ODE.MassMatrix.MassMatrix;
        opts.MStateDependence = string(ODE.MassMatrix.StateDependence);
        opts.MvPattern = ODE.MassMatrix.SparsityPattern;
        opts.MassSingular = string(ODE.MassMatrix.Singular);
    else
        nArgs = nargin(ODE.MassMatrix.MassMatrix);
        SDNone = ODE.MassMatrix.StateDependence == matlab.ode.StateDependence.none;
        if nArgs <= 1 % M(t)
            if useParam
                MFun = @(t,~)ODE.MassMatrix.MassMatrix(t);
            else
                MFun = ODE.MassMatrix.MassMatrix;
            end
        elseif nArgs == 2 && SDNone % M(t,p)
            MFun = ODE.MassMatrix.MassMatrix;
        else
            if nArgs >= 3 || ~useParam
                MFun = ODE.MassMatrix.MassMatrix;
            else
                MFun = @(t,y,~)ODE.MassMatrix.MassMatrix(t,y);
            end
        end
        opts.Mass = MFun;
        opts.MStateDependence = string(ODE.MassMatrix.StateDependence);
        opts.MvPattern = ODE.MassMatrix.SparsityPattern;
        opts.MassSingular = string(ODE.MassMatrix.Singular);
    end
end

function opts = setEvents(opts,ODE,isImplicit)
    E = ODE.EventDefinition;
    if ~isempty(E)
        if ODE.SelectedSolver == matlab.ode.SolverID.ddensd
            NOPARMS = nargin(ODE.EventDefinition.EventFcn) < 5;
            if NOPARMS
                EFcn = @(t,y,ydel,ypdel,~)E.evaluateNeutralDelay(t,y,ydel,ypdel,[]);
            else
                EFcn = @(t,y,ydel,ypdel,p)E.evaluateNeutralDelay(t,y,ydel,ypdel,p);
            end
        elseif ~isImplicit
            NOPARMS = nargin(ODE.EventDefinition.EventFcn) < 3;
            if NOPARMS
                EFcn = @(t,y,~)E.evaluateStandard(t,y);
            else
                EFcn = @(t,y,p)E.evaluateStandard(t,y,p);
            end
        else % implicit and DDE with same signature
            NOPARMS = nargin(ODE.EventDefinition.EventFcn) < 4;
            if NOPARMS
                EFcn = @(t,y,yp,~)E.evaluateImplicitOrDelay(t,y,yp);
            else
                EFcn = @(t,y,yp,p)E.evaluateImplicitOrDelay(t,y,yp,p);
            end
        end
        opts.Events = EFcn;
    end
end

function opts = setOutputFcn(opts,ODE,useParam)
    if ~isempty(ODE.SolverOptions.OutputFcn)
        if isStringScalar(ODE.SolverOptions.OutputFcn) || ...
                ischar(ODE.SolverOptions.OutputFcn)
            outfun = str2func(ODE.SolverOptions.OutputFcn);
        else
            outfun = ODE.SolverOptions.OutputFcn;
        end
        if useParam && nargin(outfun) == 3
            opts.OutputFcn = @(t,y,flag,~) outfun(t,y,flag);
        else
            opts.OutputFcn = outfun;
        end
    end
end

function [dobj,opts] = setDelay(opts, ODE, useParam)
    % Set properties and update the delay object's function handles to
    % handle parameters correctly
    if isempty(ODE.DelayDefinition) ...
            || ODE.EquationType ~= matlab.ode.EquationType.delay
        dobj = [];
        return
    end
    opts.InitialY = ODE.InitialValue;
    if ODE.SelectedSolver == matlab.ode.SolverID.dde23
        opts.Jumps = ODE.SolverOptions.Jumps;
    end
    dobj = odeDelay;
    dobj.ValueDelay = ODE.DelayDefinition.ValueDelay;
    dobj.SlopeDelay = ODE.DelayDefinition.SlopeDelay;
    dobj.History = ODE.DelayDefinition.History;
    % Update delay functions for parameters
    if ~isempty(ODE.DelayDefinition.ValueDelay) && ...
            isa(ODE.DelayDefinition.ValueDelay, "function_handle")
        dobj.ValueDelay = packageFunctionParam(ODE.DelayDefinition.ValueDelay,3,useParam);
    end
    % Update slope lags in presence of parameters if necessary
    if ~isempty(ODE.DelayDefinition.SlopeDelay) && ...
            isa(ODE.DelayDefinition.SlopeDelay, "function_handle")
        dobj.SlopeDelay = packageFunctionParam(ODE.DelayDefinition.SlopeDelay,3,useParam);
    end
    % Update history in presence of parameters and IVNDDE if necessary
    if ODE.isIVNDDE
        % IVNDDE - using this to get out ddensd IVP inputs
        opts.History = {ODE.InitialValue, ODE.InitialSlope};
    else
        % Other
        if ~isempty(ODE.DelayDefinition.History) && ...
                isa(ODE.DelayDefinition.History, "function_handle")
            dobj.History = packageFunctionParam(ODE.DelayDefinition.History,2,useParam);
        end
    end
end


function newFunc = packageFunctionParam(func,threshold,useParam)
% convenience function for binding function handles that may or may not have
% parameters. 
    newFunc = func;
    % Check if the number of arguments needs to be extended
    if useParam
        % Determine the number of input arguments for the original function
        numArgs = nargin(func);
        if numArgs < threshold
            % Select the wrapper function based on the number of arguments in the original function
            switch numArgs
                case 1
                    newFunc = @(a1, ~) func(a1);
                case 2
                    newFunc = @(a1, a2, ~) func(a1, a2);
                case 3
                    newFunc = @(a1, a2, a3, ~) func(a1, a2, a3);
                case 4
                    newFunc = @(a1, a2, a3, a4, ~) func(a1, a2, a3, a4);
            end
        end
    end
end


function fun = packageEqnAsImplicit(ODE)
% takes an ODE object and returns a function handle appropriate
% for use with decic
nArgs = nargin(ODE.ODEFcn);
nArgsMass = 0;
rhsfun = ODE.ODEFcn;
if ~isempty(ODE.MassMatrix) && isa(ODE.MassMatrix.MassMatrix,'function_handle')
    nArgsMass = nargin(ODE.MassMatrix.MassMatrix);
end
if ODE.EquationType == matlab.ode.EquationType.standard
    if nArgs == 2
        odefun = @(t,y,~) rhsfun(t,y);
    else
        odefun = @(t,y,p) rhsfun(t,y,p);
    end
    if isempty(ODE.MassMatrix)
        fun = @(t,y,yp,p) yp - odefun(t,y,p);
    else % has mass
        M = ODE.MassMatrix.MassMatrix;
        if nArgsMass == 0
            fun = @(t,y,yp,p) M*yp - odefun(t,y,p);
        elseif nArgsMass == 1
            fun = @(t,y,yp,p) M(t)*yp - odefun(t,y,p);
        elseif nArgsMass == 2
            fun = @(t,y,yp,p) M(t,y)*yp - odefun(t,y,p);
        else
            fun = @(t,y,yp,p) M(t,y,p)*yp - odefun(t,y,p);
        end
    end
elseif ODE.EquationType == matlab.ode.EquationType.delay
    % setup delay obj to have the right parameter behavior for lags
    dobj = setDelay(struct(), ODE, usesParameters(ODE));
    if ODE.SelectedSolver == matlab.ode.SolverID.ddensd
        if nArgs == 5
            rhs = @(t,y,ydel,ypdel,~) rhsfun(t,y,ydel,ypdel,ODE.Parameters);
        else
            rhs = rhsfun;
        end
        isIVNDDE = ODE.isIVNDDE;
        fun = @(t,y,yp,~) yp - ddensdyp0(t,y,yp,rhs,dobj.ValueDelay, ...
            dobj.SlopeDelay,dobj.History,isIVNDDE);
    else 
        if nArgs == 4
            rhs = @(t,y,ydel,~) rhsfun(t,y,ydel,ODE.Parameters);
        else
            rhs = rhsfun;
        end
        if (ODE.SelectedSolver == matlab.ode.SolverID.ddesd)
            laggedrhs = @ddesdyp0;
        else
            laggedrhs = @dde23yp0;
        end
        fun = @(t,y,yp,~) yp - laggedrhs(t,y,rhs,dobj.ValueDelay,dobj.History);
    end
else % implicit
    if nArgs == 3
        fun = @(t,y,yp,~) rhsfun(t,y,yp);
    else
        fun = rhsfun;
    end
end
end

% helper for consistentInitialConditions
function opts = packageOptsForCIC(ODE)
opts.RelTol = ODE.RelativeTolerance;
opts.AbsTol = ODE.AbsoluteTolerance;
useParam = ODE.usesParameters;
isImplicit = (ODE.EquationType == matlab.ode.EquationType.fullyimplicit);
if isprop(ODE.SolverOptions,"Vectorization") && isImplicit
    opts.Vectorized = ODE.SolverOptions.Vectorization;
elseif isprop(ODE.SolverOptions,"Vectorization")
    opts.Vectorized = {ODE.SolverOptions.Vectorization,'off'};
end
if ~isempty(ODE.Jacobian) && isa(ODE.Jacobian.Jacobian,'function_handle')
    jfun = ODE.Jacobian.Jacobian;
    nArgs = nargin(jfun);
    if ~isImplicit && nArgs > 2 && useParam
        J = @(t,y,~,p)jhelperTYP(t,y,p,jfun);
    elseif ~isImplicit
        J = @(t,y,~,~) jhelperTY(t,y,jfun);
    elseif isImplicit && nArgs < 4
        J = @(t,y,yp,~) jfun(t,y,yp);
    else % catch-all with implicit
        J = jfun;
    end
elseif ~isempty(ODE.Jacobian)
    if ~isImplicit
        J = {ODE.Jacobian.Jacobian,[]};
        opts.JPattern = {ODE.Jacobian.SparsityPattern,[]};
    else
        J = ODE.Jacobian.Jacobian;
        opts.JPattern = ODE.Jacobian.SparsityPattern;
    end
else
    J = [];
end
if ~isImplicit && isempty(ODE.MassMatrix)
    opts.JPattern{2} = speye(numel(ODE.InitialValue));
end
opts.Jacobian = J;
end

% helpers to pass a function handles that match decic calling conventions
function [jac1,jac2] = jhelperTY(t,y,jfun)
jac1 = jfun(t,y);
jac2 = [];
end
function [jac1,jac2] = jhelperTYP(t,y,p,jfun)
jac1 = jfun(t,y,p);
jac2 = [];
end

% helper for unpacking the solution struct from DDE solvers
function [t,y,te,ye,ie,st,stats] = unpackSolStruct(st,trim)
    if nargin == 1
        trim = false;
    end
    t = st.x(:);
    y = st.y.';
    if isfield(st,"xe")
        te = st.xe(:);
        ye = st.ye.';
        ie = st.ie(:);
    end
    stats(7) = st.stats.tfinal; % only care about time endpoint and DDE solvers return struct
    if trim % trim values in eventloops when needed
        if t(end) == te(end)
            % stopped because of an event
            inds = t>te(end-1);
        else % hit end of integration interval
            inds = t>te(end);
        end
        t = t(inds);
        y = y(inds,:);
        te = te(end);
        ye = ye(end,:);
        ie = ie(end);
    end
    if nargout == 3
        % overwrite third out arg when there are no events to conform to
        % calling conventions 
        te = stats; 
    end
end

% A few DDE helpers
function yp0 = dde23yp0(t0, y0, ddefun, dely, history)
    Z0 = matlab.ode.internal.dde.lagvals(t0,[],dely,history,t0,y0,[]);
    yp0 = ddefun(t0,y0,Z0);
end

function yp0 = ddesdyp0(t0, y0, ddefun, dely, history)
    Z0 = matlab.ode.internal.dde.lagvals(t0,y0,dely,history,t0,y0,[]);
    yp0 = ddefun(t0,y0,Z0);
end

function yp0 = ddensdyp0(t0, y0, yp0_guess, ddefun, dely, delyp, history, IVP)
    % get the derivative yp for a problem consistent with ddensd
    if IVP
        IVP_T0 = t0;
        IVP_YP0 = yp0_guess(:);
        Nhistory = y0;
    else
        Nhistory = history;
        IVP_T0 = [];
        IVP_YP0 = [];
    end

    y0 = y0(:);
    if isa(dely,'function_handle')
        ydel = dely;
    elseif isempty(dely)
        ydel = @(~,~) [];
    elseif isnumeric(dely) && isvector(dely)
        ydel = @(t,~) t - dely(:);
    end
    
    if isa(delyp,'function_handle')
        ypdel = delyp;
    elseif isempty(delyp)
        ypdel = @(~,~) [];
    elseif isnumeric(delyp) && isvector(delyp)
        ypdel = @(t,~) t - delyp(:);
    end
    
    % Sizes and indices
    D = ydel(t0,y0);
    Dp = ypdel(t0,y0);
    nydel = numel(D);
    nypdel = numel(Dp);
    
    yIdx = 1:nydel;
    ypIdx = nydel+(1:nypdel);
    ypdIdx = nydel+nypdel+(1:nypdel);
    
    epsT = eps(class(t0));
    DELTA = sqrt(epsT);
    MINCHANGE = DELTA*norm(t0,inf);
       
    Ndde_fun = @(t,y,Z)matlab.ode.internal.dde.Ndde(t,y,Z, ...
            ydel,yIdx,ypIdx,ypdIdx,ddefun,IVP,IVP_T0,IVP_YP0,ypdel,DELTA,MINCHANGE);
    Ndelays_fun = @(t,y)matlab.ode.internal.dde.Ndelays(t,y, ...
            ydel,ypdel,IVP,IVP_T0,DELTA,MINCHANGE);
    yp0 = ddesdyp0(t0, y0, Ndde_fun, Ndelays_fun, Nhistory);
end