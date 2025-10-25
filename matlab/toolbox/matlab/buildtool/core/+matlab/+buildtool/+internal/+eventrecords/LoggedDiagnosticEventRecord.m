classdef LoggedDiagnosticEventRecord < ...
        matlab.buildtool.internal.eventrecords.EventRecord
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % LoggedDiagnosticEventRecord - Record of event which produced a 
    % LoggedDiagnosticEventData instance

    % Copyright 2021-2023 The MathWorks, Inc.
    
    properties (SetAccess = immutable)
        % Verbosity - Verbosity at which diagnostic was logged
        Verbosity (1,1) matlab.automation.Verbosity

        % Timestamp - Date and time of call to the LOG method
        Timestamp (1,1) datetime

        % DiagnosticResult - Results of logged diagnostics
        DiagnosticResult (1,:) matlab.automation.diagnostics.DiagnosticResult
    end

    methods
        function str = getFormattedReport(record, formatter)
            arguments
                record (1,1) matlab.buildtool.internal.eventrecords.LoggedDiagnosticEventRecord
                formatter (1,1) matlab.buildtool.internal.eventrecords.EventRecordFormatter
            end
            str = formatter.getLoggedDiagnosticEventReport(record);
        end
    end
    
    methods (Static)
        function record = fromEventData(eventData, eventScope, eventLocation)
            arguments
                eventData (1,1) {mustBeA(eventData,["matlab.buildtool.diagnostics.LoggedDiagnosticEventData","struct"])}
                eventScope (1,1) matlab.buildtool.Scope
                eventLocation (1,1) string
            end

            import matlab.buildtool.internal.eventrecords.LoggedDiagnosticEventRecord;
            import matlab.automation.diagnostics.DiagnosticResult;

            name = eventData.EventName;
            verbosity = eventData.Verbosity;
            timestamp = eventData.Timestamp;
            result = arrayfun(@(d)captureResult(d), eventData.Diagnostic);
            result = [result DiagnosticResult.empty()];
            record = LoggedDiagnosticEventRecord(name, eventScope, eventLocation, verbosity, timestamp, result);
        end
    end

    methods (Access = private)
        function record = LoggedDiagnosticEventRecord(eventName, eventScope, eventLocation, verbosity, timestamp, result)
            record = record@matlab.buildtool.internal.eventrecords.EventRecord(eventName, eventScope, eventLocation);
            record.Verbosity = verbosity;
            record.Timestamp = timestamp;
            record.DiagnosticResult = result;
        end
    end
end

function result = captureResult(diag)
import matlab.automation.diagnostics.DiagnosticResult;
diag = safelyDiagnose(diag);
result = DiagnosticResult(matlab.automation.diagnostics.Artifact.empty, diag.DiagnosticText);
end

function diag = safelyDiagnose(diag)
import matlab.buildtool.internal.diagnostics.ExceptionDiagnostic;
try
    diag.diagnose();
catch exception
    diag = ExceptionDiagnostic(exception, "MATLAB:buildtool:Diagnostic:ErrorCapturingDiagnostics");
    diag.diagnose();
end
end
