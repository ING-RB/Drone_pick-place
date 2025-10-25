classdef DEProblem
    % Internal Only. This is likely to change in a future release of
    % MATLAB.
    % Class to specify a problem compatible with problem.cpp and
    % SimulatorBase

    % Copyright 2011-2024 The MathWorks, Inc. 
    
    properties

        % string name of desired solver, e.g. 'ODE45', 'CVODES'
        SolverName char {mustBeMember(SolverName,{'CVODES','IDAS','DASKR','ODE45','ODE15s'})} = 'CVODES'
        
        % function handle M*dx/dt = DEFun(t, x, p)
        DEFun {mustBeFunctionHandleOrEmpty(DEFun)} = []
        
        % Inputs u = InputFun(t, u, p);
        % Previous u should only be used for preserving value of inputs that
        % are changed by events.  DO NOT u = u+1
        InputFun {mustBeFunctionHandleOrEmpty(InputFun)} = []
        
        % Simulator.run calls [output, continue] = OutputFun(StepData, output)
        % output = [] initially and the final value is returned at the end of run.
        % if (~continue), the simulation will stop immediately.
        % UNUSED except by run_legacy 
        OutputFun
        
        % events
        % trigger = TriggerFun(t, x, u, p);
        % TriggerFun must be continuous and differentiable
        TriggerFun {mustBeFunctionHandleOrEmpty(TriggerFun)} = []
        AtEvent {mustBeMember(AtEvent,[0 1 2])} = 0

        % ==  0 -> any direction is okay
        % ==  1 -> cross zero from negative to positive
        % == -1 -> cross zero from positive to negative
        TriggerDir {mustBeMember(TriggerDir,[0 -1 1])} = 0
        
        % initial conditions
        StartTime (1,1) double {mustBeReal} = 0
        StopTime  (1,1) double {mustBeReal} = 1
        InitialStates (1,:) double {mustBeReal}
        InitialSlope (1,:) double {mustBeReal} 
        InitialInputs (1,:) double {mustBeReal}
        
        % scalar, vector absolute tolerance
        AbsTol (1,:) double {mustBePositive} = 1e-6
        
        % scalar double
        RelTol (1,1) double {mustBePositive} = 1e-3

        % Jacobian in matrix form for constants
        JacobianMatrix double {mustBeReal}
        
        % Function to compute Jacobian d(DEFun)/dx
        % J = JacobianFun(t, x, u, p);
        JacobianFun {mustBeFunctionHandleOrEmpty(JacobianFun)} = []

        % Sparse matrix specifying the sparsity pattern of the Jacobian
        JPattern double {mustBeReal}
        
        % mass matrix, can be sparse or dense
        MassMatrix double {mustBeReal}

        % function returing the mass matrix, can be sparse or dense
        % if sparse, should also have MvPattern
        MassFun {mustBeFunctionHandleOrEmpty(MassFun)} = []

        % sparsity pattern for M(t,y,p)
        MPattern double {mustBeReal}

        % sparsity pattern for d(Mv)/dy
        MvPattern double {mustBeReal}
        
        % function handle to compute df/dp + df/du * du/dp, 
        % ans = SJ(t, x, u, p))
        % size should be (np, nx), np = length(find(SensitivityParameters))
        % --
        % Realistically for coremath purposes, we will think of this
        % as SJ = SJ(t,x,u) and SJ=df/du. Gets used in sundials as part of
        % sensitivity computation to get sdot = df/dx * s + df/du
        SensitivityJacobianFun {mustBeFunctionHandleOrEmpty(SensitivityJacobianFun)} = []

        % For constant sensitivity Jacobian
        SensitivityJacobianMatrix double {mustBeReal}

        % Jpattern for sparse sensitivities. Must be nonempty for this to
        % be sparse.
        SensitivityJPattern double {mustBeReal}

        % Mvpattern for sparse sensitivities. Must be nonempty for this to
        % be sparse. Note, this will only be used if there is a mass matrix
        % and it depends on parameters
        SensitivityMvPattern double {mustBeReal}
        
        % matrix of dx/dp at start time, size(nx, np)
        % nx rows, np cols
        % InitialSensitivity w.r.t. States is always I.  
        % If this is set, the Simulator class will set up everything needed
        % for sensitivity (using numerical Jacobian if one is not
        % provided), and the solver will use it regardless of whether it is
        % being returned from the run method. 
        InitialSensitivity double {mustBeReal}

        % matrix of time derivatives for sensitivities at initial point.
        % Ignored if solver does not work with DAEs
        InitialSensitivitySlope double {mustBeReal}
        
        % Typical values of the parameters used as the denominator for 
        % sensitivity analysis.  This is used to derive error control tolerances
        % integration.
        % should be a vector size(np, 1)
        TypicalParameters (1,:) double {mustBeReal}

        % determines whether to compute data needed to interpolate the
        % solution, e.g. to pass to deval
        ComputeIData (1,1) logical = false

        % When using solver steps, determine how many points to interpolate
        % between steps. Ignored if requesting specific steps from solver
        Refine (1,1) double {mustBeInteger,mustBePositive} = 1

        % Nonnegative - indices of parts of the solution held to be
        % nonnegative
        NonNegative (1,:) double {mustBeInteger,mustBePositive} = []

        % SensitivityIndices - indices of parameters used in sensitivity
        % analysis
        SensitivityIndices (1,:) double {mustBeInteger,mustBePositive} = []

        % guess for first solver step size
        InitialStepSize (1,:) double {mustBeReal} = []

        % MaxStep - maximum step size allowed by solver
        MaxStep double {mustBePositive} = []

        % MaxOrder - maximum order allowed by solver
        MaxOrder double {mustBeInteger,mustBePositive} = []

        % IsStiff - flag to indicate that the equations to be solved are
        % stiff
        IsStiff (1,1) logical = false

        % MStateDependence
        % this is slightly different from its usage in ODE15s. The 'none'
        % case there is automatically handled here by checking nargin. This
        % determines if the true Jacobian or an approximation should be
        % used for residual based solvers (e.g. IDAS). true means use the
        % full Jacobian (like 'strong') and false means use the
        % approximation (like 'weak')
        MStateDependence (1,1) logical = false

        % DAE flag to determine if the matrix to solve is a DAE. Empty
        % indicates that the user has not specified whether the equation is
        % a DAE and we must check, otherwise, no check is done if the value
        % is specified. 
        isDAE logical {mustBeScalarOrEmpty} = []
        
    end

    properties(Hidden)
        % switch to skip validator
        SkipVerification = false;
    end

    properties(Dependent)
        % used by SimulatorBase to determine which mass function to which
        % to dispatch
        MassFunNargin
    end

    methods
        function out = get.MassFunNargin(obj)
            out = nargin(obj.MassFun);
        end
    end
    
    methods
        
        function obj = verify(obj)
            % differential equation function handle
            mustBeA(obj.DEFun,'function_handle'); % check nonempty and function handle by this point
            neq = numel(obj.InitialStates);
            % initial conditions
            if ~isempty(obj.InitialInputs)
                if isempty(obj.TypicalParameters)
                    obj.TypicalParameters = obj.InitialInputs;
                end
                validateattributes(obj.TypicalParameters,{'double'},...
                    {'real','size',[1,numel(obj.InitialInputs)]},'','Parameters');
            end
            % check sens indices and set as default if empty
            if ~isempty(obj.SensitivityIndices) &&...
                    any(obj.SensitivityIndices > numel(obj.InitialInputs))
                error(message("MATLAB:ode:SenseBadParamIndex"));
            end
            if isempty(obj.SensitivityIndices)
                numSens = numel(obj.InitialInputs);
            else
                numSens = numel(obj.SensitivityIndices);
            end
            if ~isempty(obj.InitialSensitivity)
                validateattributes(obj.InitialSensitivity,{'double'},...
                    {'2d','real','size',[neq,numSens]},'','Sensitivity.InitialValue');
            end
            if ~isempty(obj.InitialSensitivitySlope)
                validateattributes(obj.InitialSensitivitySlope,{'double'},...,
                    {'2d','real','size',[neq,numSens]},'','Sensitivity.InitialSlope');
            end
            if (~isa(obj.AbsTol,'function_handle'))
                validateattributes(obj.AbsTol,{'double'},{'positive','row'},...
                    '','AbsoluteTolerance');
            end
            % Mass, Jac, and Sensitivity Jac functions
            if ~isempty(obj.JacobianFun)
                error(nargchk(3,3,nargin(obj.JacobianFun))); %#ok<NCHKN>
            elseif ~isempty(obj.JPattern)
                obj.JPattern = validatePattern(obj,obj.JPattern,[],'Jacobian');
            end
            if ~isempty(obj.MassFun)
                % skip validation for MPattern - unused
                error(nargchk(1,3,nargin(obj.MassFun))); %#ok<NCHKN>
            end
            if ~isempty(obj.MvPattern)
                obj.MvPattern = validatePattern(obj,obj.MvPattern,[],'MvPattern');
            end
            if ~isempty(obj.SensitivityJacobianFun)
                error(nargchk(1,3,nargin(obj.SensitivityJacobianFun))); %#ok<NCHKN>
            elseif ~isempty(obj.SensitivityJPattern)
                obj.SensitivityJPattern = validatePattern(obj,obj.SensitivityJPattern,...
                    [neq numSens],'Sensitivity.Jacobian');
            end
            % Mass, Jac, and Sensitivity Jac matrices
            msize = [0 0];
            if ~isempty(obj.MassMatrix)
                msize = [neq neq];
            end
            jsize = [0 0];
            if ~isempty(obj.JacobianMatrix)
                jsize = [neq neq];
            end
            validateattributes(obj.MassMatrix,{'double'},{'square','size',msize},'','MassMatrix');
            validateattributes(obj.JacobianMatrix,{'double'},{'square','size',jsize},'','Jacobian');
            if ~isempty(obj.SensitivityJacobianMatrix) % only check if nonempty, since need to give explicit size
                validateattributes(obj.SensitivityJacobianMatrix,{'double'},...
                    {'size',[neq numSens]},'','Sensitivity.Jacobian');
            end
            if ~isempty(obj.SensitivityMvPattern) % only check if nonempty, since need to give explicit size
                validateattributes(obj.SensitivityMvPattern,{'double'},...
                    {'size',[neq numSens]},'','Sensitivity.MvPattern');
            end
            if ~isempty(obj.InitialStepSize)
                validateattributes(obj.InitialStepSize,{'double'},...
                    {'real','size',[1,1]},'','InitialStep');
            end
            if ~isempty(obj.InitialSlope)
                validateattributes(obj.InitialSlope,{'double'},...
                    {'real','size',[1,neq]},'','InitialSlope');
            end
            if ~isempty(obj.NonNegative) && any(obj.NonNegative > neq)
                error(message("MATLAB:ode:NonnegBadIndex"));
            end
            if isempty(obj.isDAE)
                obj = checkForDAE(obj);
            end
        end
        
    end

    methods(Hidden,Access=private)
        
        function pat = validatePattern(~,pat,size,name)
            % return obj to keep cast to sparse. Makes more sense to cast
            % instead of error. 
            if ~isempty(pat)
                sizecheck = {'square'};
                if ~isempty(size)
                    sizecheck = {'size',[size(1),size(2)]};
                end
                validateattributes(pat,{'double'},[sizecheck(:)',{'nonnan'}],'',name);
                pat = sparse(pat);
            end
        end

        function obj = checkForDAE(obj)
            % Initial checks to see if the problem being solved is a DAE
            if ~isempty(obj.MassMatrix)
                M = obj.MassMatrix;
            elseif ~isempty(obj.MassFun)
                args = {obj.StartTime};
                if obj.MassFunNargin > 1
                    args{end+1} = obj.InitialStates.';
                end
                if obj.MassFunNargin > 2
                    args{end+1} = obj.InitialInputs.';
                end
                M = obj.MassFun(args{:});
            else
                obj.isDAE = false;
                return;
            end
            nz = nnz(M);
            if nz == 0
                error(message("MATLAB:ode:MassAllZero"));
            end
            obj.isDAE = eps*nz*condest(M) > 1;
        end

    end
    
end

function mustBeFunctionHandleOrEmpty(fh)
mustBeA(fh,{'function_handle','double'});
if ~isempty(fh)
    mustBeA(fh,'function_handle');
end
end
