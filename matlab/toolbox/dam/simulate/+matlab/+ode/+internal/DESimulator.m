classdef DESimulator < matlab.ode.internal.SimulatorBase
    % Internal only. 
    % Simulator class that extends SimulatorBase in order to run the
    % MATLAB interface to DESuite. 

    %    Copyright 2011-2023 The MathWorks, Inc.

    properties
        MyProblem matlab.ode.internal.DEProblem
    end

    methods
        function obj = DESimulator(problem)
            assert(isa(problem, 'matlab.ode.internal.DEProblem'))
            if ~problem.SkipVerification
                problem = verify(problem);
            end
            obj = obj@matlab.ode.internal.SimulatorBase(problem);
            obj.MyProblem = problem;
        end

        % use new set of initial conditions to reset internal solver state.
        function obj = reset(obj,t_new,x0_new,p_new,s0_new,x0dot_new,tend_new)
            arguments
                obj
                t_new = []
                x0_new = []
                p_new = []
                s0_new = []
                x0dot_new = []
                tend_new = []
            end
            % verify that new ICs are okay.
            if ~obj.MyProblem.SkipVerification
                obj.MyProblem = verify(obj.MyProblem);
            end 
            reset_solver(obj,t_new,x0_new,p_new,s0_new,x0dot_new,tend_new);
        end

        function varargout = run(obj,tspan)
            % switch between different run functions
            if nargin == 1 || (nargin > 1 && isempty(tspan))
                [t,y,s,te,ye,ie,se,yp,ype]...
                    = run_standard(obj);
            else
                [t,y,s,te,ye,ie,se,yp,ype]...
                    = run_with_tspan(obj,tspan);
            end
            if nargout == 1
                sol.x = t;
                sol.y = y;
                sol.s = s;
                sol.te = te;
                sol.ye = ye;
                sol.ie = ie;
                sol.se = se;
                sol.yp = yp;
                sol.ype = ype;
                varargout{1} = sol;
            else
                varargout = {t,y,s,te,ye,ie,se,yp,ype};
            end
        end

    end

    methods(Access = private)

        function [t,y,s,te,ye,ie,se,yp,ype] = run_standard(obj)
            % run and output at solver steps
            [t,y,s,te,ye,ie,se,yp,ype] = obj.run_solver_steps();
        end

        function [t,y,s,te,ye,ie,se,yp,ype] = run_with_tspan(obj,tspan)
            % input tspan with > 2 elements to only output solution at
            % steps requested
            % overwrites start and stop time with tspan values
            assert(issorted(tspan,'strictmonotonic'),"tspan must be strict monotonic");
            if tspan(1) ~= obj.MyProblem.StartTime || tspan(end) ~= obj.MyProblem.StopTime
                % call reset to make passed in start and stop times 
                % consistent with tspan
                obj.MyProblem.StartTime = tspan(1);
                obj.MyProblem.StopTime = tspan(end);
                reset(obj,tspan(1),[],[],[],[],tspan(end));
            end
            [t,y,s,te,ye,ie,se,yp,ype] = obj.run_tspan(tspan);
        end

    end
end

