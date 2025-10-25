classdef CoverageReportMetricFormatter
    % Interface class for the coverage data formatters used with the
    % CoverageReport format.

    %  Copyright 2021 The MathWorks, Inc.
    
    properties(Abstract, Constant)
        OutputStructFieldName
    end

    methods (Abstract)
        formatSummaryData
        formatSourceDetailsData
        formatBreakdownBySourceData
    end
end

