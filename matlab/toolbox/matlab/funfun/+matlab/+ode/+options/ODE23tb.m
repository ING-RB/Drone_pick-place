%matlab.ode.options.ODE23tb  Solver options for ode23t solver
%   obj = matlab.ode.options.ODE23tb creates the solver options object
%   with default property values.
%
%   obj = matlab.ode.options.ODE23tb(...,Name=Value) sets the property NAME
%   to VALUE.
%
%   matlab.ode.options.ODE23tb properties:
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
%      Vectorization - ["on" | "off" (default)]
%                      Set the Vectorization mode to "on" if the ODE
%                      function F is coded so that F(t,[y1 y2 ...]) returns
%                      [F(t,y1) F(t,y2) ...].
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

classdef (Sealed = true) ODE23tb < matlab.ode.internal.LegacyStiffSolverOptions
    methods
        function obj = ODE23tb(nv)
            arguments
                nv.?matlab.ode.options.ODE23tb
            end
            for k=fields(nv)'
                obj.(k{:}) = nv.(k{:});
            end
            obj.ID = matlab.ode.SolverID.ode23tb;
        end
    end
end
