classdef RunOnceTestRunData < matlab.unittest.internal.TestRunData
    % This class is undocumented.
    
    %  Copyright 2017-2020 The MathWorks, Inc.
    
    properties (Dependent)
        CurrentResult;
    end
    
    properties
        TestResult;
        CurrentIndex = 1;
    end
    
    properties (SetAccess=private)
        RepeatIndex = 1;
    end
    
    properties (SetAccess=immutable)
        RunIdentifier;
    end
    
    properties (Constant)
        ShouldEnterRepeatLoopScope = false;
    end
    
    methods (Static)
        function data = fromSuite(suite, runIdentifier,runner)
            import matlab.unittest.internal.RunOnceTestRunData;
            import matlab.unittest.internal.plugins.TestResultDetailsBuffer;
            
            buffer = TestResultDetailsBuffer;
            result = createInitialTestResult(suite,runner);
            data = RunOnceTestRunData(suite, result, runIdentifier, buffer);
        end
        
        function data = fromSuiteUsingResults(suite, runIdentifier,testResults)
            import matlab.unittest.internal.RunOnceTestRunData;
            import matlab.unittest.internal.plugins.TestResultDetailsBuffer;
            
            buffer = TestResultDetailsBuffer;
            data = RunOnceTestRunData(suite, testResults, runIdentifier, buffer);
        end
    end
    
    methods (Access=protected)
        function data = RunOnceTestRunData(suite, result, runIdentifier, buffer)
            data.TestSuite = suite;
            data.TestResult = result;
            data.RunIdentifier = runIdentifier;
            data.Buffer = buffer;
        end
    end
    
    methods
        function resetRepeatLoop(~)
            % Do nothing
        end
        
        function beginRepeatLoopIteration(~)
            % Do nothing
        end
        
        function bool = shouldContinueRepeatLoop(~)
            bool = false;
        end
        
        function endRepeatLoop(~)
            % Do nothing
        end
        
        function addDurationToCurrentResult(data, duration)
            data.TestResult(data.CurrentIndex).Duration = data.TestResult(data.CurrentIndex).Duration + duration;
        end
        
        function appendDetails(data, task)            
            indices = task.DetailsLocationProvider.DetailsStartIndex:task.DetailsLocationProvider.DetailsEndIndex;
            data.TestResult(indices) = data.TestResult(indices).appendDetailsProperty(task.FieldName,...
                task.Value);
        end
        
        function replaceDetails(data, task)
            indices = task.DetailsLocationProvider.DetailsStartIndex:task.DetailsLocationProvider.DetailsEndIndex;
            data.TestResult(indices) = data.TestResult(indices).replaceDetailsProperty(task.FieldName,...
                task.Value);
        end
        
        function result = get.CurrentResult(data)
            result = data.TestResult(data.CurrentIndex);
        end
        
        function set.CurrentResult(data, result)
            data.TestResult(data.CurrentIndex) = result;
        end
    end
end

function result = createInitialTestResult(suite,runner)
% Create an initial TestResult that is of the same size as the suite passed
% in, transferring the suite element names

import matlab.lang.internal.uuid;
import matlab.unittest.TestResult;

result = TestResult.empty;
numElements = numel(suite);
% Create the initial test result with right size & shape
if numElements > 0
    result(numElements) = TestResult;
end
result = reshape(result, size(suite));

uuidArr = uuid(1, numElements);
for idx = 1:numElements
    s = suite(idx);
    result(idx).TestElement = s;
    result(idx).Name = s.Name;
    result(idx).TestRunner = runner;
    result(idx).ResultIdentifier = uuidArr(idx);
end

end
