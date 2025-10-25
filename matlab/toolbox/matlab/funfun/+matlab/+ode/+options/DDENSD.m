classdef (Sealed = true) DDENSD < matlab.ode.Options
    properties
        InitialStep{mustBeFloat,mustBeReal,mustBeFinite,mustBeScalarOrEmpty} = [] % Suggested initial step size  [ positive scalar ]
        MaxStep{mustBeFloat,mustBeReal,mustBeFinite,mustBeScalarOrEmpty} = [] % Upper bound on step size  [ positive scalar ]
        MinStep{mustBeFloat,mustBeReal,mustBeFinite,mustBeScalarOrEmpty} = [] % Lower bound on step size  [ positive scalar ]
        NormControl(1,1) matlab.lang.OnOffSwitchState = "off" % Control error relative to norm of solution [ on | {off} ]
        OutputFcn = [] % Installable output function  [ function_handle ]
        OutputSelection = [] % Output selection indices  [ vector of integers ]
        ComputeConsistentInitialConditions (1,1) logical = true % Enable computing consistent ICs automatically at solve
    end
    methods
        function obj = DDENSD(nv)
            arguments
                nv.?matlab.ode.options.DDENSD
            end
            obj.ID = matlab.ode.SolverID.ddensd;
            for k=fields(nv)'
                obj.(k{:}) = nv.(k{:});
            end
        end
    end
    methods (Access = {?ode,?matlab.ode.Options},Hidden)
        function p = isDefault(obj)
            p = isempty(obj.InitialStep) && ...
                isempty(obj.MaxStep) && ...
                isequal(obj.NormControl,matlab.lang.OnOffSwitchState.off) && ...
                isempty(obj.OutputFcn) && ...
                isempty(obj.OutputSelection) && ...
                isempty(obj.MinStep) && ...
                isequal(obj.ComputeConsistentInitialConditions,true);
        end
        function obj = complexToReal(obj,ODE)
            obj = matlab.ode.internal.legacyOptionsComplexToReal(obj,ODE);
        end
    end
end

%    Copyright 2024 MathWorks, Inc.