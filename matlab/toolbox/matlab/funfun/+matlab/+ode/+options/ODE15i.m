classdef (Sealed = true) ODE15i < matlab.ode.Options
    properties
        InitialStep{mustBeFloat,mustBeReal,mustBeFinite,mustBeScalarOrEmpty} = [] % Suggested initial step size  [ positive scalar ]
        MaxStep{mustBeFloat,mustBeReal,mustBeFinite,mustBeScalarOrEmpty} = [] % Upper bound on step size  [ positive scalar ]
        MinStep{mustBeFloat,mustBeReal,mustBeFinite,mustBeScalarOrEmpty} = [] % Lower bound on step size  [ positive scalar ]
        NormControl(1,1) matlab.lang.OnOffSwitchState = "off" % Control error relative to norm of solution [ on | {off} ]
        OutputFcn = [] % Installable output function  [ function_handle ]
        OutputSelection = [] % Output selection indices  [ vector of integers ]
        Vectorization = {matlab.lang.OnOffSwitchState.off,matlab.lang.OnOffSwitchState.off} 
        MaxOrder(1,1){mustBeMember(MaxOrder,1:5)} = 5 % Maximum order of ODE15I [ 1 | 2 | 3 | 4 | {5} ]
        ComputeConsistentInitialConditions (1,1) logical = true % Enable computing consistent ICs automatically at solve
    end
    methods
        function obj = ODE15i(nv)
            arguments
                nv.?matlab.ode.options.ODE15i
            end
            obj.ID = matlab.ode.SolverID.ode15i;
            for k=fields(nv)'
                obj.(k{:}) = nv.(k{:});
            end
        end
        function obj = set.Vectorization(obj,vec)
            % Special setter so we only allow through scalars or cell
            % arrays with two elements containing something convertible to
            % on/off. For convenience, expand scalar to a cell array here.
            try
                if iscell(vec)
                    assert(numel(vec) == 2);
                    vec{1} = matlab.lang.OnOffSwitchState(vec{1});
                    vec{2} = matlab.lang.OnOffSwitchState(vec{2});
                else
                    vec = matlab.lang.OnOffSwitchState(vec);
                    vec = {vec,vec};
                end
                obj.Vectorization = vec;
            catch ME
                error(message("MATLAB:ode:InvalidImplicitVec","ode15i"));
            end
        end
    end
    methods (Access = {?ode,?matlab.ode.Options},Hidden)
        function p = isDefault(obj)
            p = isempty(obj.InitialStep) && ...
                isempty(obj.MaxStep) && ...
                isempty(obj.MinStep) && ...
                isequal(obj.NormControl,matlab.lang.OnOffSwitchState.off) && ...
                isempty(obj.OutputFcn) && ...
                isempty(obj.OutputSelection) && ...
                isequal(obj.MaxOrder,5) && ...
                isequal(obj.Vectorization,{matlab.lang.OnOffSwitchState.off,matlab.lang.OnOffSwitchState.off}) && ...
                isequal(obj.ComputeConsistentInitialConditions,true);
        end
        function obj = complexToReal(obj,ODE)
            obj = matlab.ode.internal.legacyOptionsComplexToReal(obj,ODE);
        end
    end
end

%    Copyright 2024 MathWorks, Inc.