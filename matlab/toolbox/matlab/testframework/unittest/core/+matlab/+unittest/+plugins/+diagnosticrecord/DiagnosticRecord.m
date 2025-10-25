classdef DiagnosticRecord < handle & matlab.mixin.Heterogeneous & matlab.mixin.CustomDisplay
    % DiagnosticRecord - Data structure that records diagnostic information
    %
    %   The DiagnosticRecord is a data structure that holds diagnostic
    %   information about a particular test result. It is created by the
    %   DiagnosticsRecordingPlugin. It contains information describing the
    %   event that caused the record to be created, the scope of the event, the
    %   location of the event, the stack at the time of creation of the record,
    %   and the complete report. It contains additional information
    %   corresponding to the type of event that created the record.
    %
    %   DiagnosticRecord methods:
    %       selectFailed     - Return the diagnostic records for failed events
    %       selectPassed     - Return the diagnostic records for passed events
    %       selectIncomplete - Return the diagnostic records for incomplete events
    %       selectLogged     - Return the diagnostic records for logged event
    %
    %   DiagnosticRecord properties:
    %       Event         - Name of the event that caused this diagnostic to be recorded
    %       EventScope    - Scope where the event originated
    %       EventLocation - Location where the event originated
    %       Stack         - Stack at the time the event originated
    %       Report        - Summary of the diagnostic record
    %
    %   Examples:
    %       import matlab.unittest.TestRunner;
    %       import matlab.unittest.TestSuite;
    %       import matlab.unittest.plugins.DiagnosticsRecordingPlugin;
    %
    %       runner = TestRunner.withTextOutput;
    %       runner.addPlugin(DiagnosticsRecordingPlugin());
    %
    %       suite = TestSuite.fromClass(?tfoo);
    %       result = runner.run(suite);
    %
    %       % Inspect the first test result
    %       firstResultDiagnostics = result(1).Details.DiagnosticRecord
    %
    %       % Inspect the failed records
    %       failedRecords = selectFailed(firstResultDiagnostics)
    %
    %   See also:
    %       matlab.unittest.plugins.DiagnosticsRecordingPlugin
    %       matlab.unittest.plugins.diagnosticrecord.QualificationDiagnosticRecord
    %       matlab.unittest.plugins.diagnosticrecord.LoggedDiagnosticRecord
    %       matlab.unittest.plugins.diagnosticrecord.ExceptionDiagnosticRecord
    
    % Copyright 2015-2020 The MathWorks, Inc.
    
    properties(Abstract, SetAccess=private)
        % Stack - Stack at the time the event originated
        %
        %   The Stack property is a structure that represents the call stack
        %   for the event that caused the diagnostic to be recorded.
        Stack;
    end
    
    properties(SetAccess=private)
        % Event - Name of the event that caused this diagnostic to be recorded
        %
        %   The Event property is a character vector that represents the name of
        %   the event that caused the diagnostic to be recorded.
        Event;
        
        % EventScope - Scope where the event originated
        %
        %   The EventScope property is a scalar matlab.unittest.Scope
        %   instance that represents the scope where the event originated.
        EventScope = matlab.unittest.Scope.empty(1,0);
        
        % EventLocation - Location where the event originated
        %
        %   The EventLocation property is a character vector that represents the
        %   location where the event that caused the diagnostic to be recorded
        %   originated.
        EventLocation;
    end
    
    properties(Dependent, SetAccess=immutable)
        % Report - Summary of the diagnostic record
        %
        %   The Report property is a character vector of the diagnostic record
        %   summary.
        Report;
    end
    
    properties(Hidden, SetAccess=private)
        % OutputDetail - Verbosity level describing amount of information recorded
        %
        %   The OutputDetail property is a scalar matlab.unittest.Verbosity
        %   instance that describes the amount of information that was recorded
        %   from the corresponding event.
        OutputDetail;
    end
    
    properties(Hidden, Dependent, SetAccess=immutable)
        % Scope - Location where the event originated
        %
        % Scope may be removed in a future release.  Use EventLocation instead.
        Scope
    end
    
    properties(Abstract, Hidden, Access=protected)
        Passed
        Failed
        Incomplete
        Logged
    end
    
    methods
        function value = get.Report(record)
            import matlab.unittest.internal.plugins.StandardEventRecordFormatter;
            
            formatter = StandardEventRecordFormatter();
            formatter.ReportVerbosity = record.OutputDetail;
            value = record.getFormattedReport(formatter);
            value = char(value.Text);
        end
        
        function value = get.Scope(record)
            value = record.EventLocation;
        end
        
        function value = get.EventScope(record)
            value = record.EventScope;
            if isempty(value)
                error(message('MATLAB:unittest:DiagnosticRecord:UnknownEventScope'));
            end
        end
    end
    
    methods(Abstract, Hidden, Access=protected)
        str = getFormattedReport(record, formatter);
        propList = getPropertyList(record);
        eventRecord = convertToEventRecord(record);
    end
    
    methods(Sealed, Hidden)
        function eventRecords = toEventRecord(records)
            import matlab.unittest.internal.eventrecords.EventRecord;
            eventRecordsCell = arrayfun(@convertToEventRecord,records,...
                'UniformOutput',false);
            eventRecords = [EventRecord.empty(1,0),eventRecordsCell{:}];
        end
    end
    
    methods(Hidden)
        function recordStruct = saveobj(record)
            % V3: R2018b and later
            recordStruct.V3.Event = record.Event;
            recordStruct.V3.EventLocation = record.EventLocation;
            recordStruct.V3.EventScope = record.EventScope;
            recordStruct.V3.OutputDetail = record.OutputDetail;
        end
    end
    
    methods(Hidden, Access=protected)
        function record = reload(record, recordStruct)
            record.Event = recordStruct.V3.Event;
            record.EventScope = recordStruct.V3.EventScope;
            record.EventLocation = recordStruct.V3.EventLocation;
            record.OutputDetail = recordStruct.V3.OutputDetail;
        end
    end
    
    methods(Sealed)
        function record = selectFailed(record)
            % selectFailed - Return the diagnostic records for failed events.
            %
            %   FAILEDRECORDS = selectFailed(RECORDS) selects the diagnostic
            %   records corresponding to failed events contained within RECORDS.
            %
            %   Example:
            %
            %   result = run(tfoo);
            %   % Inspect the first test result
            %   firstResultDiagnostics = result(1).Details.DiagnosticRecord
            %
            %   % Find all the diagnostic records corresponding to failed events
            %   failedRecords = selectFailed(firstResultDiagnostics);
            record = record([false(1,0),record.Failed]);
        end
        
        function record = selectPassed(record)
            % selectPassed - Return the diagnostic records for passed events.
            %
            %   PASSEDRECORDS = selectPassed(RECORDS) selects the diagnostic
            %   records corresponding to passing events contained within RECORDS.
            %
            %   Example:
            %
            %   import matlab.unittest.TestRunner;
            %   import matlab.unittest.TestSuite;
            %   import matlab.unittest.plugins.DiagnosticsRecordingPlugin;
            %
            %   runner = TestRunner.withTextOutput;
            %   runner.addPlugin(DiagnosticsRecordingPlugin('IncludingPassingDiagnostics', true));
            %
            %   suite = TestSuite.fromClass(?tfoo);
            %   result = runner.run(suite);
            %
            %   % Inspect the first test result
            %   firstResultDiagnostics = result(1).Details.DiagnosticRecord
            %
            %   % Find all the diagnostic records corresponding to passed events
            %   passedRecords = selectPassed(firstResultDiagnostics);
            record = record([false(1,0),record.Passed]);
        end
        
        function record = selectIncomplete(record)
            % selectIncomplete - Return the diagnostic records for incomplete events.
            %
            %   INCOMPLETERECORDS = selectIncomplete(RECORDS) selects the diagnostic
            %   records corresponding to incomplete events contained within RECORDS.
            %
            %   Example:
            %
            %   result = run(tfoo);
            %   % Inspect the first test result
            %   firstResultDiagnostics = result(1).Details.DiagnosticRecord
            %
            %   % Find all the diagnostic records corresponding to incomplete events
            %   incompleteRecords = selectIncomplete(firstResultDiagnostics);
            record = record([false(1,0),record.Incomplete]);
        end
        
        function record = selectLogged(record)
            % selectLogged - Return the diagnostic records for logged events.
            %
            %   LOGGEDRECORDS = selectLogged(RECORDS) selects the diagnostic
            %   records corresponding to logged events contained within RECORDS.
            %
            %   Example:
            %
            %   result = run(tfoo);
            %   % Inspect the first test result
            %   firstResultDiagnostics = result(1).Details.DiagnosticRecord
            %
            %   % Find all the diagnostic records corresponding to logged events
            %   loggedRecords = selectLogged(firstResultDiagnostics);
            record = record([false(1,0),record.Logged]);
        end
    end
    
    methods(Hidden, Access=protected)
        function record = DiagnosticRecord(eventRecord,outputDetail)
            if nargin == 0
                return;
            end
            
            record.Event = eventRecord.EventName;
            record.EventScope = eventRecord.EventScope;
            record.EventLocation = eventRecord.EventLocation;
            record.OutputDetail = outputDetail;
        end
    end
    
    methods (Sealed, Hidden, Access=protected)
        function propGrp = getPropertyGroups(record)
            if isequal(class(record),'matlab.unittest.plugins.diagnosticrecord.DiagnosticRecord')
                % Heterogeneous case needs to be "fixed"
                propList = {'Event','EventScope','EventLocation','Stack','Report'};
            else
                propList = record.getPropertyList();
            end
            propGrp = matlab.mixin.util.PropertyGroup(propList);
        end
        
        function varargout = displayNonScalarObject(varargin)
            % Overridden in order to meet the Heterogeneous array requirement: Sealed
            [varargout{1:nargout}] = displayNonScalarObject@matlab.mixin.CustomDisplay(varargin{:});
        end
        
        function varargout = getHeader(varargin)
            % Overridden in order to meet the Heterogeneous array requirement: Sealed
            [varargout{1:nargout}] = getHeader@matlab.mixin.CustomDisplay(varargin{:});
        end
        
        function varargout = getFooter(varargin)
            % Overridden in order to meet the Heterogeneous array requirement: Sealed
            [varargout{1:nargout}] = getFooter@matlab.mixin.CustomDisplay(varargin{:});
        end
    end
end

% LocalWords:  tfoo diagnosticrecord formatter FAILEDRECORDS PASSEDRECORDS
% LocalWords:  INCOMPLETERECORDS LOGGEDRECORDS Grp eventrecords
