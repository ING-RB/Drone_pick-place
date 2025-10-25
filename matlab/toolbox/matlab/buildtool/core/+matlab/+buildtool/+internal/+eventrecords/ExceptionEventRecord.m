classdef ExceptionEventRecord < ...
        matlab.buildtool.internal.eventrecords.EventRecord
    % This class is unsupported and might change or be removed without notice
    % in a future version.
    
    % ExceptionEventRecord - Record of event which produced ExceptionEventData
    % instance
    
    % Copyright 2021-2023 The MathWorks, Inc.
    
    properties (SetAccess = immutable)
        Exception MException {mustBeScalarOrEmpty}
    end

    properties (Dependent, SetAccess = immutable)
        Stack (1,:) struct
    end
    
    methods
        function stack = get.Stack(eventRecord)
            import matlab.buildtool.internal.trimStack
            stack = trimStack(eventRecord.Exception.stack);
        end

        function str = getFormattedReport(record, formatter)
            arguments
                record (1,1) matlab.buildtool.internal.eventrecords.ExceptionEventRecord
                formatter (1,1) matlab.buildtool.internal.eventrecords.EventRecordFormatter
            end
            str = formatter.getExceptionEventReport(record);
        end
    end
    
    methods (Static)
        function record = fromEventData(eventData, eventScope, eventLocation)
            arguments
                eventData (1,1) {mustBeA(eventData,["matlab.buildtool.diagnostics.ExceptionEventData","struct"])}
                eventScope (1,1) matlab.buildtool.Scope
                eventLocation (1,1) string
            end
            
            import matlab.buildtool.internal.eventrecords.ExceptionEventRecord;
            
            name = eventData.EventName;
            exception = eventData.Exception;
            record = ExceptionEventRecord(name, eventScope, eventLocation, exception);
        end
    end
    
    methods (Access = private)
        function record = ExceptionEventRecord(eventName, eventScope, eventLocation, exception)
            record = record@matlab.buildtool.internal.eventrecords.EventRecord(eventName, eventScope, eventLocation);
            record.Exception = exception;
        end
    end
end

