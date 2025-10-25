classdef TestResultExtensionService < matlab.automation.internal.services.Service
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    %   Copyright 2023 The MathWorks, Inc.

    properties (Abstract, Constant)
        Extension
    end

    methods (Abstract)
        customizeTestRunner(service, liaison, runner)
        formattedStr = addLabelAndString(service, liaison, labelAlignedStr)
    end

    methods (Sealed)
        function fulfill(services, liaison)
            supportingService = services.findServiceThatSupports(liaison.Extension);

            if isempty(supportingService)
                error(message("MATLAB:buildtool:TestTask:InvalidTestResultsFormat", liaison.Extension));
            end
        end

        function aService = findServiceThatSupports(services, extension)
            aService = services([services.Extension] == extension);
        end
    end

    methods (Static)
        function createResultsFolder(liaison)
            fpath = fileparts(liaison.ResultsFile);
            if strlength(fpath) ~= 0 && ~isfolder(fpath)
                success = mkdir(fpath);
                if ~success
                    error(message("MATLAB:buildtool:TestTask:CannotCreateResultsFolder", fpath));
                end
            end
        end
        
        function str = getStringFromCatalog(id)
            str = matlab.buildtool.internal.tasks.getStringFromCatalog(matlab.buildtool.tasks.TestTask.Catalog, id);
        end
    end
end
