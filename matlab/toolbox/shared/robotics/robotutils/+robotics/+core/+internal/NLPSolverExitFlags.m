classdef NLPSolverExitFlags < int32
    %This class is for internal use only. It may be removed in the future.
    
    %NLPSOLVEREXITFLAGS
    
    %   Copyright 2016-2019 The MathWorks, Inc.
    
    %#codegen

    enumeration
        LocalMinimumFound(1)
        IterationLimitExceeded(2)
        TimeLimitExceeded(3)
        StepSizeBelowMinimum(4)
        ChangeInErrorBelowMinimum(5)
        SearchDirectionInvalid(6)
        HessianNotPositiveSemidefinite(7)
        TrustRegionRadiusBelowMinimum(8)
    end
end
