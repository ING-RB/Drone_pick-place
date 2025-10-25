%matlab.ode.internal.SolverPair  ODE object with left and right solvers

%    Copyright 2023 MathWorks, Inc.

classdef SolverPair
    properties
        Domain(1,2){mustBeFloat,mustBeReal,mustBeVector,mustBeNonNan} = [-inf,inf]
    end

    properties (Access = {?ode})
        InitialTime
        InitialValue
        rSolver = []
        lSolver = []
    end

    methods
        function obj = SolverPair(varargin)
            if nargin == 1
                ODE = varargin{1};
                obj.InitialTime = ODE.InitialTime;
                obj.InitialValue = ODE.InitialValue;
                obj.rSolver = matlab.ode.internal.Solver.makeSolver(ODE);
                obj.lSolver = matlab.ode.internal.Solver.makeSolver(ODE);
            else
                % only used for constructing loaded SolverPairs
                assert(nargin==5);
                obj.InitialTime = varargin{1};
                obj.InitialValue = varargin{2};
                obj.rSolver = varargin{3};
                obj.lSolver = varargin{4};
                obj.Domain = varargin{5};
            end
        end
        function [obj,y,yp] = evaluate(obj,t,idx)
            % Evaluate the solution at time t. If idx is supplied, only
            % return solution components y(idx).
            arguments
                obj
                t {mustBeReal,mustBeNumericOrLogical}
                idx = [];
            end
            t = cast(t,'like',obj.InitialTime);
            % Evaluate the solution at time t. If idx is supplied, only
            % return solution components y(idx). This function uses the
            % cached solution, extending it if needed. The derivative is
            % evaluated by interpolation.
            narginchk(2,3)
            t0 = obj.InitialTime;
            y0 = obj.InitialValue;
            ny0 = numel(y0);
            if nargin == 3
                ncomponents = numel(idx);
                idxArg = {idx};
            else
                ncomponents = ny0;
                idxArg = {};
            end
            % Don't extend or evaluate outside of the domain.
            undef = t < obj.Domain(1) | t > obj.Domain(2);
            t(undef) = nan;
            % Extend if needed.
            [tmin,tmax] = bounds(t(:));
            NANWARN = false;
            if isnan(tmin)
                if any(undef)
                    % Some points were out, but only NaNs remain. 
                    NANWARN = true;
                else
                    % Input is all NaNs. Output is all NaNs. No warning.
                end
                tR = tmax;
            else
                [obj,tL,tR] = obj.extend(tmin,tmax);
                if tL > tmin
                    t(t < tL) = nan;
                    NANWARN = true;
                end
                if tR < tmax
                    t(t > tR) = nan;
                    NANWARN = true;
                end
            end
            if NANWARN
                warning(message("MATLAB:ode:DomainWarning",sprintf('%g',obj.Domain(1)),sprintf('%g',obj.Domain(2))));
            end
            nt = numel(t);
            szyk = [ncomponents,1];
            y = zeros([ncomponents,nt],'like',y0);
            if tR == t0
                % integrating left, rSolver will not have used 'extend', so
                % make sure that lSolver is used in this case.
                isOnTheLeft = @(t)le(t,t0);
                isOnTheRight = @(t)gt(t,t0);
            else
                isOnTheLeft = @(t)lt(t,t0);
                isOnTheRight = @(t)ge(t,t0);
            end
            if nargout > 2
                yp = y;
                for k = 1:numel(t)
                    if isOnTheLeft(t(k))
                        [obj.lSolver,yk,ypk] = obj.lSolver.evaluate(t(k),idxArg{:});
                    elseif isOnTheRight(t(k))
                        [obj.rSolver,yk,ypk] = obj.rSolver.evaluate(t(k),idxArg{:});
                    else
                        yk = nan(szyk,'like',y0);
                        ypk = nan(szyk,'like',y0);
                    end
                    y(:,k) = yk(:);
                    yp(:,k) = ypk(:);
                end
            else
                for k = 1:numel(t)
                    if isOnTheLeft(t(k))
                        [obj.lSolver,yk] = obj.lSolver.evaluate(t(k),idxArg{:});
                    elseif isOnTheRight(t(k))
                        [obj.rSolver,yk] = obj.rSolver.evaluate(t(k),idxArg{:});
                    else
                        yk = nan(szyk,'like',y0);
                    end
                    y(:,k) = yk(:);
                end
            end
        end
        function [t,y,te,ye,ie,s,se] = getCachedSolution(obj)
            % Solve the ODE using the cache.
            if isa(obj.lSolver,"matlab.ode.internal.DESolver")
                [tL,yL,teL,yeL,ieL,sL,seL] = obj.lSolver.getCachedSolution;
                [tR,yR,teR,yeR,ieR,sR,seR] = obj.rSolver.getCachedSolution;
                s = [sL(:,1:end-1),sR];
                se = [seL,seR];
            else
                [tL,yL,teL,yeL,ieL] = obj.lSolver.getCachedSolution;
                [tR,yR,teR,yeR,ieR] = obj.rSolver.getCachedSolution;
            end
            t = [tL(1:end-1);tR];
            y = [yL(:,1:end-1),yR];
            te = [teL;teR];
            ye = [yeL,yeR];
            ie = [ieL;ieR];
        end
        function [obj,tmin,tmax] = extend(obj,t1,t2)
            tmin = obj.lSolver.TMax;
            tmax = obj.rSolver.TMax;
            [t1,t2] = bounds([t1,t2]); % This might be unnecessary.
            t1 = max(t1,obj.Domain(1));
            t2 = min(t2,obj.Domain(2));
            if t1 < tmin
                [obj.lSolver,tmin] = obj.lSolver.extend(t1);
                if tmin > t1
                    % This could be due to an integration failure or to a
                    % terminal event. Either way, this is the end of the
                    % road--further extension in this direction is not
                    % permitted. If the EventDefinition is changed, the
                    % solution will be cleared, and the Domain will be
                    % reset.
                    obj.Domain(1) = tmin;
                end
            end
            if t2 > tmax
                [obj.rSolver,tmax] = obj.rSolver.extend(t2);
                if tmax < t2
                    % See comment above on tmin > t1.
                    obj.Domain(2) = tmax;
                end
            end
        end
    end

    properties(Constant,Hidden)
        % 1.0 : Initial version (R2023b)
        Version = 1.0;
    end

    methods (Hidden)
        function b = saveobj(a)
            % Save all properties to struct. 
            b = ode.assignProps(a,false,"matlab.ode.internal.SolverPair");
            % Keep track of versioning information.
            b.CompatibilityHelper.versionSavedFrom = a.Version;
            b.CompatibilityHelper.minCompatibleVersion = 1.0;
        end
    end

    methods (Hidden,Static)
        function b = loadobj(a)
            if matlab.ode.internal.SolverPair.Version < a.CompatibilityHelper.minCompatibleVersion
                warning(message("MATLAB:ode:MinVersionIncompat","matlab.ode.internal.SolverPair"));
                b = matlab.ode.internal.SolverPair(ode());
                return
            end
            % use the constructor to make 
            b = matlab.ode.internal.SolverPair(a.InitialTime,a.InitialValue,a.rSolver,a.lSolver,a.Domain);
        end
    end
end
