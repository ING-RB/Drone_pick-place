classdef LoggedDiagnosticRecord < matlab.unittest.plugins.diagnosticrecord.DiagnosticRecord
    % LoggedDiagnosticRecord - Data structure that represents a logged event
    %
    %   LoggedDiagnosticRecord is a data structure that represents diagnostic
    %   information about logged events. In addition to providing information
    %   about the event that caused the record to be created, the scope of the
    %   event, the location of the event, the stack at the time of creation of
    %   the record, and the complete report, it also provides information about
    %   the logged diagnostics, the verbosity, and the time at which the
    %   diagnostic was logged.
    %
    %   LoggedDiagnosticRecord methods:
    %       selectFailed     - Return the diagnostic records for failed events
    %       selectPassed     - Return the diagnostic records for passed events
    %       selectIncomplete - Return the diagnostic records for incomplete events
    %       selectLogged     - Return the diagnostic records for logged events
    %
    %   LoggedDiagnosticRecord properties:
    %       Event                   - Name of the event that caused this diagnostic to be recorded
    %       EventScope              - Scope where the event originated
    %       EventLocation           - Location where the event originated
    %       LoggedDiagnosticResults - Results of diagnostics specified in the log method call
    %       Verbosity               - Verbosity at which this diagnostic was logged
    %       Timestamp               - The date and time of the call to the log method
    %       Stack                   - Stack at the time the event originated
    %       Report                  - Summary of the diagnostic record
    %
    %   See also:
    %       matlab.unittest.plugins.DiagnosticsRecordingPlugin
    %       matlab.unittest.plugins.diagnosticrecord.DiagnosticRecord
    %       matlab.unittest.plugins.diagnosticrecord.QualificationDiagnosticRecord
    %       matlab.unittest.plugins.diagnosticrecord.ExceptionDiagnosticRecord
    
    % Copyright 2015-2020 The MathWorks, Inc.
    
    properties(SetAccess=private)
        % LoggedDiagnosticResults - Results of diagnostics specified in the log method call
        %
        %   The LoggedDiagnosticResults property is a DiagnosticResult array
        %   holding the results from diagnosing the diagnostics specified in the
        %   log method call.
        %
        %   See also:
        %       matlab.unittest.diagnostics.DiagnosticResult
        LoggedDiagnosticResults;
        
        % Verbosity - Verbosity at which this diagnostic was logged
        %
        %   Verbosity is a scalar instance of matlab.unittest.Verbosity
        %   at which the diagnostic was logged.
        Verbosity;
        
        % Timestamp - The date and time of the call to the log method
        %
        %   The Timestamp property is a datetime instance that records the
        %   moment when the log method was called.
        Timestamp
        
        % Stack - Stack at the time the event was logged
        %
        %   The Stack property is a structure that represents the call stack
        %   at the time of the logged event.
        Stack;
    end
    
    properties(Hidden, Access=protected)
        Passed = false;
        Failed = false;
        Incomplete = false;
        Logged = true;
    end
    
    properties(Hidden, Dependent, SetAccess=immutable)
        % LoggedDiagnosticResult - LoggedDiagnosticResult is not recommended. Use LoggedDiagnosticResults instead.
        LoggedDiagnosticResult
    end
    
    methods(Hidden)
        function record = LoggedDiagnosticRecord(varargin)
            record = record@matlab.unittest.plugins.diagnosticrecord.DiagnosticRecord(varargin{:});
            if nargin == 0
                return;
            end
            
            eventRecord = varargin{1};
            record.LoggedDiagnosticResults = ...
                eventRecord.FormattableDiagnosticResults.toDiagnosticResultsWithoutFormat();
            record.Verbosity = eventRecord.Verbosity;
            record.Timestamp = eventRecord.Timestamp;
            record.Stack = eventRecord.Stack;
        end
        
        function recordStruct = saveobj(record)
            recordStruct = saveobj@matlab.unittest.plugins.diagnosticrecord.DiagnosticRecord(record);
            % SubVersion1: R2018b and later
            recordStruct.SubVersion1.LoggedDiagnosticResults = record.LoggedDiagnosticResults;
            recordStruct.SubVersion1.Verbosity = record.Verbosity;
            recordStruct.SubVersion1.Timestamp = record.Timestamp;
            recordStruct.SubVersion1.Stack = record.Stack;
        end
    end
    
    methods(Hidden,Static)
        function record = loadobj(recordStruct)
            record = matlab.unittest.plugins.diagnosticrecord.LoggedDiagnosticRecord();
            record.reload(recordStruct);
        end
    end
    
    methods(Hidden, Access=protected)
        function record = reload(record, recordStruct)
            record.reload@matlab.unittest.plugins.diagnosticrecord.DiagnosticRecord(recordStruct);
            record.LoggedDiagnosticResults = recordStruct.SubVersion1.LoggedDiagnosticResults;
            record.Verbosity = recordStruct.SubVersion1.Verbosity;
            record.Timestamp = recordStruct.SubVersion1.Timestamp;
            record.Stack = recordStruct.SubVersion1.Stack;
        end
        
        function str = getFormattedReport(record, formatter)
            str = formatter.getLoggedDiagnosticEventReport(record.convertToEventRecord());
        end
        
        function propList = getPropertyList(~)
            propList = {'Event','EventScope','EventLocation',...
                'LoggedDiagnosticResults','Verbosity','Timestamp','Stack','Report'};
        end
        
        function eventRecord = convertToEventRecord(record)
            import matlab.unittest.internal.eventrecords.LoggedDiagnosticEventRecord;
            eventRecord = LoggedDiagnosticEventRecord.fromDiagnosticRecord(record);
        end
    end
    
    methods
        function cellOfChars = get.LoggedDiagnosticResult(record)
            cellOfChars = {record.LoggedDiagnosticResults.DiagnosticText};
        end
    end
end

% LocalWords:  diagnosticrecord Formattable formatter eventrecords
