classdef CodeCoverageCollector < matlab.unittest.internal.plugins.CodeCoverageCollectorInterface
    % CodeCoverageCollector - A code coverage collector leveraging the
    % LXE's matlab.codecoveragetool.internal.CodeCoverageTool
    
    % Copyright 2020-2023 The MathWorks, Inc.
    
    properties (SetAccess=private)
        Results 
        Collecting = false
    end
    
    properties (Hidden,SetAccess = private)
        CoverageResultDataBase
        CoverageToolObject
        Sources
        CoverageMetric
        SourcesUsedByCoverageTool
    end

    properties(Access = private)
        SourcesChangedMask
        MetricHandlers
        CoverageToolBuiltinControlFcn
        MetricLevel
    end
    
    
    methods
        function initialize(collector)
            import  matlab.unittest.internal.CancelableCleanup
            [collector.MetricHandlers,locatedCoverageToolBuiltinControlFcn] = validateMetricLevel(collector.MetricLevel);
            if isempty(collector.CoverageToolBuiltinControlFcn)
                collector.CoverageToolBuiltinControlFcn = locatedCoverageToolBuiltinControlFcn;
            end
            collector.CoverageMetric = cellstr([collector.MetricHandlers.MetricName]);
            [collector.SourcesUsedByCoverageTool,collector.SourcesChangedMask] = collector.getExistingPFileNamesForSources(collector.Sources);    
            w = warning();
            warning('off');
            cleanup = CancelableCleanup(@()warning(w));
            collector.CoverageToolObject = collector.CoverageToolBuiltinControlFcn('newSession',collector.CoverageMetric,collector.SourcesUsedByCoverageTool);
            cleanup.cancelAndInvoke;
            if isempty(collector.CoverageToolObject)
                error(message('MATLAB:unittest:CoverageReport:CoverageSessionsWithOverlappingSourcesNotAllowed'));
            end
        end
        
        function start(collector,~)
            collector.CoverageToolBuiltinControlFcn('start',collector.CoverageToolObject);
            collector.Collecting = true;
        end
    
        function stop(collector)
            collector.CoverageToolBuiltinControlFcn('stop',collector.CoverageToolObject);
            collector.Collecting = false;
        end

        function result = get.Results(collector)
            if isempty(collector.CoverageToolObject)
                staticData = struct.empty;
                runtimeData = 0;
            else
                runtimeData = collector.CoverageToolBuiltinControlFcn('getRuntimeData',collector.CoverageToolObject);
                staticData = collector.CoverageToolBuiltinControlFcn('getStaticData',collector.CoverageToolObject);
                restoredStaticData = assignOriginalFileNamesToStaticData(staticData(collector.SourcesChangedMask),collector.Sources(collector.SourcesChangedMask), collector.MetricHandlers, runtimeData);
                staticData(collector.SourcesChangedMask) = restoredStaticData;
            end
            result = struct('StaticData', {staticData},'RuntimeData', {runtimeData});
        end
        
        function clearResults(~)
        end
        
        function reset(collector)
             collector.CoverageToolBuiltinControlFcn('clear',collector.CoverageToolObject);
             collector.CoverageToolObject = uint64.empty;
             collector.CoverageToolBuiltinControlFcn = function_handle.empty;
        end
        
        function collector = CodeCoverageCollector(fileNames,metricLevel,coverageToolFcn)
            arguments
                fileNames
                metricLevel = "statement";
                coverageToolFcn = function_handle.empty
            end
            collector.CoverageToolBuiltinControlFcn = coverageToolFcn;
            collector.Sources = cellstr(fileNames);
            collector.MetricLevel = metricLevel;
        end
    end

    methods(Access = private)
        function [sourcesWithPfileNames,ultimateMask] = getExistingPFileNamesForSources(collector,originalSources)
            % returns the sources with M-file names replaced with P-file names, and the
            % indices of the changed sources.

            [folder,parentName,ext] =  fileparts(originalSources);
            mFilenameMask = strcmp(ext,'.m');
            pFileNames = fullfile(folder,parentName+ ".p");
            pFileExistsMask = isfile(pFileNames);
            ultimateMask = mFilenameMask & pFileExistsMask;

            for fileIdx = find(ultimateMask)
                % check if the P-file and M-file are in sync
                validBool = collector.CoverageToolBuiltinControlFcn('isPFileFromMFile', [cellstr(pFileNames(fileIdx)) originalSources(fileIdx)]);
                if ~validBool
                    warning(message('MATLAB:unittest:CoverageReport:PFileExistsAndIsOutOfSync',originalSources{fileIdx},pFileNames(fileIdx)));
                end
            end

            originalSources(ultimateMask) = cellstr(pFileNames(ultimateMask));
            sourcesWithPfileNames = originalSources;
        end
    end
end



function staticData = assignOriginalFileNamesToStaticData(staticData, newFileName, metricHandlers, runtimeData)
for idx = 1:numel(staticData)
    currStaticData = staticData{idx};
    currStaticData.fileName = newFileName{idx};
    for metricHandler = metricHandlers
        staticDataForMetric = currStaticData.(metricHandler.MetricNameUsedByCollector);
        uniquifiedStaticDataForMetric = metricHandler.uniquifyStaticData(staticDataForMetric, runtimeData);
        currStaticData.(metricHandler.MetricNameUsedByCollector) = uniquifiedStaticDataForMetric;
    end
    staticData{idx} = currStaticData;
end
end

function [metricHandler,collectorBuiltin] = validateMetricLevel(metricLevel)
import matlab.unittest.internal.services.coverage.CoverageMetricsLiaison
import matlab.unittest.internal.coverage.locateCoverageReportMetricServices;

coverageMetricsServices = locateCoverageReportMetricServices;
liaison = CoverageMetricsLiaison(metricLevel,IssueWarningIfLicenseIsMissing=true);
fulfill(coverageMetricsServices,liaison);
metricHandler = [liaison.MetricHandler];
collectorBuiltin = liaison.CollectorBuiltIn{1};
end
