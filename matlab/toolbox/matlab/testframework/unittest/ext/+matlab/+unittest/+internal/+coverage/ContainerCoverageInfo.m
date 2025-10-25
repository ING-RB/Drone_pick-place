classdef ContainerCoverageInfo < matlab.unittest.internal.coverage.SourceCoverageInfo
    % Class is undocumented and may change in a future release.
    
    %  Copyright 2021 The MathWorks, Inc.
    
    properties (Abstract,SetAccess = private)
        SourceCoverageInfoList matlab.unittest.internal.coverage.SourceCoverageInfo
    end 
    
    properties (Dependent,SetAccess = private)
        SourceList
        Complexity
        Metrics
    end
    
    methods       
        function sources = get.SourceList(coverageInfo)
            sources = coverageInfo.generateSourceList;
        end
        
        function complexity = get.Complexity(coverageInfo)
           complexity = coverageInfo.generateComplexity; 
        end

        function metrics = get.Metrics(coverageInfo)
            metrics = coverageInfo.getMetricsList;
        end
    end
    
    methods (Access = private)
        function sources = generateSourceList(info)
            sources = [info.SourceCoverageInfoList.SourceList];
        end
        
        function complexity = generateComplexity(info)
            complexity = sum([info.SourceCoverageInfoList.Complexity],'omitnan');
            if isequal(complexity,0)
                complexity = nan;
            end
        end

        function metrics = getMetricsList(info)
            metrics = [info.SourceCoverageInfoList.Metrics];
        end
    end
end

