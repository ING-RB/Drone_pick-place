%matlab.ode.options  Abstract class for solver settings objects.

%    Copyright 2023-2024 MathWorks, Inc.

classdef (Abstract) Options
    properties (SetAccess = protected,Hidden)
        ID matlab.ode.SolverID
        DefaultRefine(1,1){mustBePositive,mustBeInteger} = 1;
    end
    methods (Abstract,Access = {?ode,?matlab.ode.Options},Hidden)
        isDefault(obj);
        complexToReal(obj,ODE);
    end
    methods (Static,Hidden)
        function obj = makeSolverOptions(solverid,varargin)
            switch solverid
                case matlab.ode.SolverID.ode23
                    obj = matlab.ode.options.ODE23(varargin{:});
                case matlab.ode.SolverID.ode23t
                    obj = matlab.ode.options.ODE23t(varargin{:});
                case matlab.ode.SolverID.ode23s
                    obj = matlab.ode.options.ODE23s(varargin{:});
                case matlab.ode.SolverID.ode23tb
                    obj = matlab.ode.options.ODE23tb(varargin{:});
                case matlab.ode.SolverID.ode78
                    obj = matlab.ode.options.ODE78(varargin{:});
                case matlab.ode.SolverID.ode89
                    obj = matlab.ode.options.ODE89(varargin{:});
                case matlab.ode.SolverID.ode113
                    obj = matlab.ode.options.ODE113(varargin{:});
                case matlab.ode.SolverID.ode15s
                    obj = matlab.ode.options.ODE15s(varargin{:});
                case matlab.ode.SolverID.cvodesStiff
                    obj = matlab.ode.options.CVODESStiff(varargin{:});
                case matlab.ode.SolverID.cvodesNonstiff
                    obj = matlab.ode.options.CVODESNonstiff(varargin{:});
                case matlab.ode.SolverID.idas
                    obj = matlab.ode.options.IDAS(varargin{:});
                case matlab.ode.SolverID.ode15i
                    obj = matlab.ode.options.ODE15i(varargin{:});
                case matlab.ode.SolverID.dde23
                    obj = matlab.ode.options.DDE23(varargin{:});
                case matlab.ode.SolverID.ddesd
                    obj = matlab.ode.options.DDESD(varargin{:});
                case matlab.ode.SolverID.ddensd
                    obj = matlab.ode.options.DDENSD(varargin{:});
                otherwise % matlab.ode.SolverID.ode45
                    obj = matlab.ode.options.ODE45(varargin{:});
            end
        end
    end
end
