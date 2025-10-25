classdef TestViewerLogRecord < matlab.unittest.internal.diagnostics.plugins.TestViewerRecord
    %TESTVIEWER Summary of this class goes here
    %   Detailed explanation goes here

%   Copyright 2024 The MathWorks, Inc.
    
    properties(Access=public)
        LogSummary;
    end

    properties(Hidden, Access=protected)
        Passed = false;
        Failed = false;
        Incomplete = false;
        Logged = true;
    end

    methods
        function record = TestViewerLogRecord(eventRecord, reportVerbosity)
            record = record@matlab.unittest.internal.diagnostics.plugins.TestViewerRecord(eventRecord, reportVerbosity);
            prepareLogSummary(record, eventRecord);
        end
    end

    methods(Access=private)
        function prepareLogSummary(record, eventRecord)
            % logEventRecord can have o to n FormattableDiagnosticResults,
            % using only the first element for log summary.
            record.LogSummary  = eventRecord.FormattableDiagnosticResults(1).FormattableDiagnosticText.Text;
        end
    end
end

