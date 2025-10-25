classdef ValidationEventRecord < ...
        matlab.buildtool.internal.eventrecords.EventRecord
    % This class is unsupported and might change or be removed without notice
    % in a future version.
    
    % Copyright 2022-2023 The MathWorks, Inc.

    properties (SetAccess = immutable)
        Failure matlab.buildtool.validations.ValidationFailure {mustBeScalarOrEmpty}
    end

    methods
        function str = getFormattedReport(record, formatter)
            arguments
                record (1,1) matlab.buildtool.internal.eventrecords.ValidationEventRecord
                formatter (1,1) matlab.buildtool.internal.eventrecords.EventRecordFormatter
            end
            str = formatter.getValidationEventReport(record);
        end
    end

    methods (Static)
        function record = fromEventData(eventData, eventScope, eventLocation)
            arguments
                eventData (1,1) {mustBeA(eventData,["matlab.buildtool.validations.ValidationEventData","struct"])}
                eventScope (1,1) matlab.buildtool.Scope
                eventLocation (1,1) string
            end
            
            import matlab.buildtool.internal.eventrecords.ValidationEventRecord;
            
            name = eventData.EventName;
            failure = eventData.Failure;
            record = ValidationEventRecord(name, eventScope, eventLocation, failure);
        end
    end

    methods (Access = private)
        function record = ValidationEventRecord(eventName, eventScope, eventLocation, failure)
            record = record@matlab.buildtool.internal.eventrecords.EventRecord(eventName, eventScope, eventLocation);
            record.Failure = failure;
        end
    end
end
