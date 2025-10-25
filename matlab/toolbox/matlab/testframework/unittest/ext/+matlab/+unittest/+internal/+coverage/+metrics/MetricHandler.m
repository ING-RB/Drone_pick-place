classdef MetricHandler < matlab.mixin.Heterogeneous
    % Interface class for the handlers of different code coverage metric classes

    %  Copyright 2021-2022 The MathWorks, Inc.

    properties (Abstract, Constant)
        MetricNameUsedByCollector
        MetricName
    end

    methods (Abstract)
        getMetricInstance
        getFormatter
    end

    methods
        function stringsStruct = getMessageCatalogEntriesForMetrics(~, stringsStruct)
        end

        function staticDataForMetric = uniquifyStaticData(~,staticDataForMetric,~)
        end
    end
end

