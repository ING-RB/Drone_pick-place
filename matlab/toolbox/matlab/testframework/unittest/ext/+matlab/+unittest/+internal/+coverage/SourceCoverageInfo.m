classdef (Abstract) SourceCoverageInfo < matlab.mixin.Heterogeneous & handle
    % Class is undocumented and may change in a future release.

    %  Copyright 2021 The MathWorks, Inc.

    properties (Abstract, SetAccess = private)
        SourceList
        Complexity
        Metrics
    end

    methods (Abstract)
        varargout = formatCoverageData(coverage,coverageFormatter,varargin)
    end

    methods
        function metrics = getCoverageData(coverageInfo, metricClass)
            % Use this method to extract Metric objects of a particular
            % type. For example, statement coverage data can be accessed as:  
            %   >> sourceCoverageInfo.getCoverageData('matlab.unittest.internal.coverage.metrics.StatementMetric');
            import matlab.unittest.internal.coverage.metrics.Metric
            allMetrics = [coverageInfo.Metrics];
            addedMetrics  = allMetrics(arrayfun(@(x) class(x) == string(metricClass),allMetrics));
            metrics = [Metric.empty(1,0) addedMetrics];
        end
    end
end
