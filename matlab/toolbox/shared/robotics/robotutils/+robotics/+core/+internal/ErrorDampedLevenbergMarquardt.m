classdef ErrorDampedLevenbergMarquardt < robotics.core.internal.NLPSolverInterface
    %This class is for internal use only. It may be removed in the future.
    
    %ERRORDAMPEDLEVENBERGMARQUARDT Solver for unconstrained nonlinear
    %   lease squares problem (only with some very crude handling of 
    %   variable bounds)
    %
    %   min  0.5 * f(x)'* W * f(x)
    %    x
    %   s.t.    lb <= x <= ub
    %   where f(x) is an m-by-1 vector, x is an n-by-1 vector
    
    
    %   Copyright 2016-2024 The MathWorks, Inc.
    %
    %   References:
    %
    %   [1] T. Sugihara, Solvability-unconcerned inverse kinematics by the
    %   Levenberg-Marquardt method
    %   IEEE Transactions on Robotics, Vol 27, No. 5, 2011
    
    %#codegen
    
    properties(Constant)
        %Namea Name of the solver
        Name='LevenbergMarquardt';
    end

    properties (Access = protected)
        
        %GradientTolerance The solver terminates if the norm of the 
        %gradient falls below this value (a positive value)
        GradientTolerance
        
        %ErrorChangeTolerance The solver terminates if the change in all
        %elements of the error vector fall below this value (a positive
        %value)
        ErrorChangeTolerance
        
        % The LM damping (Wn) is comprised of two parts: Current
        % cost(error) and a damping bias. In some cases, the users might
        % want to disable the cost damping term, they can do so by setting
        % UseErrorDamping flag to false. 
        %DampingBias
        DampingBias
        
        %UseErrorDamping
        UseErrorDamping 
        
        %TimeObjInternal An object of SystemTimeProvider, for timing in
        %   solveInternal
        TimeObjInternal 

    end
    
    methods
        function obj = ErrorDampedLevenbergMarquardt(varargin)
            %ErrorDampedLevenbergMarquardt Constructor
            obj.MaxNumIteration = 1500;
            obj.MaxTime = 10;
            obj.SolutionTolerance = 1e-6;
            obj.ConstraintsOn = true;
            obj.RandomRestart = true;
            obj.StepTolerance = 1e-12;
            obj.GradientTolerance = 0.5e-8;
            obj.ErrorChangeTolerance = 1e-12;
            obj.DampingBias = 1e-2*(0.5^2);
            obj.UseErrorDamping = true;
            
            
            obj.ConstraintBound = []; % not used
            obj.ConstraintMatrix = []; % not used
            
            narginchk(0,1);
            
            %This solver can be called with the logical flag, UseTimer. It
            %can be either TRUE (default) or FALSE. This input is for
            %internal use only, and may not be supported in a future
            %release.
            %
            %When the value is TRUE, the solver uses the a timer object
            %that relies on platform-specific code, SystemTimeProvide
            %MockSystemTimeProvider, a placeholder that has the same
            %properties and methods, but which does not require any
            %platform specific code and is therefore compatible with
            %cross-platform deployment. In that case, the solver does not
            %check for a maximum solver time, as no timer object is given.
            %When the value is FALSE, the solver uses
            
            if nargin > 0
                obj.UseTimer = varargin{:};
            else
                obj.UseTimer = true;
            end
            
            if obj.UseTimer
                obj.TimeObj = robotics.core.internal.SystemTimeProvider();
                obj.TimeObjInternal = robotics.core.internal.SystemTimeProvider();
            else
                obj.TimeObj = robotics.core.internal.MockSystemTimeProvider();
                obj.TimeObjInternal = robotics.core.internal.MockSystemTimeProvider();
            end
                
        end   
        
        function params = getSolverParams(obj)
            params.Name = obj.Name;
            params.MaxNumIteration = obj.MaxNumIteration;
            params.MaxTime = obj.MaxTime;
            params.GradientTolerance = obj.GradientTolerance;
            params.SolutionTolerance = obj.SolutionTolerance;
            params.ConstraintsOn = obj.ConstraintsOn;
            params.RandomRestart = obj.RandomRestart;
            params.StepTolerance = obj.StepTolerance;
            params.ErrorChangeTolerance = obj.ErrorChangeTolerance;
            params.DampingBias = obj.DampingBias;
            params.UseErrorDamping = obj.UseErrorDamping;
        end
        
        function obj=setSolverParams(obj, params)
            obj.MaxNumIteration =       params.MaxNumIteration;
            obj.MaxTime =               params.MaxTime;
            obj.GradientTolerance =     params.GradientTolerance;
            obj.SolutionTolerance =     params.SolutionTolerance;
            obj.ConstraintsOn =         params.ConstraintsOn;
            obj.RandomRestart =         params.RandomRestart;
            obj.StepTolerance =         params.StepTolerance;
            obj.ErrorChangeTolerance=          params.ErrorChangeTolerance;
            obj.DampingBias =           params.DampingBias;
            obj.UseErrorDamping =       params.UseErrorDamping;
        end

        function newobj = copy(obj)
            %COPY
            newobj = robotics.core.internal.ErrorDampedLevenbergMarquardt();
                        
            newobj.ConstraintBound = obj.ConstraintBound;
            newobj.ConstraintMatrix = obj.ConstraintMatrix;
            newobj.ConstraintsOn = obj.ConstraintsOn;
            newobj.SolutionTolerance = obj.SolutionTolerance;
            newobj.RandomRestart = obj.RandomRestart;
            
            newobj.SeedInternal = obj.SeedInternal;
            newobj.MaxTimeInternal = obj.MaxTimeInternal;
            newobj.MaxNumIterationInternal = obj.MaxNumIterationInternal;
            
            newobj.CostFcn = obj.CostFcn;
            newobj.GradientFcn = obj.GradientFcn;
            newobj.SolutionEvaluationFcn = obj.SolutionEvaluationFcn;
            newobj.RandomSeedFcn = obj.RandomSeedFcn;
            newobj.BoundHandlingFcn = obj.BoundHandlingFcn;
            
            newobj.ExtraArgs = obj.ExtraArgs;
            
            newobj.setSolverParams(obj.getSolverParams);
            
            newobj.TimeObj = obj.TimeObj;
            newobj.TimeObjInternal = obj.TimeObjInternal;
        end
        
    end
    
    methods (Access = {?robotics.core.internal.NLPSolverInterface, ...
                       ?matlab.unittest.TestCase})
        
        function [xSol, exitFlag, en, iter] = solveInternal(obj)
            
            x = obj.SeedInternal;
            
            if obj.UseTimer
                obj.TimeObjInternal.reset();
            end
            
            % Dimension
            n = size(x,1);
            
            xSol = x; % initialize xSol
            xprev = x; % initialize xprev
            % These lines initialize evprev to be a vector of the
            % appropriate size. It will be overwritten before it is
            % accessed, but code generation requires its size to be set
            % here.
            [~, ~, ~, obj.ExtraArgs] = obj.CostFcn(xprev, obj.ExtraArgs);
            [~, evprev] = obj.SolutionEvaluationFcn(xprev, obj.ExtraArgs);
            
            for i = 1:obj.MaxNumIterationInternal
                [cost, W, J, obj.ExtraArgs] = obj.CostFcn(x, obj.ExtraArgs);
                grad = obj.GradientFcn(x, obj.ExtraArgs);
                grad = grad(:);
                [en, ev] = obj.SolutionEvaluationFcn(x, obj.ExtraArgs);
                
                xSol = x; 
                iter = i;
                
                % Exit conditions
                if atLocalMinimum(obj,grad)
                    exitFlag = robotics.core.internal.NLPSolverExitFlags.LocalMinimumFound;
                    return;
                end
                
                if i>1 && stepSizeBelowMinimum(obj, x, xprev)
                    exitFlag = robotics.core.internal.NLPSolverExitFlags.StepSizeBelowMinimum;
                    return;
                end
                
                if i>1 && changeInErrorBelowMinimum(obj, ev, evprev)
                    exitFlag = robotics.core.internal.NLPSolverExitFlags.ChangeInErrorBelowMinimum;
                    return;
                end
                
                if obj.UseTimer
                    if timeLimitExceeded(obj, obj.TimeObjInternal.getElapsedTime)
                        exitFlag = robotics.core.internal.NLPSolverExitFlags.TimeLimitExceeded;
                        return;
                    end
                end
                
                evprev = ev;
                xprev = x;
                
                % Levenberg-Marquardt update
                
                cc = obj.UseErrorDamping * cost;
                Wn = (cc + obj.DampingBias)*eye(n); 
                H0 = J'*W*J;
                
                H = H0 + Wn;
                step = - H\grad; 
                newcost = obj.CostFcn(x+step, obj.ExtraArgs);
                lambda = 1;

                % Make sure it's a (sufficient) decent
                while newcost > cost
                    lambda = lambda*2.5;
                    Wn = (cc + lambda*obj.DampingBias)*eye(n); 
                    step = - (H0 + Wn)\grad; 
                    newcost = obj.CostFcn(x+step, obj.ExtraArgs);
                end
                
                x = x + step;
                
                % Naive handling of constraints
                if obj.ConstraintsOn
                    x = obj.BoundHandlingFcn(x, obj.ExtraArgs); 
                end
                
            end
            
            en= obj.SolutionEvaluationFcn(xSol, obj.ExtraArgs);
            xSol = x;
            iter = obj.MaxNumIterationInternal;
            exitFlag = robotics.core.internal.NLPSolverExitFlags.IterationLimitExceeded; % Maximum iteration has been reached
            
        end
        
        function flag = atLocalMinimum(obj, grad)
            flag = norm(grad) < obj.GradientTolerance;
        end
        
        function flag = changeInErrorBelowMinimum(obj, ev, evprev)
            flag = all(abs(ev - evprev) < obj.ErrorChangeTolerance);
        end
        
        function flag = stepSizeBelowMinimum(obj, x, xprev)
            flag = all(abs(x - xprev) < obj.StepTolerance);
        end
        
    end
    
    methods (Static, Hidden)
        function props = matlabCodegenNontunableProperties(~)
            props = {'UseTimer'};
        end
    end

end

