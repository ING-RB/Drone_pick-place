classdef TestRunCustomizationService < matlab.automation.internal.services.Service
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    %   Copyright 2023 The MathWorks, Inc.

    properties (Abstract, Constant)
        Option
    end

    methods (Abstract)
        customizeTestRunner(service, liaison, runner)
    end

    methods (Sealed)
        function fulfill(services, liaison)
            supportingService = services.findServiceThatSupports(liaison.RunnerOption);

            if isempty(supportingService)
                error(message("MATLAB:buildtool:TestTask:InvalidTestRunnerOption", liaison.RunnerOption));
            end
        end

        function aService = findServiceThatSupports(services, option)
            aService = services([services.Option] == option);
        end
    end

end
