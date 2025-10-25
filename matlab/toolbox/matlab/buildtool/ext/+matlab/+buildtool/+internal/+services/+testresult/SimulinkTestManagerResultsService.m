classdef SimulinkTestManagerResultsService < matlab.automation.internal.services.Service
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    %   Copyright 2023 The MathWorks, Inc.

    methods
        function fulfill(~, runner)
            import matlab.buildtool.internal.tasks.isSimulinkTestInstalled
            import matlab.buildtool.internal.tasks.constructSTMResultsPlugin

            if ~isSimulinkTestInstalled() || ~license("checkout", "SIMULINK_TEST")
                return
            end

            runner.addPlugin(constructSTMResultsPlugin());
        end
    end
end