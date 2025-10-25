%matlab.ode.options.IDAS  Solver options for IDAS solver

%   Copyright 2023-2024 MathWorks, Inc.

classdef (Sealed = true) IDAS < matlab.ode.Options
properties
    InitialStep double {mustBeFloat,mustBeReal,mustBeFinite,mustBeScalarOrEmpty} = []
    MaxStep double {mustBeFloat,mustBeReal,mustBeFinite,mustBeScalarOrEmpty} = []
    MaxOrder (1,1) double {mustBeMember(MaxOrder,1:5)} = 5
end
methods
    function obj = IDAS(nv)
        arguments
            nv.?matlab.ode.options.IDAS
        end
        for k=fields(nv)'
            obj.(k{:}) = nv.(k{:});
        end
        obj.ID = matlab.ode.SolverID.idas;
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