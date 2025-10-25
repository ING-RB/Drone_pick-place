%matlab.ode.options.CVODESNonstiff  Solver options for CVODES nonstiff solver

%   Copyright 2023-2024 MathWorks, Inc.

classdef (Sealed = true) CVODESNonstiff < matlab.ode.Options
properties
    InitialStep double {mustBeFloat,mustBeReal,mustBeFinite,mustBeScalarOrEmpty} = []
    MaxStep double {mustBeFloat,mustBeReal,mustBeFinite,mustBeScalarOrEmpty} = []
    MaxOrder (1,1) double {mustBeMember(MaxOrder,1:12)} = 12
end
methods
    function obj = CVODESNonstiff(nv)
        arguments
            nv.?matlab.ode.options.CVODESNonstiff
        end
        for k=fields(nv)'
            obj.(k{:}) = nv.(k{:});
        end
        obj.ID = matlab.ode.SolverID.cvodesNonstiff;
    end
end
methods (Access = {?ode,?matlab.ode.Options},Hidden)
    function p = isDefault(obj)
        p = isempty(obj.InitialStep) && ...
            isempty(obj.MaxStep) && ...
            isequal(obj.MaxOrder,12);
    end
    function obj = complexToReal(obj,~)
    end
end
end