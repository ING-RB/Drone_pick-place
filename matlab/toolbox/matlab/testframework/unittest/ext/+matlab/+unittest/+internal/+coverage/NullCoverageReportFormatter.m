classdef NullCoverageReportFormatter< matlab.unittest.internal.coverage.CoverageReportMetricFormatter

    % Class is undocumented and may change in a future release.
    
    %  Copyright 2021 The MathWorks, Inc.
    
    properties(Constant)
        OutputStructFieldName
    end

    methods 
        function  formatSummaryData(~)
            % no-op
        end 

        function  formatSourceDetailsData(~)
            % no-op
        end

        function formatBreakdownBySourceData(~)
            % no-op
        end
    end

end