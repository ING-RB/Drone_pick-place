%matlab.ode.internal.Solver  ODE Solver Interface

%    Copyright 2023 MathWorks, Inc.

classdef (Abstract) Solver
    properties (SetAccess = protected)
        ID matlab.ode.SolverID
        TMax % Farthest extent of cached/saved solution, if any.
    end
    methods
        function obj = Solver(name,varargin) %#ok<INUSD>
        end
    end
    methods (Static)
        function obj = makeSolver(ODE)
            arguments
                ODE ode
            end
            if ismember(ODE.SelectedSolver,[10 11 12]) 
                obj = matlab.ode.internal.DESolver(ODE);
            else
                obj = matlab.ode.internal.LegacySolver(ODE);
            end
        end
    end
    methods (Abstract)
        [t,y,te,ye,ie,s,se] = solve(obj,t,tend,pps)
        % Solve the ODE without an internal cache.
        % * When both t and tend are supplied, both are scalar, and t
        %   is guaranteed to be t0. Output should be returned at
        %   solversteps between t0 and tend interpolated at
        %   pps evenly-spaced points for each step.
        % * If only t is supplied and it is scalar, return output only
        %   at t, but detect and return events, if applicable, between
        %   t0 and t.
        % * If only t is supplied and it is non-scalar, it is
        %   guaranteed to be sorted, unique, and non-empty with
        %   t(1) = t0.
        [obj,tfarthest] = extend(obj,t)
        % Extend the internal solution cache to t, if possible.
        % Returns the actual farthest point reached, which might not be
        % all the way to the input value in the case of terminal events
        % or integration failures. The solver is only required to
        % extend on one direction, either t > t0 or t < t0, never both
        % in the same instance.
        [obj,y,yp] = evaluate(obj,t,idx)
        % Evaluate using the internal solution cache at time value t,
        % where t can be an array of any size or shape. If not all
        % solution components are needed, the desired components can be
        % supplied in the optional third input. Columns y(:,k) and
        % yp(:,k) are the solution and derivative, respectively, at
        % time t(k). The ODE class will ensure that the solution has
        % been extended to cover the range of t values.
        [t,y,te,ye,ie,s,se] = getCachedSolution(obj)
        % Return the cached solution at solver steps.
        % t must be sorted ascending, y(:,k) corresponds to t(k).
        % t is never empty. Either t(1) == t0 or t(end) == t0.
    end
end
