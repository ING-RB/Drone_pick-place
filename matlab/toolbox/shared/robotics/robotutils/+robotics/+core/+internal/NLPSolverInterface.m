classdef NLPSolverInterface < handle
    %NLPSOLVERINTERFACE Base class for RST internal nonlinear program solvers
    %   This is the solver interface for problems shown below (nonlinear costs
    %   with linear constraints)
    %   
    %   min F(x)
    %    x
    %   s.t. 
    %       Ax - b <= 0
    
    %   Copyright 2016-2024 The MathWorks, Inc.
    
    %#codegen


    properties(Abstract,Constant)
        %Name Name of the solver
        Name
    end
        
    properties
        %ConstraintMatrix
        ConstraintMatrix
        
        %ConstraintBound
        ConstraintBound
        
        %ConstraintsOn
        ConstraintsOn
        
        %CostFcn Function handle to compute cost
        CostFcn
    
        %GradientFcn Function handle to compute gradient
        GradientFcn
        
        %SolutionEvaluationFcn Function handle to evaluate found solution
        SolutionEvaluationFcn
        
        %SolutionTolerance
        SolutionTolerance
        
        %BoundHandlingFcn Function handle to deal with out-of-bound
        %   variables
        BoundHandlingFcn
        
        %RandomRestart
        RandomRestart
        
        %RandomSeedFcn Function handle to generate random initial guess
        %   (that satisfies constraints)
        RandomSeedFcn
        
        %ExtraArgs Extra arguments for function handles
        ExtraArgs
        
        %MaxNumIteration Maximum number of iterations
        MaxNumIteration
        
        %MaxTime Maximum solving time
        MaxTime

    end
    
    properties (Access = {?robotics.core.internal.NLPSolverInterface, ...
                          ?robotics.core.internal.InternalAccess})
        % Intermediate variables for internal use
        SeedInternal
        
        MaxTimeInternal
        
        MaxNumIterationInternal
        
        %StepTolerance Minimum step size
        StepTolerance
        
        %TimeObj An object of SystemTimeProvider, for timing in solve
        %   method
        TimeObj   
        
        %UseTimer Internal property to ensure System Time Provider is called only when needed
        UseTimer = true
    end

    properties(Constant)
        %STATUS_SUCCESS
        STATUS_SUCCESS='success';

        %STATUS_BEST_AVAIL
        STATUS_BEST_AVAIL='best available';
    end
    
    
    methods (Abstract)
        
        params = getSolverParams(obj)
        
    end
    
    methods (Abstract, Access = {?robotics.core.internal.NLPSolverInterface, ...
                                 ?matlab.unittest.TestCase})
        
        [xSol, exitFlag, err, iter, XDebug] = solveInternal(obj);
        
    end
    
    methods
        
        function [xSol, solutionInfo] = solve(obj, seed)
            %solve
            obj.MaxNumIterationInternal = obj.MaxNumIteration;
            obj.MaxTimeInternal = obj.MaxTime;
            obj.SeedInternal = seed(:);
            tol = obj.SolutionTolerance; 
            
            if obj.UseTimer
                obj.TimeObj.reset();
            end
            
            [xSol, exitFlag, err, iter] = solveInternal(obj);
            rrAttempts = 0;
            
            iterations = iter;
            xSolPrev = xSol;
            errPrev = err;
            exitFlagPrev = exitFlag;
            
            while obj.RandomRestart && (err > tol)
                obj.MaxNumIterationInternal = obj.MaxNumIterationInternal - iter;
                
                if obj.UseTimer
                    obj.MaxTimeInternal = obj.MaxTime - obj.TimeObj.getElapsedTime;
                end
                
                % This check prevents solveInternal from being called with 
                % an iteration limit of 0, in the case where the previous
                % call to solveInternal terminated on the final
                % iteration, but for a reason other than hitting the
                % iteration limit.
                if obj.MaxNumIterationInternal <= 0
                    exitFlag = robotics.core.internal.NLPSolverExitFlags.IterationLimitExceeded;
                end
                
                if exitFlag == robotics.core.internal.NLPSolverExitFlags.IterationLimitExceeded ...
                        || exitFlag == robotics.core.internal.NLPSolverExitFlags.TimeLimitExceeded
                    % if time out or maximum iteration, then stop trying
                    exitFlagPrev = exitFlag;
                    break 
                end
                
                newseed = obj.RandomSeedFcn(obj.ExtraArgs);
                obj.SeedInternal(:) = newseed(:);
                [xSol, exitFlag, err, iter] = solveInternal(obj);
                
                % only keeping the best available solution
                if (err < errPrev)
                    xSolPrev = xSol;
                    errPrev = err;
                    exitFlagPrev = exitFlag;
                end
                
                rrAttempts = rrAttempts + 1;
                iterations = iterations + iter;
            end
            
            xSol = xSolPrev;
            err = errPrev;
            exitFlag = exitFlagPrev;
            
            solutionInfo.Iterations = iterations;
            solutionInfo.RRAttempts = rrAttempts;
            solutionInfo.Error = err;
            solutionInfo.ExitFlag = double(exitFlag);
            
            if err < tol
                solutionInfo.Status = obj.STATUS_SUCCESS;
            else
                solutionInfo.Status = obj.STATUS_BEST_AVAIL;
            end
        end
        
        function flag = timeLimitExceeded(obj, t)
            flag = t > obj.MaxTimeInternal;
        end
        
    end
    
end

