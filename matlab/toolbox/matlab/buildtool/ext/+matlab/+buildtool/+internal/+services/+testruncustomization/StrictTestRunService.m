classdef StrictTestRunService < matlab.buildtool.internal.services.testruncustomization.TestRunCustomizationService
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    %   Copyright 2023 The MathWorks, Inc.

    properties (Constant)
        Option = "Strict"
    end

    methods
        function customizeTestRunner(~, liaison, runner)
            import matlab.unittest.plugins.FailOnWarningsPlugin

            if liaison.RunnerOptionValue
                runner.addPlugin(FailOnWarningsPlugin);
            end
        end
    end
end
