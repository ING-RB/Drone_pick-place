classdef RunRepeatedlyTestRunData < matlab.unittest.internal.TestRunData
    % This class is undocumented.
    
    %  Copyright 2017-2020 The MathWorks, Inc.
    
    properties(Dependent)
        CurrentIndex;
        CurrentResult;
    end
    
    properties
        TestResult;
    end
    
    properties (SetAccess=private)
        RepeatIndex = 1;
    end
    
    properties (SetAccess=immutable)
        RunIdentifier;
    end
    
    properties (Constant)
        ShouldEnterRepeatLoopScope = true;
    end
    
    properties(Access=private)
        NumRepetitions;
        EarlyTerminationFcn;
        InternalCurrentIndex = 1;
        ResultPrototype;
    end
    
    methods (Static)
        function data = fromSuite(suite, runIdentifier, numRepetitions, earlyTerminationFcn,runner)
            import matlab.unittest.internal.RunRepeatedlyTestRunData;
            import matlab.unittest.internal.plugins.TestResultDetailsBuffer;
            
            buffer = TestResultDetailsBuffer;
            result = createInitialCompositeTestResult(suite,runner);
            data = RunRepeatedlyTestRunData(suite, result, runIdentifier, numRepetitions, earlyTerminationFcn, buffer);
        end
    end
    
    methods (Access=protected)
        function data = RunRepeatedlyTestRunData(suite, result, runIdentifier, numRepetitions, earlyTerminationFcn, buffer)
            data.TestSuite = suite;
            data.TestResult = result;
            data.RunIdentifier = runIdentifier;
            data.NumRepetitions = numRepetitions;
            data.EarlyTerminationFcn = earlyTerminationFcn;
            data.Buffer = buffer;
        end
    end
    
    methods
        function resetRepeatLoop(data)
            % Use the first child TestResult as the prototype for future
            % repeat loop iterations.
            data.ResultPrototype = data.CurrentResult;
            
            data.HasCompletedTestRepetitions = false;
            data.RepeatIndex = 0;
        end
        
        function beginRepeatLoopIteration(data)
            import matlab.lang.internal.uuid;
            data.RepeatIndex = data.RepeatIndex + 1;
            
            if data.RepeatIndex > 1
                % Initialize current result from the prototype, resetting
                % the duration to zero
                data.CurrentResult = data.ResultPrototype;
                data.CurrentResult.Duration = 0;
                data.CurrentResult.ResultIdentifier = uuid;
            end
        end
        
        function bool = shouldContinueRepeatLoop(data)
            bool = ~data.EarlyTerminationFcn(data.CurrentResult, data.InternalCurrentIndex) && ...
                data.RepeatIndex < data.NumRepetitions;
        end
        
        function endRepeatLoop(data)
            data.HasCompletedTestRepetitions = true;
        end
        
        function addDurationToCurrentResult(data, duration)
            data.CurrentResult.Duration = data.CurrentResult.Duration + duration;
        end
        
        function appendDetails(data, task)
            args = {};
            if ~task.DistributeLoop
                args = {data.RepeatIndex};
            end
            indices = task.DetailsLocationProvider.DetailsStartIndex:task.DetailsLocationProvider.DetailsEndIndex;
            data.TestResult(indices) = data.TestResult(indices).appendDetailsProperty(task.FieldName,...
                task.Value, args{:});
        end
        
        function replaceDetails(data, task)
            args = {};
            if ~task.DistributeLoop
                args = {data.RepeatIndex};
            end
            indices = task.DetailsLocationProvider.DetailsStartIndex:task.DetailsLocationProvider.DetailsEndIndex;
            data.TestResult(indices) = data.TestResult(indices).replaceDetailsProperty(task.FieldName,...
                task.Value, args{:});
        end
        
        function set.CurrentIndex(data, index)
            data.InternalCurrentIndex = index;
            data.RepeatIndex = 1;
        end
        
        function index = get.CurrentIndex(data)
            index = data.InternalCurrentIndex;
        end
        
        function result = get.CurrentResult(data)
            result = data.TestResult(data.InternalCurrentIndex).TestResult(data.RepeatIndex);
        end
        
        function set.CurrentResult(data, result)
            data.TestResult(data.InternalCurrentIndex).TestResult(data.RepeatIndex) = result;
        end
    end
end

function result = createInitialCompositeTestResult(suite,runner)
% Creates an initial CompositeTestResult that is of the same size as the
% suite passed, transferring the suite element name

import matlab.unittest.CompositeTestResult;
import matlab.unittest.TestResult;
import matlab.lang.internal.uuid;

result = CompositeTestResult.empty;
numElements = numel(suite);
% Create the initial test result with right size & shape
if numElements > 0
    result(numElements) = CompositeTestResult;
end
result = reshape(result, size(suite));

uuidArr = uuid(1, numElements);
for idx = 1:numElements
    s = suite(idx);
    name = s.Name;
    result(idx).Name = name;
    leafResult = TestResult;
    leafResult.Name = name;
    leafResult.TestElement = s;
    leafResult.TestRunner = runner;
    leafResult.ResultIdentifier = uuidArr(idx);
    result(idx).TestResult = leafResult;
end
end