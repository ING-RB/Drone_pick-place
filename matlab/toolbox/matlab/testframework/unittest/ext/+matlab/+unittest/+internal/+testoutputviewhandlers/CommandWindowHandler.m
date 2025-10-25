classdef CommandWindowHandler < matlab.unittest.internal.testoutputviewhandlers.TestOutputHandler
%

%   Copyright 2023 The MathWorks, Inc.
    methods
        function obj = CommandWindowHandler()
            obj = obj@matlab.unittest.internal.testoutputviewhandlers.TestOutputHandler();
            obj.UseDiagnosticOutputPlugin = true;
        end
    end

    methods
        function runFcn = prepareRunner(~,runOptions, plugins, suite, runner)
            runFcn = matlab.unittest.internal.getRunFcn(runOptions, plugins, suite, runner.ArtifactsRootFolder);
            arrayfun(@(plugin)runner.addPlugin(plugin), plugins);
        end
    end
end
