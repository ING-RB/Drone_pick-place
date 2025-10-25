classdef TestOutputViewService < matlab.automation.internal.services.Service
    % This class is undocumented and will change in a future release.

    % TestOutputViewService - Interface for UI runner services.
    %
    % See Also: TestOutputViewLiaison, Service, ServiceLocator, ServiceFactory

    %   Copyright 2023 The MathWorks, Inc.
    
    properties(Abstract)
        TestOutputView (1,1) string
    end

    methods (Sealed)
        function fulfill(services, liaison)
            % fulfill - Fulfill an array of UI runner services
            supportingService = services.findSupportingServices(liaison);
            if ~isempty(supportingService)
                supportingService.updateHandler(liaison);
            end
        end

        function supportingService = findSupportingServices(services, liaison)
            supportingService = services(strcmp([services.TestOutputView],liaison.RequestedTestOutputView));
            mustBeScalarOrEmpty(supportingService);
        end
    end

    methods(Abstract)
        updateHandler(service, liaison);
    end
end