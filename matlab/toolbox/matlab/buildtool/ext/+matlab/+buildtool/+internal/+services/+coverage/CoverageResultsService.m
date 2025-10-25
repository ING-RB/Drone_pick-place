classdef CoverageResultsService < matlab.automation.internal.services.Service
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    %   Copyright 2023-2024 The MathWorks, Inc.

    properties (Abstract, Constant)
        Extension
        CoverageFormatClass
    end

    methods (Abstract)        
        format = constructCoverageFormat(service, liaison)
        formattedStr = addLabelAndString(service, liaison, labelAlignedStr)
    end

    methods (Sealed)
        function format = provideCoverageFormat(service, liaison)
            service.createResultsFolder(liaison);
            format = constructCoverageFormat(service, liaison);
        end
        
        function fulfill(services, liaison)
            supportingService = services.findServiceThatSupports(liaison.ResultPath, liaison.ResultFormat);

            % if format is specified, use that to find a supporting
            % service. if not, use file extension to infer format            
            if ~isempty(liaison.ResultFormat)
                key = liaison.ResultFormat;
            else
                key = liaison.Extension;
            end

            if isempty(supportingService)
                error(message("MATLAB:buildtool:TestTask:" + liaison.CatalogKey, key));
            end
        end

        function service = findServiceThatSupports(services, resultPath, formatClass)
            [~,~,ext] = fileparts(resultPath);
            for service = services                
                tf = service.supports(ext, CoverageFormat=formatClass);
                if tf
                    return;
                end
            end
            service = matlab.buildtool.internal.services.coverage.CoverageResultsService.empty();
        end

        function tf = supports(service, extension, options)
            arguments
                service (1,1) matlab.buildtool.internal.services.coverage.CoverageResultsService
                extension (1,1) string
                options.CoverageFormat string {mustBeScalarOrEmpty} = string.empty()
            end

            tf = service.Extension == extension;
            if ~isempty(options.CoverageFormat)
                tf = tf & service.CoverageFormatClass == options.CoverageFormat;
            end
        end
    end

    methods
        function files = listSupportingOutputFiles(service, liaison) %#ok<INUSD>
            files = matlab.buildtool.io.FileCollection.empty(1,0);
        end
    end

    methods (Static)
        function createResultsFolder(liaison)
            fpath = fileparts(liaison.ResultPath);
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
