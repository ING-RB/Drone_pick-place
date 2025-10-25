classdef TestOutputHandler
%

%   Copyright 2023 The MathWorks, Inc.

    properties(SetAccess=protected)
        %Default behavior is to NOT include the DiagnosticOutputPlugin
        % Subclasses can set this to true if they want to use the default
        UseDiagnosticOutputPlugin (1,1) logical = false;
    end

    methods(Abstract)
        runFcn = prepareRunner(handler,runOptions, plugins, suite, runner)
    end

    methods(Sealed)
        function results = runTests(handler, runOptions, plugins, suite, runner)
            arguments(Input)
                handler (1,1) matlab.unittest.internal.testoutputviewhandlers.TestOutputHandler
                runOptions struct
                plugins matlab.unittest.plugins.TestRunnerPlugin
                suite
                runner (1,1) matlab.unittest.TestRunner
            end
            
            runFcn = handler.prepareRunner(runOptions, plugins, suite, runner);
            results = runFcn(runner,suite);
        end
    end  
end