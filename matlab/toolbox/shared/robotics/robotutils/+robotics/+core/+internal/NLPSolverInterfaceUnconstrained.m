classdef NLPSolverInterfaceUnconstrained < handle
    %This class is for internal use only. It may be removed in the future.
    
    %NLPSOLVERINTERFACEUNCONSTRAINED Base class for RST unconstrained nonlinear program solvers
    %   This is the solver interface for problems shown below (nonlinear costs
    %   with no constraints)
    %   
    %   min F(x)
    %    x
    %
    %   where F(x) is a scalar cost function
    
    %   Copyright 2017-2020 The MathWorks, Inc.
    
    %#codegen


    properties (Abstract, SetAccess = protected)
        
        %Name Name of the solver
        Name
    end
    
    properties
        
        %CostFcn Function handle to compute cost
        CostFcn
        
        %ExtraArgs Extra arguments for function handles
        ExtraArgs
        
        %MaxNumIteration Maximum number of iterations
        MaxNumIteration
        
        %MaxTime Maximum solving time
        MaxTime

    end
    
    properties (Access = {?robotics.core.internal.NLPSolverInterfaceUnconstrained, ...
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
        
    end
    
    
    methods (Abstract)
        
        params = getSolverParams(obj)
        
    end
    
    methods (Abstract, Access = {?robotics.core.internal.NLPSolverInterfaceUnconstrained, ...
                                 ?matlab.unittest.TestCase})
        
        [xSol, exitFlag, err, iter, hess] = solveInternal(obj);
        
    end
    
    methods
        
        function [xSol, solutionInfo, hess] = solve(obj, seed)
            %solve
            obj.MaxNumIterationInternal = obj.MaxNumIteration;
            obj.MaxTimeInternal = obj.MaxTime;
            obj.SeedInternal = seed; %
            
            obj.TimeObj.reset();
            
            [xSol, exitFlag, err, iter, hess] = solveInternal(obj);
            
            solutionInfo.Iterations = iter;
            solutionInfo.Error = err;
            solutionInfo.ExitFlag = double(exitFlag);
            

        end
        
        function flag = timeLimitExceeded(obj, t)
            flag = t > obj.MaxTimeInternal;
        end
        
    end
    
end

