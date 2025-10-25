classdef CoverageFilterManagerLiaison < handle
    % This class is undocumented and will change in a future release.
    % CoverageFilterManagerLiaison - Class to handle coverage filtering data between CoverageMetricsService classes.

    % Copyright 2024 The MathWorks, Inc.

    properties (SetAccess = immutable)
        ReportID string;        
        ReportData struct
    end

    properties
        ReceiverChannelName = ""
        PublisherChannelName = ""
        FilterDataStructArray = struct.empty;
    end

    methods
        function liaison = CoverageFilterManagerLiaison(reportID, reportData)
            arguments
                reportID {mustBeTextScalar}
                reportData (1,1) struct
            end

            liaison.ReportID = reportID;
            liaison.ReportData = reportData;
        end
    end
end