classdef CodeCoverageResult < handle
    % Class is undocumented and may change in a future release.
    
    % Copyright 2021-2022 The MathWorks, Inc.
    
    properties (Access=private)
        % replace these with the result database object in the future
        StaticData
        RuntimeData
        NumberOfFiles
        MetricsFieldNames
    end
    
    properties (Dependent)
        CoverageData
    end
    
    properties (Access=private)
        CombinedCoverageData = "UNASSIGNED";
        MetricHandlers        
    end
    
    methods
        function r = CodeCoverageResult(staticData, runtimeData, metricHandlers)
            r.StaticData = staticData;
            r.RuntimeData = double(runtimeData);
            r.NumberOfFiles = numel(staticData);
            [r.MetricsFieldNames, uniqueMetricFieldNameIdx] = unique(string([metricHandlers.MetricNameUsedByCollector]),'stable');
            r.MetricHandlers = metricHandlers(uniqueMetricFieldNameIdx);
            r.CombinedCoverageData = "UNASSIGNED";
        end
        
        function covData = get.CoverageData(resultObj)            
            
            if isequal(resultObj.CombinedCoverageData,"UNASSIGNED")
                % For each file, combine the static data with the runtime
                % data. The raw static data includes indices of hit counts
                % in the runtimeData array. Replace the indices with actual
                % values from the runtimeData available.
                covDataCell = cell(1, resultObj.NumberOfFiles);
                
                for fileIdx = 1:resultObj.NumberOfFiles
                    covDataStruct = resultObj.StaticData{fileIdx};
                    for metricIdx = 1:numel(resultObj.MetricHandlers)
                        staticDataForMetric = covDataStruct.(resultObj.MetricsFieldNames(metricIdx));
                        combinedStaticData = resultObj.MetricHandlers(metricIdx).combineStaticAndRuntimeData(staticDataForMetric, resultObj.RuntimeData);
                        covDataStruct.(resultObj.MetricsFieldNames(metricIdx)) = combinedStaticData;
                    end
                    covDataCell{fileIdx} = covDataStruct;
                end
                resultObj.CombinedCoverageData = [covDataCell{:}];
            end
            covData = resultObj.CombinedCoverageData;            
        end
    end
end