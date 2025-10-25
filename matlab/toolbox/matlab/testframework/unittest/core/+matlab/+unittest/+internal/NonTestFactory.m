classdef NonTestFactory < matlab.unittest.internal.TestSuiteFactory
    % This class is undocumented.
    
    % NonTestFactory - Factory for creating suites for non-test entities.
    
    % Copyright 2014-2022 The MathWorks, Inc.
    
    properties(Constant)
        CreatesSuiteForValidTestContent = false;
        SupportsParameterizedTests = true;
    end
    
    properties (Access=private)
        Exception;
    end
    
    methods
        function factory = NonTestFactory(exception)
            factory.Exception = exception;
        end
        
        function suite = createSuiteExplicitly(factory, ~, ~, nvpairs)
            arguments
                factory
                ~
                ~
                nvpairs.NonTestBehavior {mustBeMember(nvpairs.NonTestBehavior,["error","ignore"])} = "error"
            end
            if nvpairs.NonTestBehavior == "ignore"
                suite = matlab.unittest.Test.empty;
            else
                throwAsCaller(factory.Exception);
            end
        end
        
        function suite = createSuiteImplicitly(varargin)
            suite = matlab.unittest.Test.empty;
        end
    end
end

