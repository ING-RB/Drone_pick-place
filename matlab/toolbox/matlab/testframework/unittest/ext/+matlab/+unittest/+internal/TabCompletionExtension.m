classdef (Hidden) TabCompletionExtension < matlab.unittest.internal.TabCompletion
    %
    
    % Copyright 2019-2022 The MathWorks, Inc.
    
    methods (Static)
        function names = nameChoicesForProject(test)
            import matlab.unittest.internal.TabCompletionExtension;
            
            suite = createSuiteIfPossibleForProject(test);
            names = TabCompletionExtension.getUniqueSuiteParentProcedureNames(suite);
        end
        
        function parameterNames = parameterNameChoicesForProject(test)
            import matlab.unittest.internal.TabCompletionExtension;
            
            suite = createSuiteIfPossibleForProject(test);
            parameterNames = TabCompletionExtension.getSuiteParameterNames(suite);
        end
        
        function parameterProperties = parameterPropertyChoicesForProject(test)
            import matlab.unittest.internal.TabCompletionExtension;
            
            suite = createSuiteIfPossibleForProject(test);
            parameterProperties = TabCompletionExtension.getSuiteParameterProperties(suite);
        end
        
        function tags = tagChoicesForProject(test)
            import matlab.unittest.internal.TabCompletionExtension;
            
            suite = createSuiteIfPossibleForProject(test);
            tags = TabCompletionExtension.getUniqueTagsFromSuite(suite);
        end
        
        function procedureNames = procedureNameChoicesForProject(test)
            import matlab.unittest.internal.TabCompletionExtension;
            
            suite = createSuiteIfPossibleForProject(test);
            procedureNames = TabCompletionExtension.getUniqueProcedureNamesFromSuite(suite);
        end
        
        function superclassNames = superclassChoicesForProject(test)
            import matlab.unittest.internal.TabCompletionExtension;
            
            suite = createSuiteIfPossibleForProject(test);
            superclassNames = TabCompletionExtension.getSuperClassNames(suite);
        end

        function metricNames = metricChoicesForCoverageReport
            import matlab.unittest.internal.coverage.locateCoverageReportMetricServices;
            coverageMetricsServices = locateCoverageReportMetricServices;
            metricNames = cellstr([coverageMetricsServices.ValidMetricNames]);
        end
    end
end

function suite = createSuiteIfPossibleForProject(test)
import matlab.unittest.TestSuite;
import matlab.unittest.Test;

try
    suite = TestSuite.fromProject(test);
catch
    suite = Test.empty;
end
end

% LocalWords:  unittest testsuite
