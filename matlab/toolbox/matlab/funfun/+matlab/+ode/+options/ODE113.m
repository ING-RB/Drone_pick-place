%matlab.ode.options.ODE113  Solver options for ode113 solver
%   obj = matlab.ode.options.ODE113 creates the solver options object
%   with default property values.
%
%   obj = matlab.ode.options.ODE113(...,Name=Value) sets the property NAME
%   to VALUE.
%
%   matlab.ode.options.ODE113 properties:
%        NormControl - ["on" | "off" (default)]
%                      Control error relative to norm of solution. Set this
%                      property to "on" to request that solvers control the
%                      error in each integration step with norm(e) <=
%                      max(RelTol*norm(y),AbsTol). By default the solvers
%                      use a more stringent component-wise error control.
%
%          OutputFcn - [function_handle]
%                      The output function is called by the solver after
%                      each time step. You can write a custom output
%                      function to plot or analyze data available in the
%                      intermediate steps.
%
%    OutputSelection - [vector of integers]
%                      Vector of indices that specify which components of
%                      the solution vector are passed to the OutputFcn. The
%                      default is to pass all components.
%
%        InitialStep - [positive scalar]
%                      The solver attempts to use the specified initial
%                      step size first, but adjusts it if needed to meet
%                      error tolerances. By default the solver determines
%                      an initial step size automatically.
%
%            MaxStep - [positive scalar]
%                      MaxStep provides an upper bound for the size of a
%                      step. The default is one-tenth of the tspan interval
%                      for all solvers.
%
%   See also ode, odeJacobian, odeEventDefinition, odeMassMatrix, odeset

%   Copyright 2023-2024 MathWorks, Inc.

classdef (Sealed = true) ODE113 < matlab.ode.internal.LegacyNonstiffSolverOptions
    methods
        function obj = ODE113(nv)
            arguments
                nv.?matlab.ode.options.ODE113
            end
            for k=fields(nv)'
                obj.(k{:}) = nv.(k{:});
            end
            obj.ID = matlab.ode.SolverID.ode113;
        end
    end
end
