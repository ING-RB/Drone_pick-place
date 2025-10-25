classdef TestViewerRecord < handle & matlab.mixin.Heterogeneous
%

%   Copyright 2024 The MathWorks, Inc.

   properties(Access=public)
        FailedOnLine;
        Stack;
        Report;
        Event;
        ArtifactPath;
   end

   properties(Abstract, Hidden, Access=protected)
        Passed
        Failed
        Incomplete
        Logged
   end

   properties(Hidden, Access=protected)
       EventRecord
   end

   properties (Constant, Access = private)
        BaselineQualFailureTypes = {'VerificationFailed', 'AssumptionFailed', 'AssertionFailed', 'FatalAssertionFailed'}
    end

   methods(Sealed)
        function records = selectFailed(records)
            records = records([records.Failed]);
        end
        
        function records = selectPassed(records)
            records = records([records.Passed]);
        end
        
        function records = selectIncomplete(records)
            records = records([records.Incomplete]);
        end
        
        function records = selectLogged(records)
            records = records([records.Logged]);
        end
   end

    methods(Sealed, Hidden)
        function eventRecords = toEventRecord(records)
            import matlab.unittest.internal.eventrecords.EventRecord;
            eventRecordsCell = arrayfun(@(rec) rec.EventRecord, records,...
                'UniformOutput',false);
            eventRecords = [EventRecord.empty(1,0),eventRecordsCell{:}]; %#ok<PROP>
        end
   end

   methods(Access=public)
       function record = TestViewerRecord(eventRecord, reportVerbosity)
            if nargin == 0
                return;
            end
            
            record.EventRecord = eventRecord;
            record.Event = eventRecord.EventName;
            prepareStack(record, eventRecord);
            prepareReport(record,eventRecord, reportVerbosity);
            storeBaselineFailureArtifactPath(record, eventRecord);
        end
   end

   methods(Access=private)
        function prepareStack(record,eventRecord)
            record.FailedOnLine = '';
            if ~isempty(eventRecord.Stack)
                record.Stack = eventRecord.Stack;
                record.FailedOnLine = string(record.Stack(end).line);
            end
        end

        function prepareReport(record, eventRecord, reportVerbosity)
            formatter = matlab.unittest.internal.plugins.StandardEventRecordFormatter();
            formatter.ReportVerbosity = reportVerbosity;
            record.Report =  string(eventRecord.getFormattedReport(formatter));
        end

        function storeBaselineFailureArtifactPath(record, eventRecord)
            record.ArtifactPath = "";
            isBaselineQualFailure = ismember(eventRecord.EventName, record.BaselineQualFailureTypes);
            if isBaselineQualFailure    
                allArtifacts = [eventRecord.FormattableFrameworkDiagnosticResults.Artifacts];
                isBaselineArtifact = arrayfun(@(artifact)isa(artifact, "matlabtest.internal.diagnostics.BaselineFailureArtifact"), allArtifacts);
                if any(isBaselineArtifact)
                    baselineArtifacts = allArtifacts(isBaselineArtifact);
                    record.ArtifactPath = [baselineArtifacts.FullPath];
                end
            end
        end
   end

end
