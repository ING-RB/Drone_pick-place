classdef ResultsExtensionService < matlab.automation.internal.services.Service
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    %   Copyright 2023 The MathWorks, Inc.

    methods (Abstract)
        save(service, liaison)
        formattedStr = addLabelAndString(service, liaison, labelAlignedStr)
    end

    methods (Sealed)
        function fulfill(services, liaison)
            supportingService = services.findServiceThatSupports(liaison.ResultsFile);
            if isempty(supportingService)
                error(message("MATLAB:buildtool:CodeIssuesTask:InvalidResultsFormat", liaison.Extension));
            end
        end

        function service = findServiceThatSupports(services, resultsFile)
            for service = services
                tf = service.supports(resultsFile);
                if tf
                    return;
                end
            end
            service = [];
        end
    end

    methods (Access = protected)
        function tf = supports(service, resultsFile)
            [~, ~, fext] = fileparts(resultsFile);
            tf = fext == service.Extension;
        end
    end

    methods (Static)
        function str = getStringFromCatalog(id)
            str = matlab.buildtool.internal.tasks.getStringFromCatalog(matlab.buildtool.tasks.CodeIssuesTask.Catalog, id);
        end
    end
end
