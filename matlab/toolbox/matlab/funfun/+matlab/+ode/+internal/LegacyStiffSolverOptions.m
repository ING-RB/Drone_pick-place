%matlab.ode.internal.LegacyStiffSolverOptions  Solver options common to most stiff MATLAB ODE solvers

%    Copyright 2023-2024 MathWorks, Inc.

classdef LegacyStiffSolverOptions < matlab.ode.Options
    properties
        InitialStep{mustBeFloat,mustBeReal,mustBeFinite,mustBeScalarOrEmpty} = [] % Suggested initial step size  [ positive scalar ]
        MaxStep{mustBeFloat,mustBeReal,mustBeFinite,mustBeScalarOrEmpty} = [] % Upper bound on step size  [ positive scalar ]
        MinStep{mustBeFloat,mustBeReal,mustBeFinite,mustBeScalarOrEmpty} = [] % Lower bound on step size  [ positive scalar ]
        NormControl(1,1) matlab.lang.OnOffSwitchState = "off" % Control error relative to norm of solution [ on | {off} ]
        OutputFcn = [] % Installable output function  [ function_handle ]
        OutputSelection = [] % Output selection indices  [ vector of integers ]
        Vectorization(1,1) matlab.lang.OnOffSwitchState = "off" % Vectorized ODE function [ on, {off} ]
    end
    properties (SetAccess = protected, NonCopyable)
    end
    methods
        function obj = LegacyStiffSolverOptions(nv)
            arguments
                nv.?matlab.ode.internal.LegacyStiffSolverOptions
            end
            for k=fields(nv)'
                obj.(k{:}) = nv.(k{:});
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
                isequal(obj.Vectorization,matlab.lang.OnOffSwitchState.off);
        end
        function obj = complexToReal(obj,ODE)
            obj = matlab.ode.internal.legacyOptionsComplexToReal(obj,ODE);
        end
    end
end
