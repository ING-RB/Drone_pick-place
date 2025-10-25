classdef (Sealed = true) ode < matlab.mixin.Scalar & matlab.mixin.CustomDisplay

    properties
        EquationType (1,1) matlab.ode.EquationType = "standard"
        ODEFcn function_handle % The right-hand side function of the differential equation: dy/dt = ODEFcn(t,y)
        Parameters = []  % Parameters to pass to ODEFcn and other user functions
        InitialTime(1,1){mustBeFloat,mustBeReal,mustBeFinite} = 0 % Initial time (t0)
        InitialValue{mustBeFloat,mustBeVector,mustBeFinite} = zeros(0,1); % Value of the solution at the initial time (y0)
        InitialSlope{mustBeFloat,mustBeVector,mustBeFinite} = zeros(0,1) % Consistent initial slope
        Jacobian = [] % odeJacobian object defining the Jacobian matrix of ODEFcn
        MassMatrix = [] % odeMassMatrix object defining the mass matrix M to solve M*dy/dt = ODEFcn(t,y)
        NonNegativeVariables{mustBePositive,mustBeInteger} = [] % A vector of positive integers indicating non-negative solution components
        EventDefinition = [] % odeEvent object to define events/zero-crossings for the solver to detect
        DelayDefinition = [] % odeDelay object to define delays and history for solving delay differential equations
        Sensitivity = [] % odeSensitivity object defining the sensitivity problem to be solved
        AbsoluteTolerance{mustBeFloat,mustBeReal,mustBeFinite,mustBeNonempty,mustBeNonnegative} = 1e-6 % Absolute tolerance
        RelativeTolerance(1,1){mustBeFloat,mustBeReal,mustBeFinite,mustBeNonempty,mustBeNonnegative} = 1e-3 % Relative tolerance
        Solver(1,1) matlab.ode.SolverID = "auto" % Solver method or "auto", "stiff", or "nonstiff" to automatically select a solver method
        SolverOptions matlab.ode.Options = matlab.ode.options.ODE45 % An object that holds specific, less often used options for the selected solver
        SeparateComplexParts(1,1) matlab.lang.OnOffSwitchState = "off" % Separate real and imaginary parts into different solution components while solving
    end

    properties (SetAccess = protected)
        SelectedSolver matlab.ode.SolverID = "ode45" % Solver method to use (output)
    end

    properties(Hidden,Constant)
        % versioning for save/load serialization
        % 1.0 : Original shipping version (R2023b)
        Version = 1.0;
    end

    properties (SetAccess = private, Hidden)
        SyncSettings = false; % false during construction, then turned on.
        ComplexToRealParameters = false; % true if complex Parameters have been split into real and imaginary parts.
    end

    methods (Hidden)
        function b = saveobj(a)
            % Save all properties to struct.
            b = ode.assignProps(a,false,"ode");
            % We have tethered properties. On load, we want to just set the
            % property values, not enforce any dependencies. Note that
            % SyncSettings default value is false.
            b.SyncSettings = false;
            % Keep track of versioning information.
            b.CompatibilityHelper.versionSavedFrom = a.Version;
            b.CompatibilityHelper.minCompatibleVersion = 1.0;
        end
    end

    methods (Hidden,Static)
        function b = loadobj(a)
            if ode.Version < a.CompatibilityHelper.minCompatibleVersion
                warning(message("MATLAB:ode:MinVersionIncompat","ode"));
                b = ode;
                return
            end
            if isfield(a,'Solver') && isstruct(a.Solver)
                % This indicates loaded solver was not part of solver
                % enumeration, so a solver was used that was unavilable in
                % this version of MATLAB.
                warning(message("MATLAB:ode:DefaultIncompat","Solver"));
                a.Solver = matlab.ode.SolverID(-1); % auto
                a.SelectedSolver = matlab.ode.SolverID(2); % ode45
            end
            % Get all values from struct.
            b = ode.assignProps(a,true,"ode");
            % Now that the object is loaded, it should be consistent if it
            % was saved in a consistent state. Turn on the property
            % tethering for future property changes.
            b.SyncSettings = true;
        end

        function b = assignProps(a,returnobj,class)
            % Convenience function to assign properties to and from ode
            % related objects.
            % returnobj true indicates an object of type class should be
            % returned, false indicates return a struct.
            if returnobj
                % Make an object of the specified class.
                f = str2func(class);
                b = f();
                if isa(b,'ode')
                    % make sure that solver heuristic doesn't run while
                    % constructing odes
                    b.SyncSettings = false;
                end
            else
                b = struct;
            end
            writtenFields = strings(0);
            mc = meta.class.fromName(class);
            for ip = 1:numel(mc.PropertyList)
                prop = mc.PropertyList(ip);
                if prop.Transient || prop.Constant || prop.Dependent || ...
                        (returnobj && ~isfield(a,prop.Name))
                    % Skip if we don't need to save, or if the struct does
                    % not contain the field.
                    continue;
                end
                b.(prop.Name) = a.(prop.Name);
                writtenFields(end+1) = prop.Name; %#ok<AGROW>
            end
            % add CompatibilityHelper to list so it doesn't trigger warning
            writtenFields(end+1) = "CompatibilityHelper";
            if returnobj && ~isempty(setdiff(fieldnames(a),writtenFields))
                % If the ode did not request to define all fields saved in
                % a, there are new properties indicating a backwards
                % incompatibility, so warn.
                warning(message("MATLAB:ode:IgnoredIncompat"));
            end
        end
    end

    methods
        function obj = ode(nv)
            arguments
                nv.?ode
            end
            % Suspend syncing while we construct the object.
            obj.SyncSettings = false;
            names = fieldnames(nv);
            for k = 1:numel(names)
                obj.(names{k}) = nv.(names{k});
            end
            % Check for consistency.
            SOLVER_SUPPLIED = isfield(nv,'Solver');
            SOLVEROPTIONS_SUPPLIED = isfield(nv,'SolverOptions');
            % Set the solver.
            if SOLVER_SUPPLIED && SOLVEROPTIONS_SUPPLIED
                if obj.SolverOptions.ID ~= obj.Solver
                    error(message('MATLAB:ode:IncompatibleSolver',string(obj.Solver),string(obj.SolverOptions.ID)));
                end
            elseif SOLVEROPTIONS_SUPPLIED && ~SOLVER_SUPPLIED
                obj.Solver = obj.SolverOptions.ID;
                obj.SelectedSolver = obj.SolverOptions.ID;
            elseif SOLVER_SUPPLIED && ~SOLVEROPTIONS_SUPPLIED
                if isManualSolverSelection(obj.Solver)
                    obj.SelectedSolver = obj.Solver;
                else
                    obj.SelectedSolver = obj.selectSolver;
                end
                obj.SolverOptions = matlab.ode.Options.makeSolverOptions(obj.SelectedSolver);
            end
            obj.SyncSettings = true;
            obj = obj.manageSolverProperties;
        end
        function obj = set.EquationType(obj,typ)
            arguments
                obj ode
                typ matlab.ode.EquationType
            end
            if ~isSame(typ,obj.EquationType)
                obj.EquationType = typ;
                obj = obj.manageSolverProperties;
                if ~isSame(typ,obj.EquationType)
                    % Manually chosen solver takes precedence. If
                    % EquationType did not update, warn to indicate the
                    % incompatibility.
                    warning(message("MATLAB:ode:EqnAndSolverCompat",...
                        string(typ),string(obj.SelectedSolver),string(obj.EquationType))) %#ok<MCSUP>
                end
            end
        end
        function obj = set.NonNegativeVariables(obj,nn)
            arguments
                obj ode
                nn {mustBePositive,mustBeInteger}
            end
            if ~isSame(nn,obj.NonNegativeVariables)
                obj.NonNegativeVariables = nn;
                obj = obj.manageSolverProperties;
            end
        end
        function obj = set.ODEFcn(obj,fcn)
            if ~isSame(fcn,obj.ODEFcn)
                obj.ODEFcn = fcn;
                nArgs = nargin(obj.ODEFcn);
                if nArgs < 2 || nArgs > 5
                    error(message('MATLAB:ode:NarginODEFcn'));
                end
            end
        end
        function obj = set.AbsoluteTolerance(obj,tol)
            arguments
                obj ode
                tol {mustBeFloat,mustBeReal,mustBeFinite,mustBeNonempty,mustBeNonnegative}
            end
            if ~isSame(tol,obj.AbsoluteTolerance)
                obj.AbsoluteTolerance = tol;
                obj = obj.manageSolverProperties;
            end
        end
        function obj = set.RelativeTolerance(obj,tol)
            arguments
                obj ode
                tol {mustBeFloat,mustBeReal,mustBeFinite,mustBeNonempty,mustBeNonnegative}
            end
            if ~isSame(tol,obj.RelativeTolerance)
                mintol = 100*eps(class(obj.InitialValue)); %#ok<MCSUP>
                toosmall = ~(tol >= mintol);
                if any(toosmall,'all')
                    tol(toosmall) = mintol;
                    warning(message('MATLAB:odearguments:RelTolIncrease',sprintf('%g',mintol)));
                end
                obj.RelativeTolerance = tol;
                obj = obj.manageSolverProperties;
            end
        end
        function obj = set.MassMatrix(obj,M)
            if ~isSame(M,obj.MassMatrix) && ...
                    ~(isempty(M) && isempty(obj.MassMatrix))
                if isempty(M)
                    obj.MassMatrix = [];
                elseif isa(M,'odeMassMatrix')
                    obj.MassMatrix = M;
                else
                    obj.MassMatrix = odeMassMatrix(MassMatrix=M);
                end
                obj = obj.manageSolverProperties;
            end
        end
        function obj = set.Jacobian(obj,J)
            if ~isSame(J,obj.Jacobian) && ...
                    ~(isempty(J) && isempty(obj.Jacobian))
                if isempty(J)
                    obj.Jacobian = [];
                elseif isa(J,'odeJacobian')
                    obj.Jacobian = J;
                else
                    obj.Jacobian = odeJacobian(Jacobian=J);
                end
                obj = obj.manageSolverProperties;
            end
        end
        function obj = set.EventDefinition(obj,E)
            if ~isSame(E,obj.EventDefinition)
                emptyBefore = isempty(obj.EventDefinition);
                if isempty(E)
                    obj.EventDefinition = [];
                elseif isa(E,'odeEvent')
                    obj.EventDefinition = E;
                else
                    obj.EventDefinition = odeEvent(EventFcn=E);
                end
                emptyAfter = isempty(obj.EventDefinition);
                if emptyBefore ~= emptyAfter
                    obj = obj.manageSolverProperties;
                end
            end
        end
        function obj = set.DelayDefinition(obj,D)
            if ~isSame(D,obj.DelayDefinition)
                if isempty(D)
                    obj.DelayDefinition = [];
                    if obj.SyncSettings %#ok<MCSUP>
                        obj.EquationType = 0; %#ok<MCSUP>
                    end
                elseif isa(D,'odeDelay') && isscalar(D)
                    obj.DelayDefinition = D;
                else
                    error(message("MATLAB:ode:BadDelay"));
                end
                obj = obj.manageSolverProperties;
            end
        end
        function obj = set.Sensitivity(obj,S)
            if ~isSame(S,obj.Sensitivity)
                emptyBefore = isempty(obj.Sensitivity);
                if isempty(S)
                    obj.Sensitivity = [];
                elseif isa(S,'odeSensitivity') && isscalar(S)
                    obj.Sensitivity = S;
                else
                    error(message("MATLAB:ode:BadSensitivity"))
                end
                emptyAfter = isempty(obj.Sensitivity);
                if emptyBefore ~= emptyAfter
                    obj = obj.manageSolverProperties;
                end
            end
        end
        function obj = set.Solver(obj,s)
            arguments
                obj
                s(1,1) matlab.ode.SolverID
            end
            narginchk(2,2);
            if ~isSame(obj.Solver,s)
                obj.Solver = s;
                obj = obj.manageSolverProperties;
            end
        end
        function obj = set.InitialValue(obj,iv)
            arguments
                obj
                iv
            end
            narginchk(2,2);
            % check if solver heuristic should run again, if class or size
            % changes while setting initial value
            runSelectSolver = ~isequal(class(obj.InitialValue),class(iv)) ...
                || numel(obj.InitialValue) ~= numel(iv);
            obj.InitialValue = iv;
            if runSelectSolver
                obj = obj.manageSolverProperties;
            end
        end
        function obj = set.InitialSlope(obj,iv)
            arguments
                obj
                iv
            end
            narginchk(2,2);
            % check if solver heuristic should run again, if class or size
            % changes while setting initial value
            runSelectSolver = ~isequal(class(obj.InitialSlope),class(iv)) ...
                || numel(obj.InitialSlope) ~= numel(iv);
            obj.InitialSlope = iv;
            if runSelectSolver
                obj = obj.manageSolverProperties;
            end
        end
        function obj = set.SolverOptions(obj,op)
            arguments
                obj
                op matlab.ode.Options
            end
            obj.SolverOptions = op;
            if obj.SyncSettings %#ok<MCSUP>
                MANUAL_SOLVER = isManualSolverSelection(obj.Solver); %#ok<MCSUP>
                % When the solver is automatically selected, the only supported
                % input for SolverOptions is a default options object for the
                % currently selected solver. That input needs to be supported
                % on construction and on load.
                if ~(MANUAL_SOLVER || (obj.SelectedSolver == op.ID && op.isDefault)) %#ok<MCSUP>
                    error(message('MATLAB:ode:SolverOptionsCannotBeModified',string(obj.SelectedSolver))); %#ok<MCSUP>
                end
                % When the solver is manually selected, assigning a new
                % SolverOptions object will set the Solver to match.
                if MANUAL_SOLVER && obj.Solver ~= op.ID %#ok<MCSUP>
                    obj.Solver = op.ID; %#ok<MCSUP>
                end
            end
        end
        function sol = solve(obj,t1,t2,nv)
            arguments
                obj
                t1 {mustBeReal,mustBeNumericOrLogical,mustBeVector}
                t2(1,1) {mustBeReal,mustBeNumericOrLogical} = 0
                nv.Refine(1,1) {mustBeInteger,mustBePositive}
            end
            narginchk(2,inf);
            checkConsistency(obj);
            if obj.SeparateComplexParts
                splitZ = true;
                obj = complexToReal(obj);
            else
                splitZ = false;
            end
            if obj.EquationType == matlab.ode.EquationType.delay
                % validate time interval
                if ( nargin <=2 && ~(obj.InitialTime<=min(t1)) ) || ...
                        (isscalar(t1) && isscalar(t2) && ~(obj.InitialTime<=min([t1, t2])))
                    error(message('MATLAB:ode:InvalidTimeIntervalDelay'))
                end
                obj.InitialValue = getDelayInitialValue(obj);
            end
            if obj.checkCIC
                obj = consistentInitialConditions(obj);
            end
            if nargin <= 2
                if isfield(nv,'Refine')
                    warning(message('MATLAB:ode:RequestedAndRefine'));
                end
                sol = obj.solveAt(t1);
            elseif ~isscalar(t1)
                error(message('MATLAB:maxrhs'));
            elseif isnan(t1) || isnan(t2)
                error(message('MATLAB:ode:InvalidSolutionInterval'));
            else
                if isfield(nv,'Refine')
                    refine = nv.Refine;
                else
                    refine = obj.SolverOptions.DefaultRefine;
                end
                sol = obj.solveBetween(t1,t2,refine);
            end
            if splitZ
                sol = realToComplex(sol);
            end
        end
        function [f,solutionData] = solutionFcn(obj,t1,t2,nv)
            arguments
                obj ode
                t1(1,1) {mustBeFloat,mustBeReal,mustBeNonNan}
                t2(1,1) {mustBeFloat,mustBeReal,mustBeNonNan}
                nv.OutputVariables {mustBeNumeric,mustBeReal,mustBePositive,mustBeInteger,mustBeVector}
                nv.Extension(1,1) matlab.lang.OnOffSwitchState = "off"
            end
            checkConsistency(obj);
            if obj.SeparateComplexParts
                splitZ = true;
                obj = complexToReal(obj);
            else
                splitZ = false;
            end
            t0 = obj.InitialTime;
            if t2 < t1
                error(message('MATLAB:ode:EndPointsInWrongOrder'));
            end
            if t1 > t0 || t2 < t0
                error(message('MATLAB:ode:IntervalMustContainInitialTime'));
            end
            if t1 == t2
                error(message('MATLAB:ode:IntervalMustHavePositiveLength'))
            end
            if obj.EquationType == matlab.ode.EquationType.delay
                % error if attempting to integrate backwards
                if t1 < t0
                    error(message('MATLAB:ode:InvalidTimeIntervalDelay'));
                end
                obj.InitialValue = getDelayInitialValue(obj);
            end
            if obj.checkCIC
                obj = consistentInitialConditions(obj);
            end
            VARIABLES_SUPPLIED = isfield(nv,'OutputVariables') && ~isempty(nv.OutputVariables);
            if VARIABLES_SUPPLIED
                if any(nv.OutputVariables > numel(obj.InitialValue))
                    error(message('MATLAB:ode:OutputVarDimMismatch',...
                        numel(obj.InitialValue)));
                end
                vars = nv.OutputVariables(:).';
                if splitZ
                    vars = [2*vars - 1;2*vars];
                    VARIABLES = {vars(:).'};
                else
                    VARIABLES = {vars};
                end
            else
                VARIABLES = {};
            end
            ODESOL = matlab.ode.internal.SolverPair(obj);
            L = cast(t1,"like",t0);
            R = cast(t2,"like",t0);
            [ODESOL,L,R] = ODESOL.extend(L,R);
            if nv.Extension == matlab.lang.OnOffSwitchState.off
                ODESOL.Domain = [L,R];
            end
            function [y,yp] = interpolate(t)
                if nargout > 1
                    [ODESOL,y,yp] = ODESOL.evaluate(t,VARIABLES{:});
                else
                    [ODESOL,y] = ODESOL.evaluate(t,VARIABLES{:});
                end
            end
            function [y,yp] = interpolateRealToComplex(t)
                if nargout > 1
                    [ODESOL,y,yp] = ODESOL.evaluate(t,VARIABLES{:});
                    sz = size(y);
                    nrows = size(y,1)/2;
                    sz(1) = nrows;
                    y = reshape(typecast(y(:),"like",complex(y)),sz);
                    yp = reshape(typecast(yp(:),"like",complex(yp)),sz);
                else
                    [ODESOL,y] = ODESOL.evaluate(t,VARIABLES{:});
                    sz = size(y);
                    nrows = size(y,1)/2;
                    sz(1) = nrows;
                    y = reshape(typecast(y(:),"like",complex(y)),sz);
                end
            end
            if ~splitZ
                f = @interpolate;
            else
                f = @interpolateRealToComplex;
            end
            if nargout > 1
                HAS_EVENTS = ~isempty(obj.EventDefinition);
                HAS_SENSITIVITY = ~isempty(obj.Sensitivity);
                s = []; se = [];
                if HAS_SENSITIVITY
                    [t,y,te,ye,ie,s,se] = ODESOL.getCachedSolution;
                else
                    [t,y,te,ye,ie] = ODESOL.getCachedSolution;
                end
                t = t.';
                te = te.';
                ie = ie.';
                ncomp = numel(obj.InitialValue);
                [s,se] = shapeSens(s,se,ncomp);
                solutionData = matlab.ode.ODEResults(Time=t,Solution=y,...
                    EventTime=te,EventSolution=ye,EventIndex=ie,...
                    Sensitivity=s,EventSensitivity=se,...
                    hasEvents=HAS_EVENTS,hasSensitivity=HAS_SENSITIVITY);
                if splitZ
                    solutionData = solutionData.realToComplex();
                end
            end
        end
        function [obj,nrm] = consistentInitialConditions(obj,nv)
            arguments
                obj ode
                nv.FixedValueVariables (1,:) logical = []
                nv.FixedSlopeVariables (1,:) logical = []
            end
            if nargout < 1
                warning(message("MATLAB:ode:NoOutputIC"));
            end
            if obj.EquationType == matlab.ode.EquationType.delay
                obj.InitialValue = getDelayInitialValue(obj);
            end
            checkConsistency(obj);
            nVals = numel(obj.InitialValue);
            % check compatibility of initial value and slope
            if ~isempty(obj.InitialSlope) && numel(obj.InitialValue) ~= numel(obj.InitialSlope)
                error(message("MATLAB:ode:WrongSizeSlope"))
            end
            if ~isempty(nv.FixedValueVariables) && ...
                    numel(nv.FixedValueVariables) ~= nVals
                error(message("MATLAB:ode:VectorWrongLengthOrEmpty","FixedValueVariables",nVals))
            end
            if ~isempty(nv.FixedSlopeVariables) && ...
                    numel(nv.FixedSlopeVariables) ~= nVals
                error(message("MATLAB:ode:VectorWrongLengthOrEmpty","FixedSlopeVariables",nVals))
            end
            val_y = obj.InitialValue(:);
            if ~isvector(obj.AbsoluteTolerance) || ...
                    (numel(obj.AbsoluteTolerance) > 1 && numel(obj.AbsoluteTolerance) ~= numel(val_y))
                error(message("MATLAB:ode:ICAbsTolSize"));
            end
            if isempty(obj.InitialSlope)
                val_yp = 0*obj.InitialValue(:);
            else
                val_yp = obj.InitialSlope(:);
            end
            % set up fixed components
            fixed_y = nv.FixedValueVariables;
            fixed_yp = nv.FixedSlopeVariables;
            [fun,opts] = matlab.ode.internal.LegacySolver.packageProblemForCIC(obj);
            % call decic
            [obj.InitialValue,obj.InitialSlope,nrm] = ...
                decic(fun,obj.InitialTime,val_y,fixed_y,...
                val_yp,fixed_yp,...
                opts,obj.Parameters);
        end
        function solverid = selectSolver(obj,nv)
            % Heuristic solver selection based on tolerances and
            % user-supplied information. This is not the final word.
            % Note that RelativeTolerance is used as a scalar below. If a
            % new solver supports vector tolerances in the future,
            % supplying vector tolerances may influence the solver
            % selection.
            arguments
                obj
                nv.DetectStiffness (1,1) matlab.lang.OnOffSwitchState = "off"
                nv.IntervalLength (1,1) {mustBePositive} = inf
            end
            if obj.EquationType == matlab.ode.EquationType.fullyimplicit
                % early exit for fully implicit problems
                solverid = matlab.ode.SolverID.ode15i;
                return
            elseif obj.EquationType == matlab.ode.EquationType.delay
                % early exit for delay problems
                solverid = matlab.ode.SolverID.dde23; % Default to dde23
                if ~isempty(obj.DelayDefinition)
                    if ~isempty(obj.DelayDefinition.SlopeDelay)
                        solverid = matlab.ode.SolverID.ddensd;
                    elseif ~isempty(obj.DelayDefinition.ValueDelay) && ...
                            isa(obj.DelayDefinition.ValueDelay,'function_handle')
                        solverid = matlab.ode.SolverID.ddesd;
                    end
                end
                return
            end
            n = numel(obj.InitialValue);
            STIFF = obj.Solver == matlab.ode.SolverID.stiff;
            NONSTIFF = obj.Solver == matlab.ode.SolverID.nonstiff;
            HASMASS = ~isempty(obj.MassMatrix);
            if HASMASS
                msing = obj.MassMatrix.Singular;
                mstate = obj.MassMatrix.StateDependence;
                MASS_SINGULAR = strcmp(msing,'yes');
                MASS_NONSINGULAR = strcmp(msing,'no');
                MASS_CONSTANT = strcmp(mstate,'none');
            else
                MASS_SINGULAR = false;
                MASS_CONSTANT = true;
                MASS_NONSINGULAR = true;
            end
            HASYP0 = ~isempty(obj.InitialSlope);
            NONNEG = ~isempty(obj.NonNegativeVariables);
            if nv.DetectStiffness
                isStiff = stiffnessHeuristic(obj,nv.IntervalLength);
                % Note, if user requests stiffness detection, we
                % purposefully ignore setting stiff or nonstiff as solver
                STIFF = isStiff;
                NONSTIFF = ~isStiff;
            end
            % Use the NonNegative parameter with ode15s, ode23t, and ode23tb
            % only for those problems in which there is no mass matrix.
            if ~isempty(obj.Sensitivity)
                if HASMASS
                    solverid = matlab.ode.SolverID.idas;
                elseif STIFF || ~isempty(obj.Jacobian)
                    solverid = matlab.ode.SolverID.cvodesStiff;
                else % nonstiff
                    solverid = matlab.ode.SolverID.cvodesNonstiff;
                end
            elseif STIFF || (~NONSTIFF && ( ...
                    ~isempty(obj.InitialSlope) || ...
                    ~isempty(obj.Jacobian) || ...
                    ~MASS_NONSINGULAR))
                % If the user supplies yp0 or jac, then default to a
                % stiff solver.
                if NONNEG && HASMASS
                    % We can't mix NONNEG and HASMASS with the
                    % stiff solvers. Best we can do is the non-stiff
                    % solver ode23.
                    solverid = matlab.ode.SolverID.ode23;
                elseif obj.RelativeTolerance <= 1e-3
                    solverid = matlab.ode.SolverID.ode15s;
                elseif HASYP0 || MASS_SINGULAR
                    solverid = matlab.ode.SolverID.ode23t;
                elseif ~NONNEG && MASS_CONSTANT
                    solverid = matlab.ode.SolverID.ode23s;
                else
                    solverid = matlab.ode.SolverID.ode23tb;
                end
            else
                if obj.RelativeTolerance > 1e-3
                    solverid = matlab.ode.SolverID.ode23;
                elseif obj.RelativeTolerance > 1e-7
                    solverid = matlab.ode.SolverID.ode45;
                elseif any(obj.RelativeTolerance >= 1e-12) && ...
                        isempty(obj.EventDefinition) && ...
                        n <= 32 && ...
                        isa(obj.InitialValue,'double')
                    % ODE78 and ODE89 are prone to report duplicate
                    % events so we eschew them via auto-select if
                    % events have been defined.
                    if obj.RelativeTolerance > 1e-10
                        solverid = matlab.ode.SolverID.ode78;
                    else
                        solverid = matlab.ode.SolverID.ode89;
                    end
                else
                    solverid = matlab.ode.SolverID.ode113;
                end
            end
        end
    end

    methods (Hidden,Access={?matlab.ode.internal.Solver})
        function p = usesParameters(obj)
            p = false;
            nArgBnd = 3;
            if obj.EquationType == matlab.ode.EquationType.delay
                if obj.SelectedSolver == matlab.ode.SolverID.ddensd
                    nArgBnd = 5;
                else
                    nArgBnd = 4;
                end
            elseif  obj.EquationType == matlab.ode.EquationType.fullyimplicit
                % implicit gets extra argument for some function handles
                nArgBnd = 4;
            end
            if ~isempty(obj.ODEFcn)
                p = nargin(obj.ODEFcn) >= nArgBnd;
            end
            if ~p && ~isempty(obj.MassMatrix) && isa(obj.MassMatrix.MassMatrix,'function_handle')
                if obj.MassMatrix.StateDependence == matlab.ode.StateDependence.none
                    p = nargin(obj.MassMatrix.MassMatrix) >= 2;
                else
                    p = nargin(obj.MassMatrix.MassMatrix) >= 3;
                end
            end
            if ~p && ~isempty(obj.Jacobian) && isa(obj.Jacobian.Jacobian,'function_handle')
                p = nargin(obj.Jacobian.Jacobian) >= nArgBnd;
            end
            if ~p && ~isempty(obj.EventDefinition)
                if ~isempty(obj.EventDefinition.EventFcn)
                    p = nargin(obj.EventDefinition.EventFcn) >= nArgBnd;
                end
                if ~p && ~isempty(obj.EventDefinition.CallbackFcn)
                    p = nargin(obj.EventDefinition.CallbackFcn) >= 4;
                end
            end
            if ~p && ~isempty(obj.DelayDefinition)
                if ~isempty(obj.DelayDefinition.History) && ...
                        isa(obj.DelayDefinition.History,'function_handle')
                    p = nargin(obj.DelayDefinition.History) >= 2;
                end
                if ~p && ~isempty(obj.DelayDefinition.ValueDelay) && ...
                        isa(obj.DelayDefinition.ValueDelay,'function_handle')
                    p = nargin(obj.DelayDefinition.ValueDelay) >= 3;
                end
                if ~p && ~isempty(obj.DelayDefinition.SlopeDelay) && ...
                        isa(obj.DelayDefinition.SlopeDelay,'function_handle')
                    p = nargin(obj.DelayDefinition.SlopeDelay) >= 3;
                end
            end
        end
        function tf = isIVNDDE(obj)
            % Check if the problem setup is consistent with an initial
            % value delay differential equation
            tf = (obj.SelectedSolver == matlab.ode.SolverID.ddensd) && ...
                ~isempty(obj.DelayDefinition) && isempty(obj.DelayDefinition.History);
        end
    end

    methods (Access = private)
        function sol = solveAt(obj,t)
            % Solve the ODE at given time values.
            arguments
                obj ode
                t {mustBeReal,mustBeNumericOrLogical,mustBeVector}
            end
            t = cast(t(:),"like",obj.InitialTime);
            % Solve without cache, given steps.
            % Returns columns (unshaped output).
            nt = numel(t);
            ncomp = numel(obj.InitialValue);
            te = zeros(0,1,"like",obj.InitialTime);
            ye = zeros(ncomp,0,"like",obj.InitialValue);
            ie = zeros(0,1);
            s = [];
            se = [];
            t0 = obj.InitialTime;
            HAS_EVENTS = ~isempty(obj.EventDefinition);
            HAS_SENSITIVITY = ~isempty(obj.Sensitivity);
            tspan = t;
            [tUnique,~,ic] = unique(tspan);
            tspan = tUnique(~isnan(tUnique)); % Work with the non-NaN values.
            if isempty(tspan)
                % All NaN
                t = reshape(t,1,nt);
                y = nan(ncomp,nt,"like",obj.InitialValue);
                if HAS_SENSITIVITY
                    solver = matlab.ode.internal.Solver.makeSolver(obj);
                    [~,~,~,~,~,s,se] = solver.solve(obj.InitialTime);
                end
                s = nan(size(s));
                [s,se] = shapeSens(s,se,ncomp);
                sol = matlab.ode.ODEResults(Time=t,Solution=y,...
                    EventTime=te,EventSolution=ye,EventIndex=ie,...
                    Sensitivity=s,EventSensitivity=se,...
                    hasEvents=HAS_EVENTS,hasSensitivity=HAS_SENSITIVITY);
                return
            end
            tmin = tspan(1);
            tmax = tspan(end);
            HAS_LEFT = tmin < t0;
            HAS_RIGHT = tmax > t0;
            tspanLeft = flip(tspan(tspan <= t0));
            tspanRight = tspan(tspan >= t0);
            ADD_T0_LEFT = numel(tspanLeft) >= 2 && tspanLeft(1) < t0;
            if ADD_T0_LEFT
                tspanLeft = [t0,tspanLeft(:).'];
            end
            ADD_T0_RIGHT = numel(tspanRight) >= 2 && tspanRight(1) > t0;
            if ADD_T0_RIGHT
                tspanRight = [t0,tspanRight(:).'];
            end
            USER_SUPPLIED_T0 = ~(ADD_T0_LEFT || ADD_T0_RIGHT || ...
                isscalar(tspanRight) || isscalar(tspanLeft));
            if HAS_LEFT
                % Instantiate the left solver.
                solver = matlab.ode.internal.Solver.makeSolver(obj);
                if HAS_SENSITIVITY
                    [tL,yL,teL,yeL,ieL,sL,seL] = solver.solve(tspanLeft); %#ok<ASGLU>
                elseif HAS_EVENTS
                    [tL,yL,teL,yeL,ieL] = solver.solve(tspanLeft); %#ok<ASGLU>
                    sL = s;
                    seL = se;
                else
                    [tL,yL] = solver.solve(tspanLeft); %#ok<ASGLU>
                    teL = te;
                    yeL = ye;
                    ieL = ie;
                    sL = s;
                    seL = se;
                end
            end
            if HAS_RIGHT
                solver = matlab.ode.internal.Solver.makeSolver(obj);
                if HAS_SENSITIVITY
                    [tR,yR,teR,yeR,ieR,sR,seR] = solver.solve(tspanRight); %#ok<ASGLU>
                elseif HAS_EVENTS
                    [tR,yR,teR,yeR,ieR] = solver.solve(tspanRight); %#ok<ASGLU>
                    sR = s;
                    seR = se;
                else
                    [tR,yR] = solver.solve(tspanRight); %#ok<ASGLU>
                    teR = te;
                    yeR = ye;
                    ieR = ie;
                    sR = s;
                    seR = se;
                end
            end
            if ADD_T0_LEFT
                % Remove t0
                yL = yL(:,2:end);
                sL = sL(:,2:end);
            end
            if ADD_T0_RIGHT
                % Remove t0
                yR = yR(:,2:end);
                sR = sR(:,2:end);
            end
            if HAS_LEFT && HAS_RIGHT
                % Splice
                if USER_SUPPLIED_T0
                    % We have an extra t0 because it is in both sides.
                    yL = yL(:,2:end);
                    sL = sL(:,2:end);
                end
                yL = flip(yL,2);
                yUnique = [yL,yR];
                teL = flip(teL,1);
                yeL = flip(yeL,2);
                ieL = flip(ieL,1);
                seL = flip(seL,2);
                sL = flip(sL,2);
                sUnique = [sL,sR];
                % Can an event happen at t0? If so we might get a dup.
                te = [teL;teR];
                ye = [yeL,yeR];
                ie = [ieL;ieR];
                se = [seL,seR];
            elseif HAS_LEFT
                yUnique = flip(yL,2); % To use ic.
                te = teL;
                ye = yeL;
                ie = ieL;
                sUnique = flip(sL,2);
                se = seL;
            elseif HAS_RIGHT
                yUnique = yR;
                te = teR;
                ye = yeR;
                ie = ieR;
                sUnique = sR;
                se = seR;
            else
                solver = matlab.ode.internal.Solver.makeSolver(obj);
                if HAS_SENSITIVITY
                    [~,yUnique,~,~,~,sUnique,se] = solver.solve(obj.InitialTime);
                else
                    [~,yUnique] = solver.solve(obj.InitialTime);
                end
            end
            nu = size(yUnique,2);
            if nu < nt
                yUnique = [yUnique,nan(ncomp,nt - nu)];
                if HAS_SENSITIVITY
                    np = size(s,1)/ncomp;
                    sUnique = [sUnique,nan(np,nt - nu)];
                end
            end
            y = yUnique(:,ic);
            if HAS_SENSITIVITY
                s = sUnique(:,ic);
            end
            % Make outputs consistent for plot(t,y).
            t = t.';
            te = te.';
            ie = ie.';
            [s,se] = shapeSens(s,se,ncomp);
            sol = matlab.ode.ODEResults(Time=t,Solution=y,...
                EventTime=te,EventSolution=ye,EventIndex=ie,...
                Sensitivity=s,EventSensitivity=se,...
                hasEvents=HAS_EVENTS,hasSensitivity=HAS_SENSITIVITY);
        end
        function sol = solveBetween(obj,t1,t2,pps)
            % Solve the ODE between two time inputs.
            t0 = obj.InitialTime;
            t1 = cast(t1,"like",t0);
            t2 = cast(t2,"like",t0);
            ncomp = numel(obj.InitialValue);
            te = zeros(0,1,"like",obj.InitialTime);
            ye = zeros(ncomp,0,"like",obj.InitialValue);
            ie = zeros(0,1);
            s = [];
            se = [];
            HAS_EVENTS = ~isempty(obj.EventDefinition);
            HAS_SENSITIVITY = ~isempty(obj.Sensitivity);
            if t1 == t0 && t2 == t0
                solver = matlab.ode.internal.Solver.makeSolver(obj);
                if HAS_SENSITIVITY
                    [t,y,te,ye,ie,s,se] = solver.solve(t0);
                elseif HAS_EVENTS
                    [t,y,te,ye,ie] = solver.solve(t0);
                else
                    [t,y] = solver.solve(t0);
                end
                t = t.';
                te = te.';
                ie = ie.';
                [s,se] = shapeSens(s,se,ncomp);
                sol = matlab.ode.ODEResults(Time=t,Solution=y,...
                    EventTime=te,EventSolution=ye,EventIndex=ie,...
                    Sensitivity=s,EventSensitivity=se,...
                    hasEvents=HAS_EVENTS,hasSensitivity=HAS_SENSITIVITY);
                return
            end
            [tmin,tmax] = bounds([t1,t2]);
            HAS_LEFT = tmin < t0;
            HAS_RIGHT = tmax > t0;
            if HAS_LEFT
                % Instantiate a solver.
                solver = matlab.ode.internal.Solver.makeSolver(obj);
                if HAS_SENSITIVITY
                    [tL,yL,teL,yeL,ieL,sL,seL] = solver.solve(t0,tmin,pps);
                elseif HAS_EVENTS
                    [tL,yL,teL,yeL,ieL] = solver.solve(t0,tmin,pps);
                    sL = s;
                    seL = se;
                else
                    [tL,yL] = solver.solve(t0,tmin,pps);
                    teL = te;
                    yeL = ye;
                    ieL = ie;
                    sL = s;
                    seL = se;
                end
                if HAS_RIGHT
                    % Remove t0
                    yL = yL(:,2:end);
                    tL = tL(2:end);
                    if HAS_SENSITIVITY
                        sL = sL(:,2:end);
                    end
                elseif tmax < t0
                    % Remove leading points up to just before tmax.
                    inearest = find(tL <= tmax,1,'first');
                    tlTruncate = false;
                    if isempty(inearest)
                        % Integration must have failed.
                        yL = zeros(size(yL,1),0,"like",yL);
                        tL = zeros(0,1,"like",tL);
                    elseif tmin == tmax
                        tL = tmax;
                        yL = yL(:,end);
                    elseif tL(inearest) == tmax
                        tlTruncate = true;
                        tL = tL(inearest:end);
                        yL = yL(:,inearest:end);
                    else
                        % tL(inearest - 1) is nearest but larger than tmax.
                        % Remember we are integrating backwards, so tL is
                        % sorted descending.
                        tL = tL(inearest-1:end);
                        yL = yL(:,inearest-1:end);
                        % We need the solution at tmax. Make a short integration to
                        % compute it.
                        [tmax,yL(:,1)] = partialStep(obj,tL(1),yL(:,1),tmax);
                        tL(1) = tmax;
                    end
                    if HAS_SENSITIVITY
                        % NOTE: inearest comes from previous if
                        if isempty(inearest)
                            sL = [];
                        elseif tmin == tmax
                            sL = sL(:,end);
                        elseif tlTruncate
                            sL = sL(:,inearest:end);
                        else
                            sL = sL(:,inearest-1:end);
                            [~,~,~,~,~,tmp,~] = solver.solve(tL(1));
                            sL(:,1) = tmp(:,end);
                        end
                    end
                    if HAS_EVENTS
                        % Remove out-of-range events.
                        inearest = find(teL <= tmax,1,'first');
                        if isempty(inearest)
                            teL = te;
                            yeL = ye;
                            ieL = ie;
                        else
                            teL = teL(inearest:end);
                            ieL = ieL(inearest:end);
                            yeL = yeL(:,inearest:end);
                        end
                        if HAS_SENSITIVITY
                            if isempty(inearest)
                                seL = se;
                            else
                                seL = seL(:,inearest:end);
                            end
                        end
                    end
                end
            end
            if HAS_RIGHT
                % Instantiate a solver.
                solver = matlab.ode.internal.Solver.makeSolver(obj);
                if HAS_SENSITIVITY
                    [tR,yR,teR,yeR,ieR,sR,seR] = solver.solve(t0,tmax,pps);
                elseif HAS_EVENTS
                    [tR,yR,teR,yeR,ieR] = solver.solve(t0,tmax,pps);
                    sR = s;
                    seR = se;
                else
                    [tR,yR] = solver.solve(t0,tmax,pps);
                    teR = te;
                    yeR = ye;
                    ieR = ie;
                    sR = s;
                    seR = se;
                end
                if tmin > t0
                    % Remove leading points up to just before tmin.
                    inearest = find(tR >= tmin,1,'first');
                    trTruncate = false;
                    if isempty(inearest)
                        % Integration must have failed.
                        yR = zeros(size(yR,1),0,"like",yR);
                        tR = zeros(0,1,"like",tR);
                    elseif tmin == tmax
                        tR = tmax;
                        yR = yR(:,end);
                    elseif tR(inearest) == tmin
                        trTruncate = true;
                        tR = tR(inearest:end);
                        yR = yR(:,inearest:end);
                    else
                        % tR(inearest - 1) is nearest but smaller than tmin.
                        tR = tR(inearest-1:end);
                        yR = yR(:,inearest-1:end);
                        % We need the solution at tmin. Make a short integration to
                        % compute it.
                        [tmin,yR(:,1)] = partialStep(obj,tR(1),yR(:,1),tmin);
                        tR(1) = tmin;
                    end
                    if HAS_SENSITIVITY
                        % NOTE: reusing inearest from above
                        if isempty(inearest)
                            sR = [];
                        elseif tmin == tmax
                            sR = sR(:,end);
                        elseif trTruncate
                            sR = sR(:,inearest:end);
                        else
                            sR = sR(:,inearest-1:end);
                            [~,~,~,~,~,tmp,~] = solver.solve(tR(1));
                            sR(:,1) = tmp(:,end);
                        end
                    end
                    if HAS_EVENTS
                        % Remove out-of-range events.
                        inearest = find(teR >= tmin,1,'first');
                        if isempty(inearest)
                            teR = te;
                            yeR = ye;
                            ieR = ie;
                        else
                            teR = teR(inearest:end,1);
                            ieR = ieR(inearest:end,1);
                            yeR = yeR(:,inearest:end);
                        end
                        if HAS_SENSITIVITY
                            if isempty(inearest)
                                seR = se;
                            else
                                seR = seR(:,inearest:end);
                            end
                        end
                    end
                end
            end
            if HAS_LEFT && HAS_RIGHT
                % Splice
                tL = flip(tL,1);
                yL = flip(yL,2);
                teL = flip(teL,1);
                yeL = flip(yeL,2);
                sL = flip(sL,2);
                seL = flip(seL,2);
                t = [tL;tR];
                y = [yL,yR];
                te = [teL;teR];
                ye = [yeL,yeR];
                ie = [ieL;ieR];
                s = [sL,sR];
                se = [seL,seR];
            elseif HAS_LEFT
                t = tL;
                y = yL;
                te = teL;
                ye = yeL;
                ie = ieL;
                s = sL;
                se = seL;
            else
                t = tR;
                y = yR;
                te = teR;
                ye = yeR;
                ie = ieR;
                s = sR;
                se = seR;
            end
            if ~isempty(t) && (t1 <= t2) ~= (t(1) <= t(end))
                % Flip outputs.
                t = flip(t,1);
                y = flip(y,2);
                te = flip(te,1);
                ye = flip(ye,2);
                ie = flip(ie,1);
                s = flip(s,2);
                se = flip(se,2);
            end
            % Make outputs consistent for plot(t,y).
            t = t.';
            te = te.';
            ie = ie.';
            [s,se] = shapeSens(s,se,ncomp);
            sol = matlab.ode.ODEResults(Time=t,Solution=y,...
                EventTime=te,EventSolution=ye,EventIndex=ie,...,...
                Sensitivity=s,EventSensitivity=se,...
                hasEvents=HAS_EVENTS,hasSensitivity=HAS_SENSITIVITY);
        end
        function obj = selectEquationType(obj)
            % Update equation type based on solver selection.
            if obj.Solver == matlab.ode.SolverID.ode15i ...
                    || obj.SelectedSolver == matlab.ode.SolverID.ode15i
                obj.EquationType = "fullyimplicit";
            elseif ( ~isempty(obj.DelayDefinition) && obj.Solver == matlab.ode.SolverID.auto ) || ...
                    any(ismember([obj.Solver obj.SelectedSolver],["dde23","ddesd","ddensd"]))
                obj.EquationType = "delay";
            else
                obj.EquationType = "standard";
            end
        end
        function obj = manageSolverProperties(obj)
            % Perform automatic solver selection, if applicable, and
            % harmonize the Solver, SelectedSolver, and SolverOptions
            % properties. This is a no-op if SyncSettings is false.
            % It is also be a no-op if any of the aforementioned
            % properties is empty.
            if isempty(obj.Solver) || ...
                    isempty(obj.SelectedSolver) || ...
                    isempty(obj.SolverOptions) || ...
                    isempty(obj.SyncSettings) || ...
                    ~obj.SyncSettings
                % Do nothing.
                return
            end
            if isManualSolverSelection(obj.Solver)
                solverID = obj.Solver;
                % Note that manually chosen solver takes precedence over
                % EquationType, will reset if incompatible.
                if ~isEqnAndSolverConsistent(solverID,obj.EquationType)
                    obj = obj.selectEquationType;
                end
            else
                solverID = obj.selectSolver;
            end
            if solverID ~= obj.SelectedSolver
                obj.SelectedSolver = solverID;
                if obj.SolverOptions.ID ~= solverID
                    if ~isempty(obj.SolverOptions) && ~obj.SolverOptions.isDefault
                        warning(message('MATLAB:ode:SolverOptionsReset'));
                    end
                    SavedSyncSettings = obj.SyncSettings;
                    obj.SyncSettings = false; % Don't recurse back here.
                    obj.SolverOptions = matlab.ode.Options.makeSolverOptions(solverID);
                    obj.SyncSettings = SavedSyncSettings;
                end
            end
            % reset equation type now that solver selection is complete
            obj = obj.selectEquationType;
        end
        function assertODEDefined(obj)
            if isempty(obj.ODEFcn)
                error(message('MATLAB:ode:UndefinedODEFcn'));
            end
            if isempty(obj.InitialValue) && ...
                    (obj.EquationType ~= matlab.ode.EquationType.delay) % IV *may* be empty for delay
                error(message('MATLAB:ode:UndefinedInitialValue'));
            end
        end
        function [t1,y1] = partialStep(obj,t0,y0,t1)
            % Step from t0 to t1. Assumes the integrator has successfully
            % stepped beyond t1. We just need the solution at an
            % intermediate point.
            ODE = obj;
            ODE.InitialTime = t0;
            ODE.InitialValue = y0;
            ODE.Solver = ODE.SelectedSolver;
            ODE.EventDefinition = [];
            s = ODE.solveAt(t1);
            t1 = s.Time;
            y1 = s.Solution;
        end
        function objReal = complexToReal(obj)
            % Split real and imaginary parts into separate components. The
            % original, unmodified ode object will be passed to contained
            % objects to provide any context they might need to perform the
            % conversion from complex to real. The partially converted
            % object, objReal, is not made available to contained objects
            % in order that sequencing dependencies not be allowed to creep
            % in over time.
            if isempty(obj.Parameters)
                obj.ComplexToRealParameters = false;
            else
                % Theoretically, we only need to convert the parameters if
                % sensitivity analysis is being performed. However, the
                % implementation of our interface to the SUNDIALS solvers
                % introduces a trade-off. It is more efficient when
                % parameters are numeric vectors. In exchange we cannot
                % allow complex parameter vectors with SUNDIALS solvers
                % even if we are not performing sensitivity analysis.
                obj.ComplexToRealParameters = ~isempty(obj.Sensitivity) || ( ...
                    isfloat(obj.Parameters) && ...
                    isvector(obj.Parameters) && ...
                    isSUNDIALS(obj.SelectedSolver));
            end
            % Proceed with the conversion.
            objReal = obj; % Make a copy.
            objReal.SyncSettings = false; % Do not run selectSolver, need options to be consistent.
            objReal.SeparateComplexParts = "off"; % No recursion, please!
            hasMatrixArgs = obj.EquationType == matlab.ode.EquationType.delay;
            if obj.SelectedSolver == matlab.ode.SolverID.ddensd
                if nargin(obj.ODEFcn) == 5
                    convertArgs = [false,true,true,true,obj.ComplexToRealParameters]; % f(t,y,ydel,ypdel,p)
                else
                    convertArgs = [false,true,true,true]; % f(t,y,ydel,ypdel)
                end
            elseif obj.EquationType == matlab.ode.EquationType.fullyimplicit ...
                    || obj.EquationType == matlab.ode.EquationType.delay
                if nargin(obj.ODEFcn) == 4
                    convertArgs = [false,true,true,obj.ComplexToRealParameters]; % f(t,y,yp,p)
                else
                    convertArgs = [false,true,true]; % f(t,y,yp)
                end
            else
                if nargin(obj.ODEFcn) == 3
                    convertArgs = [false,true,obj.ComplexToRealParameters]; % f(t,y,p)
                else
                    convertArgs = [false,true]; % f(t,y)
                end
            end
            % Convert ODEFcn
            objReal.ODEFcn = matlab.ode.internal.r2cVectorFcn(obj.ODEFcn,convertArgs,hasMatrixArgs);
            % Convert non-object ODE properties.
            objReal.InitialValue = matlab.ode.internal.c2rVector(obj.InitialValue);
            if ~isempty(obj.NonNegativeVariables)
                % Both real and imaginary parts are constrained to be
                % non-negative. This might be useful with explicit solvers
                % that can handle complex values natively.
                idx = obj.NonNegativeVariables(:).'*2;
                idx = [idx-1;idx];
                objReal.NonNegativeVariables = idx(:);
            end
            if ~isempty(obj.InitialSlope)
                objReal.InitialSlope = matlab.ode.internal.c2rVector(obj.InitialSlope);
            end
            if obj.ComplexToRealParameters
                objReal.Parameters = matlab.ode.internal.c2rVector(obj.Parameters);
            end
            if ~isscalar(obj.AbsoluteTolerance)
                % AbsoluteTolerance is already real, but we need to
                % double each element.
                tmp = repmat(obj.AbsoluteTolerance(:).',2,1);
                objReal.AbsoluteTolerance = tmp(:);
            end
            % Convert contained objects.
            if ~isempty(obj.EventDefinition)
                objReal.EventDefinition = obj.EventDefinition.complexToReal(obj);
            end
            if ~isempty(obj.Jacobian)
                objReal.Jacobian = obj.Jacobian.complexToReal(obj);
            end
            if ~isempty(obj.MassMatrix)
                objReal.MassMatrix = obj.MassMatrix.complexToReal(obj);
            end
            if ~isempty(obj.Sensitivity)
                objReal.Sensitivity = obj.Sensitivity.complexToReal(obj);
            end
            if ~isempty(obj.DelayDefinition)
                objReal.DelayDefinition = obj.DelayDefinition.complexToReal(obj);
            end
            objReal.SolverOptions = complexToReal(obj.SolverOptions,obj);
            objReal.SyncSettings = obj.SyncSettings;
        end
        function isStiff = stiffnessHeuristic(obj,intervalLength)
            % compute Jacobian and run through stiffness heuristic
            % reset solver to avoid solver-specific errors for consistency
            % check
            if obj.Solver ~= matlab.ode.SolverID.auto
                % reset options to default before changing solver to avoid
                % warning
                obj.SolverOptions = obj.SolverOptions.makeSolverOptions(obj.SelectedSolver);
                obj.Solver = "auto";
            end
            checkConsistency(obj); % validate problem setup before computing
            if obj.SeparateComplexParts
                obj = complexToReal(obj);
            end
            J = computeJacobianAtIC(obj);
            t0 = obj.InitialTime;
            isStiff = isStiffSystem(J,t0,t0+intervalLength);
        end
        function J = computeJacobianAtIC(obj)
            % compute the Jacobian at the initial conditions
            odeIsFuncHandle = true;
            assert(obj.EquationType ~= matlab.ode.EquationType.fullyimplicit); % expect early return for Implicit
            [odefun,opts,t0,y0,params] = matlab.ode.internal.LegacySolver.packageProblem(obj); % package for Legacy helpers
            [~,J,jargs,jopts] = ...
                odejacobian(odeIsFuncHandle,odefun,t0,y0,opts,params);
            if isempty(J)
                f0 = odefun(t0,y0,params{:});
                J = odenumjac(odefun, {t0,y0,params{:}}, f0, jopts); %#ok<CCAT>
            elseif ~isnumeric(J)
                J = J(t0,y0,jargs{:});
            end
        end
    end

    %% Methods related to custom display

    properties (Hidden, Access=protected)
        name char % to be set to the name the user has given the object at time of display
    end
    methods (Access = protected)
        function displayScalarObject(obj)
            obj.name = inputname(1);
            displayScalarObject@matlab.mixin.CustomDisplay(obj);
        end
        function footer = getFooter(obj)
            var = obj.name;
            cl = class(obj);
            linkcmd = sprintf("if exist('%s','var'), ",var) + ...
                sprintf("ode.displayAll('%s',%s,'%s'); ",var,var,cl) + ...
                sprintf("else, ode.displayAll('%s'), end",var);
            footer = char(sprintf("  Show <a href=""matlab:" + ...
                linkcmd + """>all properties</a>\n\n"));
        end
        function propgrp = getPropertyGroups(obj)
            [problemProperties,unusedProperties] = obj.getProblemProperties;
            problemPropertyGroup = matlab.mixin.util.PropertyGroup( ...
                problemProperties,"<strong>Problem definition</strong>");
            solverProperties = obj.getSolverProperties;
            solverPropertyGroup = matlab.mixin.util.PropertyGroup( ...
                solverProperties,"<strong>Solver properties</strong>");
            propgrp = [problemPropertyGroup,solverPropertyGroup];
            if ~isempty(unusedProperties)
                propgrp(end+1) = matlab.mixin.util.PropertyGroup( ...
                    unusedProperties,sprintf("<strong>Ignored by selected solver</strong> (%s)",obj.SelectedSolver));
            end
        end
    end

    methods (Hidden, Static)
        function displayAll(name,val,classname)
            if nargin > 1
                if ~isa(val,classname)
                    disp(getString(message("MATLAB:graphicsDisplayText:FooterLinkFailureClassMismatch",name,classname)));
                else
                    matlab.mixin.CustomDisplay.displayPropertyGroups(...
                        val,matlab.mixin.util.PropertyGroup(properties(val)));
                end
            else
                disp(getString(message("MATLAB:graphicsDisplayText:FooterLinkFailureMissingVariable",name)));
            end
        end
    end

    methods (Access = private)
        function [problemProperties,unusedProperties] = getProblemProperties(obj)
            unusedProperties = {};
            problemProperties = {'ODEFcn'};
            if obj.usesParameters || ~isempty(obj.Parameters)
                problemProperties{1,end+1} = 'Parameters';
            end
            problemProperties{1,end+1} = 'InitialTime';
            problemProperties{1,end+1} = 'InitialValue';
            % Define some useful constants.
            STIFF = obj.Solver == matlab.ode.SolverID.stiff;
            ODE15s = matlab.ode.SolverID.ode15s;
            ODE23t = matlab.ode.SolverID.ode23t;
            ODE23tb = matlab.ode.SolverID.ode23tb;
            ODE23s = matlab.ode.SolverID.ode23s;
            CVODESS = matlab.ode.SolverID.cvodesStiff;
            CVODESN = matlab.ode.SolverID.cvodesNonstiff;
            IDAS = matlab.ode.SolverID.idas;
            IMPLICIT = obj.EquationType == matlab.ode.EquationType.fullyimplicit;
            DELAY = obj.EquationType == matlab.ode.EquationType.delay;
            IVNDDE = obj.isIVNDDE;
            SOLVER = obj.SelectedSolver;
            STIFFSEL = ...
                STIFF || ...
                SOLVER == ODE15s  || ...
                SOLVER == ODE23t  || ...
                SOLVER == ODE23s  || ...
                SOLVER == ODE23tb || ...
                SOLVER == CVODESS || ...
                SOLVER == IDAS || ...
                IMPLICIT; % used to check for Jacobian, include implicit
            UNUSED_JACOBIAN = ~STIFFSEL;
            UNUSED_INITIALSLOPE = ~( ...
                SOLVER == ODE23s  || ...
                SOLVER == ODE15s  || ...
                SOLVER == ODE23t  || ...
                SOLVER == IDAS || ...
                IVNDDE || ...
                IMPLICIT);
            UNUSED_NONNEGATIVE = ...
                SOLVER == ODE23s || ...
                IMPLICIT || ...
                DELAY;
            USE_SENSE = ...
                SOLVER == CVODESS || ...
                SOLVER == CVODESN || ...
                SOLVER == IDAS;
            UNUSED_MASS = DELAY;
            % Decide whether to display InitialSlope
            if ~isempty(obj.InitialSlope)
                if UNUSED_INITIALSLOPE
                    unusedProperties{1,end+1} = 'InitialSlope';
                else
                    problemProperties{1,end+1} = 'InitialSlope';
                end
            end
            % Decide whether to display Jacobian.
            if isempty(obj.Jacobian)
                if ~UNUSED_JACOBIAN
                    % Show unset Jacobian property in problem group.
                    problemProperties{1,end+1} = 'Jacobian';
                end
            elseif UNUSED_JACOBIAN
                unusedProperties{1,end+1} = 'Jacobian';
            else
                problemProperties{1,end+1} = 'Jacobian';
            end
            % Decide whether to display MassMatrix.
            if ~isempty(obj.MassMatrix)
                if UNUSED_MASS
                    unusedProperties{1,end+1} = 'MassMatrix';
                else
                    problemProperties{1,end+1} = 'MassMatrix';
                end
            end
            % Decide whether to display NonNegativeVariables
            if ~isempty(obj.NonNegativeVariables)
                if UNUSED_NONNEGATIVE
                    unusedProperties{1,end+1} = 'NonNegativeVariables';
                else
                    problemProperties{1,end+1} = 'NonNegativeVariables';
                end
            end
            % Display EventDefinition only if set.
            if ~isempty(obj.EventDefinition)
                problemProperties{1,end+1} = 'EventDefinition';
            end
            % Display Delay information only if set.
            if DELAY
                problemProperties{1,end+1} = 'DelayDefinition';
            elseif ~isempty(obj.DelayDefinition)
                unusedProperties{1,end+1} = 'DelayDefinition';
            end
            % Display Sensitivity only if set.
            if ~isempty(obj.Sensitivity) && USE_SENSE
                problemProperties{1,end+1} = 'Sensitivity';
            elseif ~isempty(obj.Sensitivity)
                unusedProperties{1,end+1} = 'Sensitivity';
            end
            % add EquationType to problem definition
            problemProperties{1,end+1} = 'EquationType';
        end
        function solverProperties = getSolverProperties(obj)
            % property group for information related to solver type
            % used during display
            solverProperties = {};
            solverProperties{1,end+1} = 'AbsoluteTolerance';
            solverProperties{1,end+1} = 'RelativeTolerance';
            if obj.SeparateComplexParts
                solverProperties{1,end+1} = 'SeparateComplexParts';
            end
            solverProperties{1,end+1} = 'Solver';
            if isManualSolverSelection(obj.Solver)
                if ~isempty(obj.SolverOptions) && ~obj.SolverOptions.isDefault
                    solverProperties{1,end+1} = 'SolverOptions';
                end
            elseif ~isempty(obj.ODEFcn) && ~isempty(obj.InitialValue)
                solverProperties{1,end+1} = 'SelectedSolver';
            end
        end
        function val = getDelayInitialValue(obj)
            HAS_DELAY_DEF = ~isempty(obj.DelayDefinition);
            HAS_HISTORY = HAS_DELAY_DEF && ~isempty(obj.DelayDefinition.History);
            if HAS_DELAY_DEF && HAS_HISTORY && isempty(obj.InitialValue)
                % Return history(t0) as initial value if the users has not
                % set initial value
                if isnumeric(obj.DelayDefinition.History)
                    val = obj.DelayDefinition.History;
                elseif nargin(obj.DelayDefinition.History) > 1 && obj.usesParameters
                    val = obj.DelayDefinition.History(obj.InitialTime,obj.Parameters);
                else
                    val = obj.DelayDefinition.History(obj.InitialTime);
                end
                if ~isvector(val) || ~isnumeric(val)
                    error(message("MATLAB:ode:InvalidHistoryFunction"));
                end
            else
                % Return the initial value provided by the user
                assert(~isempty(obj.InitialValue),message("MATLAB:ode:InvalidICDelay")); % should be caught by consistency
                val = obj.InitialValue;
            end
        end
        function tf = checkCIC(obj)
            % helper to decide if consistentInitialConditions must run
            if (obj.SelectedSolver == matlab.ode.SolverID.ode15i) || ...
                    (obj.EquationType == matlab.ode.EquationType.delay && obj.isIVNDDE)
                % may need ICs 
                tf = isprop(obj.SolverOptions,'ComputeConsistentInitialConditions') && ...
                    obj.SolverOptions.ComputeConsistentInitialConditions;
            else
                % don't need ICs
                tf = false;
            end
        end
        function checkConsistency(obj)
            % check properties that need further validation at solve time
            % This should be called before any solver is reached.
            obj.assertODEDefined;
            % nargin checks now that eqn type is known
            nArgs = nargin(obj.ODEFcn);
            useParam = obj.usesParameters;
            if obj.EquationType == matlab.ode.EquationType.standard
                if (~useParam && nArgs ~= 2) || ...
                        (useParam && (nArgs ~= 2 && nArgs ~= 3))
                    error(message("MATLAB:ode:ODENarginStandard"));
                end
            elseif obj.EquationType == matlab.ode.EquationType.delay
                % DelayDefinition can not be empty for delay equations
                if isempty(obj.DelayDefinition)
                    error(message("MATLAB:ode:InvalidDelayDefinition"));
                end
                % History may be excluded only for IVNDDE delay problems
                if ~obj.isIVNDDE && isempty(obj.DelayDefinition.History)
                    error(message("MATLAB:ode:InvalidHistory"));
                end
                % ddensd assumes that at least one delay has been set to do
                % indexing
                if obj.SelectedSolver == matlab.ode.SolverID.ddensd && ...
                    (isempty(obj.DelayDefinition.ValueDelay) && isempty(obj.DelayDefinition.SlopeDelay))
                    error(message("MATLAB:ode:DelayEmpty"));
                end
                % IVNDDE requires an initial value
                if obj.isIVNDDE && isempty(obj.InitialValue)
                    error(message("MATLAB:ode:UndefinedInitialValue"));
                end
                % dde23 can not accept a function handle as ydel
                if obj.SelectedSolver == matlab.ode.SolverID.dde23
                    if isa(obj.DelayDefinition.ValueDelay, "function_handle")
                        error(message("MATLAB:ode:InvalidValueDelayDDE23"));
                    end
                end
            else % implicit
                if (~useParam && nArgs ~= 3) || ...
                        (useParam && (nArgs ~= 3 && nArgs ~= 4))
                    error(message("MATLAB:ode:ODENarginImplicit"));
                end
            end
            % mass cannot be defined when implicit or delay
            if ismember(obj.EquationType,["fullyimplicit","delay"]) ...
                    && ~isempty(obj.MassMatrix)
                error(message("MATLAB:ode:MassImplicit"));
            end
            % Check for non-real data with SUNDIALS solvers
            if isSUNDIALS(obj.SelectedSolver) && ~obj.SeparateComplexParts
                if isfloat(obj.Parameters) && isvector(obj.Parameters) && ~isreal(obj.Parameters)
                    error(message("MATLAB:ode:ParameterVectorMustBeReal",string(obj.SelectedSolver)));
                end
                if ~isreal(obj.InitialValue)
                    error(message("MATLAB:ode:InitialValueMustBeReal",string(obj.SelectedSolver)));
                end
                if ~isreal(obj.InitialSlope)
                    error(message("MATLAB:ode:InitialSlopeMustBeReal",string(obj.SelectedSolver)));
                end
                if ~isempty(obj.Jacobian) && isnumeric(obj.Jacobian.Jacobian) && ~isreal(obj.Jacobian.Jacobian)
                    error(message("MATLAB:ode:JacobianMustBeReal",string(obj.SelectedSolver)));
                end
                if ~isempty(obj.Sensitivity)
                    if ~isreal(obj.Sensitivity.InitialValue)
                        error(message("MATLAB:ode:SensitivityInitialValueMustBeReal",string(obj.SelectedSolver)));
                    end
                    if ~isreal(obj.Sensitivity.InitialSlope)
                        error(message("MATLAB:ode:SensitivityInitialSlopeMustBeReal",string(obj.SelectedSolver)));
                    end
                end
                if ~isempty(obj.MassMatrix) && isnumeric(obj.MassMatrix.MassMatrix) && ...
                        ~isreal(obj.MassMatrix.MassMatrix)
                    error(message("MATLAB:ode:MassMatrixMustBeReal",string(obj.SelectedSolver)));
                end
            end
            % check Jacobian matches equation type - ignore for delay
            if ~isempty(obj.Jacobian) && (obj.EquationType ~= matlab.ode.EquationType.delay)
                jac = obj.Jacobian;
                if obj.EquationType == matlab.ode.EquationType.standard
                    if ~isempty(jac.Jacobian) && ...
                            ~(isa(jac.Jacobian,'function_handle') || isnumeric(jac.Jacobian))
                        error(message("MATLAB:ode:JacIncompatStandard"));
                    elseif ~isempty(jac.SparsityPattern) && ~(isnumeric(jac.SparsityPattern) || islogical(jac.SparsityPattern))
                        error(message("MATLAB:ode:JacSparseIncompatStandard"));
                    end
                else % implicit
                    if ~isempty(jac.Jacobian) && ...
                            ~(isa(jac.Jacobian,'function_handle') || iscell(jac.Jacobian))
                        error(message("MATLAB:ode:JacIncompatImplicit"));
                    elseif ~isempty(jac.SparsityPattern) && ~iscell(jac.SparsityPattern)
                        error(message("MATLAB:ode:JacSparseIncompatImplicit"));
                    end
                    % For the implicit problem, the Jacobian function must
                    % support two outputs. The function can be varargout or
                    % support more. It will be called with two outputs and
                    % will error there if that doesn't work.
                    if ~isempty(jac.Jacobian) && isa(jac.Jacobian,'function_handle') ...
                            && nargout(jac.Jacobian) == 1
                        error(message("MATLAB:ode:JacIncompatFcn"));
                    end
                end
            end
            % check events are set up
            if ~isempty(obj.EventDefinition) && isempty(obj.EventDefinition.EventFcn)
                error(message('MATLAB:ode:NoEventFcn'));
            end
            % check sensitivity
            if ~isempty(obj.Sensitivity) && ~isSUNDIALS(obj.SelectedSolver)
                error(message("MATLAB:ode:UnsupportedSolverSense"));
            end
        end
    end
end

function p = isSame(old,new)
p = isa(new,class(old)) && isequaln(old,new);
end

function p = isManualSolverSelection(solverID)
p = solverID > 0;
end

function p = isEqnAndSolverConsistent(solverID,eqnType)
% lists of solvers consistent with specialized equation types
delaySolvers = ["dde23","ddesd","ddensd"];
implicitSolvers = "ode15i";
p = true;
if eqnType == matlab.ode.EquationType.standard && ...
        ismember(solverID,delaySolvers) || ismember(solverID,implicitSolvers)
    p = false;
elseif eqnType == matlab.ode.EquationType.fullyimplicit && ...
        ~ismember(solverID,implicitSolvers)
    p = false;
elseif eqnType == matlab.ode.EquationType.delay && ...
        ~ismember(solverID,delaySolvers)
    p = false;
end
end

function [s,se] = shapeSens(s,se,nEqn)
nParam = size(s,1)/nEqn;
if ~isempty(s)
    s = reshape(s,nEqn,nParam,[]);
else
    s = zeros(nEqn,nParam,0);
end
if ~isempty(se)
    se = reshape(se,nEqn,nParam,[]);
else
    se = zeros(nEqn,nParam,0);
end
end

function isStiff = isStiffSystem( Jm, t0, tfinal )
% stiffness threshold
threshold = 100;

% stepsize setup
epsTol = eps("like",t0);
safehmax = 16.0*epsTol*max(abs(t0),abs(tfinal));
defaulthmax = max(0.1*(abs(tfinal-t0)),safehmax);
compMaxStepSize = min(abs(tfinal-t0),defaulthmax);

% For a eigenvalue whose condition number is > 100, ignore it
condThreshold = 100;
isStiff = false;
Jm = full(Jm);

% s is the condition number, D is eigen value matrix
[~,D,s] = condeigNoBalance(Jm);

% Ignore eigenvalues over the new threshold as they are very ill-conditioned
n1 = (s < condThreshold);
maxCondNum = max( s(n1) );
if ~isempty( maxCondNum )
    condThreshold = max( condThreshold, 10*maxCondNum );
end

% Only consider eigenvalue with proper condition number and
% the norm of eigenvalue > sqrt(eps(abs(D))
n2 = (s < condThreshold) & (abs(real(D)) > sqrt(eps(1)));
D = D(n2);

% All eigenvalues are ill-conditioned
if isempty(D)
    isStiff = false;
    return;
end

% Real part of eigenvalue
eigenValue_realpart_negative  = D(real(D) < 0);

if (isempty(eigenValue_realpart_negative))
    % This actually means system is unstable, no negative eigenvalue
    stiffness = 0;
elseif isscalar( eigenValue_realpart_negative )
    ratio = abs(1.0/eigenValue_realpart_negative)/compMaxStepSize;
    chokeThreshold = 10;
    if ratio >= chokeThreshold
        stiffness = -1;
    else
        stiffness = abs( eigenValue_realpart_negative );
    end
else
    absVal = abs(eigenValue_realpart_negative);
    maxVal = max( absVal );
    minVal = min( absVal );
    % Use stiff if eigenvalues are big enough
    minEvalThreshold = 1e9;
    if( minVal >= minEvalThreshold )
        stiffness = minVal;
    else
        stiffness = maxVal/ minVal;
    end
end

if stiffness > threshold
    isStiff = true;
end
end

function [X, D, s] = condeigNoBalance(A)
[X, D, Y] = eig(A,"vector","nobalance");
n = size(A,1);
s = zeros(n,1, class(A));
for i=1:n
    s(i) = norm(Y(:,i)) * norm(X(:,i)) / abs( Y(:,i)'*X(:,i) );
end
end

function p = isSUNDIALS(solverID)
p = solverID == matlab.ode.SolverID.cvodesstiff || ...
    solverID == matlab.ode.SolverID.cvodesnonstiff || ...
    solverID == matlab.ode.SolverID.idas;
end

%    Copyright 2022-2024 MathWorks, Inc.