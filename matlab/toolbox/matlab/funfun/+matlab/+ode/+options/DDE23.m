classdef (Sealed = true) DDE23 < matlab.ode.Options
    properties
        InitialStep{mustBeFloat,mustBeReal,mustBeFinite,mustBeScalarOrEmpty} = [] % Suggested initial step size  [ positive scalar ]
        MaxStep{mustBeFloat,mustBeReal,mustBeFinite,mustBeScalarOrEmpty} = [] % Upper bound on step size  [ positive scalar ]
        MinStep{mustBeFloat,mustBeReal,mustBeFinite,mustBeScalarOrEmpty} = [] % Lower bound on step size  [ positive scalar ]
        NormControl(1,1) matlab.lang.OnOffSwitchState = "off" % Control error relative to norm of solution [ on | {off} ]
        OutputFcn = [] % Installable output function  [ function_handle ]
        OutputSelection = [] % Output selection indices  [ vector of integers ]
        Jumps{mustBeFloat,mustBeReal,mustBeFinite,mustBeVector(Jumps,"allow-all-empties")} = []
    end
    methods
        function obj = DDE23(nv)
            arguments
                nv.?matlab.ode.options.DDE23
            end
            obj.ID = matlab.ode.SolverID.dde23;
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
                isempty(obj.MinStep) && ...
                isempty(obj.OutputSelection) && ...
                isempty(obj.Jumps);
        end
        function obj = complexToReal(obj,ODE)
            obj = matlab.ode.internal.legacyOptionsComplexToReal(obj,ODE);
        end
    end
end

%    Copyright 2024 MathWorks, Inc.