classdef TestRunData < handle
    % This class is undocumented.
    
    % Copyright 2013-2020 The MathWorks, Inc.
    
    properties (Abstract)
        TestResult;
        CurrentIndex;
        CurrentResult;
    end
    
    properties(Hidden, SetAccess=protected)
        Buffer
    end
    
    properties (Abstract, SetAccess=private)
        RepeatIndex;
    end
    
    properties (Abstract, SetAccess=immutable)        
        RunIdentifier;
    end
    
    properties(SetAccess = {?matlab.unittest.internal.TestRunData,?matlab.unittest.internal.TestRunStrategy})
        TestSuite;
    end
    
    properties (Abstract, Constant)
        ShouldEnterRepeatLoopScope logical;
    end
    
    properties (Dependent)
        CurrentSuite;
    end
    
    properties (SetAccess=protected)
        HasCompletedTestRepetitions = true;
    end
    
    methods (Abstract)
        resetRepeatLoop(data);
        beginRepeatLoopIteration(data);
        bool = shouldContinueRepeatLoop(data);
        endRepeatLoop(data);
        
        addDurationToCurrentResult(data, duration);
        appendDetails(data, task);
        replaceDetails(data, task);
    end
    
    methods
        function suite = get.CurrentSuite(data)
            suite = data.TestSuite(data.CurrentIndex);
        end
    end
end

