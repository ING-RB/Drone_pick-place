%matlab.ode.options.CVODESStiff  Solver options for CVODES stiff solver

%   Copyright 2023-2024 MathWorks, Inc.

classdef (Sealed = true) CVODESStiff < matlab.ode.Options
properties
    InitialStep double {mustBeFloat,mustBeReal,mustBeFinite,mustBeScalarOrEmpty} = []
    MaxStep double {mustBeFloat,mustBeReal,mustBeFinite,mustBeScalarOrEmpty} = []
    MaxOrder (1,1) double {mustBeMember(MaxOrder,1:5)} = 5
end
methods
    function obj = CVODESStiff(nv)
        arguments
            nv.?matlab.ode.options.CVODESStiff
        end
        for k=fields(nv)'
            obj.(k{:}) = nv.(k{:});
        end
        obj.ID = matlab.ode.SolverID.cvodesStiff;
    end
end
methods (Access = {?ode,?matlab.ode.Options},Hidden)
    function p = isDefault(obj)
        p = isempty(obj.InitialStep) && ...
                isempty(obj.MaxStep) && ...
                isequal(obj.MaxOrder,5);
    end
    function obj = complexToReal(obj,~)
    end
end
end