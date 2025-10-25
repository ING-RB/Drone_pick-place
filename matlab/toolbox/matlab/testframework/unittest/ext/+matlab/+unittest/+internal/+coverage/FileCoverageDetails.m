classdef FileCoverageDetails < matlab.unittest.internal.coverage.FileCoverageInfo  
    % Class is undocumented and may change in a future release.
    
    %  Copyright 2021-2024 The MathWorks, Inc.
    
   
    properties (Dependent,SetAccess = private)        
        Namespace
        MethodCoverageInfoList 
        SourceList
        Complexity
    end

    properties (SetAccess = private)
        FullName
        FileIdentifier
        Metrics
        RawFileContent
        CodeCovData
    end

    properties(Access = private)
        SetFileIdentifier = false;
        SetMetrics = false;
        RawCoverageDataStruct
        MetricHandler
    end
    
    methods(Static)
        function infoArray = getCoverageFileInfoFromRawCoverageData(coverageResult, metricHandler, codeCovData)
            arguments
                coverageResult
                metricHandler
                codeCovData = cell(1,numel(coverageResult.CoverageData));
            end
            import matlab.unittest.internal.coverage.FileCoverageDetails;
            data = coverageResult.CoverageData;
            infoArrayCell = cell(1,numel(data));
            for idx = 1:numel(data)
                infoArrayCell{idx} = FileCoverageDetails(data(idx), metricHandler, codeCovData(idx));
            end
            infoArray = [FileCoverageDetails.empty(1,0),infoArrayCell{:}];
        end
    end
    
    
    methods
        
        function info = FileCoverageDetails(covData, metricHandler, codeCovData)
            info.FullName = covData.fileName;
            info.RawCoverageDataStruct = covData;
            if isfield(covData, 'rawFileContent') && ~isempty(covData.rawFileContent)
                info.RawFileContent = covData.rawFileContent;
            end
            info.MetricHandler = metricHandler;
            info.CodeCovData = codeCovData;
        end

        function fileIdentifier = get.FileIdentifier(fileCoverageInfo)
            import matlab.unittest.internal.getParentNameFromFilename
            if ~fileCoverageInfo.SetFileIdentifier
                [folder,shortName] = fileparts(fileCoverageInfo.FullName);

                [~,containingFolder] = fileparts(folder);
                if containingFolder == "private"
                    fileCoverageInfo.FileIdentifier = shortName;
                elseif startsWith(containingFolder,'@') && containingFolder ~= "@"+shortName
                    parentName = char(getParentNameFromFilename(fileCoverageInfo.FullName));
                    fileCoverageInfo.FileIdentifier = fullfile(parentName,shortName);
                else
                    fileCoverageInfo.FileIdentifier = char(getParentNameFromFilename(fileCoverageInfo.FullName));
                end
                fileCoverageInfo.SetFileIdentifier = true;
            end
            fileIdentifier = fileCoverageInfo.FileIdentifier;
        end

        function namespace = get.Namespace(fileCoverageInfo)
            import matlab.unittest.internal.getParentNameFromFilename;
            
            identifier = char(getParentNameFromFilename(fileCoverageInfo.FullName));
            namespace = getNamespace(identifier);
        end

        function source = get.SourceList(fileCoverageInfo)
            source = string(fileCoverageInfo.FullName);
        end

        function complexity = get.Complexity(~)
            complexity = NaN;
        end

        function metrics = get.Metrics(fileCoverageInfo)
            import matlab.unittest.internal.coverage.metrics.Metric
            if ~fileCoverageInfo.SetMetrics
                metricsCell = cell(1,numel(fileCoverageInfo.MetricHandler));
                for metricIdx = 1:numel(fileCoverageInfo.MetricHandler)
                    coverageDataForMetric = fileCoverageInfo.RawCoverageDataStruct.(fileCoverageInfo.MetricHandler(metricIdx).MetricNameUsedByCollector);
                    metricsCell{metricIdx} = fileCoverageInfo.MetricHandler(metricIdx).getMetricInstance(coverageDataForMetric);
                end
                fileCoverageInfo.Metrics = [Metric.empty(1:0),metricsCell{:}];
                fileCoverageInfo.SetMetrics = true;
            end
            metrics = fileCoverageInfo.Metrics;
        end

        function methodCoverageInfo = get.MethodCoverageInfoList(fileCoverageInfo)
            import matlab.automation.internal.services.ServiceLocator
            import matlab.unittest.internal.services.ServiceFactory

            namespace = "matlab.unittest.internal.services.coverage";

            locator = ServiceLocator.forNamespace(meta.package.fromName(namespace));
            serviceClass = ?matlab.unittest.internal.services.coverage.MethodCoverageInfoService;
            locatedServiceClasses = locator.locate(serviceClass);
            locatedServices = ServiceFactory.create(locatedServiceClasses);
            methodCoverageInfo = locatedServices.fulfill(fileCoverageInfo);
        end
    end
end 
function namespace = getNamespace(parentName)
ind = find(parentName == '.',1,'last');
 if isempty(ind)
     namespace = '';
 else
     namespace = parentName(1:ind-1);
 end
end

% LocalWords:  fileinformation
