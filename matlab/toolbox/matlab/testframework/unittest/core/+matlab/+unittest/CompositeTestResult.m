classdef (Hidden) CompositeTestResult < matlab.unittest.internal.BaseTestResult
    % This class is undocumented
    
    % Copyright 2015-2023 The MathWorks, Inc.
    
    properties (Dependent, SetAccess = {?matlab.unittest.TestRunner})
        % Duration - Time elapsed running test
        %
        %   The Duration property indicates the amount of time taken to run a
        %   particular test, including the time taken setting up and tearing
        %   down any test fixtures.
        %
        %   Fixture setup time is accounted for in duration of the first
        %   test suite array element that uses the fixture. Fixture
        %   teardown time is accounted for in the duration of the last test
        %   suite array element that uses the fixture.
        %
        %   The total runtime for a suite of tests will exceed the sum of the
        %   durations for all the elements of the suite because the Duration
        %   property does not include all the overhead of the TestRunner
        %   nor any of the time consumed by test runner plugins.
        %
        %   Duration of a CompositeTestResult is the sum of all durations
        %   of the contained results.
        Duration;
    end
    
    properties (Hidden, Dependent, SetAccess = {?matlab.unittest.internal.BaseTestResult, ?matlab.unittest.TestRunner})
        Started;
        VerificationFailed;
        AssumptionFailed;
        AssertionFailed;
        Errored;
        FatalAssertionFailed;
        Interrupted;
        Finalized;
    end
    
    properties (SetAccess = {?matlab.unittest.CompositeTestResult, ?matlab.unittest.internal.TestRunData})
        TestResult = matlab.unittest.TestResult.empty;
    end
    
    methods
        function duration = get.Duration(result)
            duration = sum([result.TestResult.Duration]);
        end
        
        function started = get.Started(result)
            started = any([result.TestResult.Started]);
        end
        
        function failed = get.VerificationFailed(result)
            failed = any([result.TestResult.VerificationFailed]);
        end
        
        function failed = get.AssertionFailed(result)
            failed = any([result.TestResult.AssertionFailed]);
        end
        
        function failed = get.FatalAssertionFailed(result)
            failed = any([result.TestResult.FatalAssertionFailed]);
        end

        function Interrupted = get.Interrupted(result)
            Interrupted = any([result.TestResult.Interrupted]);
        end
        
        function failed = get.AssumptionFailed(result)
            failed = any([result.TestResult.AssumptionFailed]);
        end
        
        function failed = get.Errored(result)
            failed = any([result.TestResult.Errored]);
        end
        
        function result = set.VerificationFailed(result, value)
            [result.TestResult.VerificationFailed] = deal(value);
        end
        
        function result = set.AssertionFailed(result, value)
            [result.TestResult.AssertionFailed] = deal(value);
        end
        
        function result = set.AssumptionFailed(result, value)
            [result.TestResult.AssumptionFailed] = deal(value);
        end
        
        function result = set.FatalAssertionFailed(result, value)
            [result.TestResult.FatalAssertionFailed] = deal(value);
        end

        function result = set.Interrupted(result, value)
            [result.TestResult.Interrupted] = deal(value);
        end
        
        function result = set.Errored(result, value)
            [result.TestResult.Errored] = deal(value);
        end
        
        function result = set.Finalized(result, value)
            [result.TestResult.Finalized] = deal(value);
        end
    end
    
    methods (Hidden, Access=protected)
        function groups = getPropertyGroups(result)
            groups = getPropertyGroups@matlab.unittest.internal.BaseTestResult(result);
            groups.PropertyList{end+1} = 'TestResult';
        end
    end
        
    methods(Hidden)
        function result = flatten(result)
            result = result.TestResult(:);
        end
    end
    
    methods (Hidden, Access={?matlab.unittest.internal.BaseTestResult, ...
            ?matlab.unittest.internal.TestRunData})
        function result = appendDetailsProperty(result, propertyName, value, varargin)
            for idx = 1:numel(result)
                result(idx) = result(idx).applyOperationToScalarResult(@appendDetailsProperty, propertyName, value, varargin{:});
            end
        end
        
        function result = replaceDetailsProperty(result, propertyName, value, varargin)
            for idx = 1:numel(result)
                result(idx) = result(idx).applyOperationToScalarResult(@replaceDetailsProperty, propertyName, value, varargin{:});
            end
        end
    end
    
    methods (Access=private)
        function result = applyOperationToScalarResult(result, fcn, propertyName, value, idx)
            arguments
                result (1,1) matlab.unittest.CompositeTestResult;
                fcn (1,1) function_handle;
                propertyName;
                value;
                idx = 1:numel(result.TestResult);
            end
            
            result.TestResult(idx) = fcn(result.TestResult(idx), propertyName, value);
        end
    end
end
