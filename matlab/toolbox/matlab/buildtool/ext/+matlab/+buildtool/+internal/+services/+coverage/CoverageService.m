classdef CoverageService < matlab.automation.internal.services.Service
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % Copyright 2023-2024 The MathWorks, Inc.

    properties (Abstract, Constant)
        SourceType
    end

    methods (Abstract)
        customizeTestRunner(service, liaison, runner)
    end

    methods (Sealed)
        function fulfill(services, liaison)
            supportingService = services.findServiceThatSupports(liaison.SourceType);

            if isempty(supportingService)
                error(message("MATLAB:buildtool:TestTask:InvalidCoverageSource", string(liaison.SourceType)));
            end
        end

        function aService = findServiceThatSupports(services, sourceType)
            aService = services([services.SourceType] == sourceType);
        end
    end

end
