
%   Copyright 2023-2024 MathWorks, Inc.

classdef (Sealed = true) ODE15s < matlab.ode.Options
    properties
        InitialStep{mustBeFloat,mustBeReal,mustBeFinite,mustBeScalarOrEmpty} = [] % Suggested initial step size  [ positive scalar ]
        MaxStep{mustBeFloat,mustBeReal,mustBeFinite,mustBeScalarOrEmpty} = [] % Upper bound on step size  [ positive scalar ]
        MinStep{mustBeFloat,mustBeReal,mustBeFinite,mustBeScalarOrEmpty} = [] % Lower bound on step size  [ positive scalar ]
        NormControl(1,1) matlab.lang.OnOffSwitchState = "off" % Control error relative to norm of solution [ on | {off} ]
        OutputFcn = [] % Installable output function  [ function_handle ]
        OutputSelection = [] % Output selection indices  [ vector of integers ]
        Vectorization(1,1) matlab.lang.OnOffSwitchState = "off" % Vectorized ODE function [ on, {off} ]
        BDF(1,1) matlab.lang.OnOffSwitchState = "off" % Use Backward Differentiation Formulas in ODE15S  [ on | {off} ]
        MaxOrder(1,1){mustBeMember(MaxOrder,1:5)} = 5 % Maximum order of ODE15S and ODE15I [ 1 | 2 | 3 | 4 | {5} ]
    end
    methods
        function obj = ODE15s(nv)
            arguments
                nv.?matlab.ode.options.ODE15s
            end
            for k=fields(nv)'
                obj.(k{:}) = nv.(k{:});
            end
            obj.ID = matlab.ode.SolverID.ode15s;
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
                isequal(obj.BDF,matlab.lang.OnOffSwitchState.off) && ...
                isequal(obj.Vectorization,matlab.lang.OnOffSwitchState.off);
        end
        function obj = complexToReal(obj,ODE)
            obj = matlab.ode.internal.legacyOptionsComplexToReal(obj,ODE);
        end
    end
end
