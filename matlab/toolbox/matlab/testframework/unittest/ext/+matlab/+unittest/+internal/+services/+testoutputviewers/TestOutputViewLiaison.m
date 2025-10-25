classdef TestOutputViewLiaison < handle
%

% Copyright 2023 The MathWorks, Inc.    

    properties
        RunOptions
        RequestedTestOutputView
        TestOutputViewHandler (1,1) = matlab.unittest.internal.testoutputviewhandlers.CommandWindowHandler;
    end

    methods
        function obj =  TestOutputViewLiaison(runOptions)
            obj.RunOptions = runOptions;
            obj.RequestedTestOutputView = runOptions.TestOutputView;
        end
    end
end
