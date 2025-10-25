classdef QualificationEventRecord < matlab.buildtool.internal.eventrecords.EventRecord
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % Copyright 2023 The MathWorks, Inc.

    properties (SetAccess = immutable)
        Stack (1,:) struct
        FormattableTaskDiagnosticResults (1,:) matlab.automation.internal.diagnostics.FormattableDiagnosticResult
    end

    methods
        function str = getFormattedReport(record, formatter)
            str = formatter.getQualificationEventReport(record);
        end
    end

    methods (Static)
        function eventRecord = fromEventData(eventData, eventScope, eventLocation)
            arguments
                eventData (1,1) {mustBeA(eventData, ["matlab.buildtool.internal.qualifications.QualificationEventData","struct"])}
                eventScope (1,1) matlab.buildtool.Scope
                eventLocation (1,1) string
            end

            import matlab.buildtool.internal.eventrecords.QualificationEventRecord;
            eventName = eventData.EventName;
            stack = eventData.Stack;
            formattableTaskDiagnosticResults = eventData.FormattableTaskDiagnosticResults;
            eventRecord = QualificationEventRecord(eventName, eventScope, eventLocation, ...
                stack, formattableTaskDiagnosticResults);
        end
    end

    methods (Access = private)
        function eventRecord = QualificationEventRecord(eventName, eventScope, eventLocation, ...
                stack, formattableTaskDiagnosticResults)
            eventRecord = eventRecord@matlab.buildtool.internal.eventrecords.EventRecord(...
                eventName, eventScope, eventLocation);

            eventRecord.Stack = stack;
            eventRecord.FormattableTaskDiagnosticResults = formattableTaskDiagnosticResults;
        end
    end
end