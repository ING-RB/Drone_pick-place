classdef EventRecordProducer < handle
    % This class is unsupported and might change or be removed without notice
    % in a future version.
    
    % Copyright 2021-2023 The MathWorks, Inc.

    properties
        % LoggingLevel - Maximum verbosity level at which logged diagnostics are recorded
        LoggingLevel (1,1) matlab.automation.Verbosity = matlab.automation.Verbosity.Concise
    end

    properties (Constant, Access = private)
        BuildFixtureEvents = ["ValidationFailed","ExceptionThrown"]
        TaskContextEvents = ["DiagnosticLogged","ValidationFailed","ExceptionThrown","AssertionFailed"]
    end

    methods (Abstract)
        processEventRecord(producer, eventRecord)
    end
    
    methods
        function listeners = addListenersToBuildFixture(producer, fixture, eventLocation)
            arguments
                producer (1,1) matlab.buildtool.internal.plugins.EventRecordProducer
                fixture (1,1) matlab.buildtool.internal.fixtures.Fixture
                eventLocation (1,1) string
            end
            listeners = producer.addListenersForEvents(producer.BuildFixtureEvents, fixture, matlab.buildtool.Scope.Fixture, eventLocation);
        end

        function listeners = addListenersToTaskContext(producer, context, eventLocation)
            arguments
                producer (1,1) matlab.buildtool.internal.plugins.EventRecordProducer
                context (1,1) matlab.buildtool.TaskContext
                eventLocation (1,1) string
            end
            listeners = producer.addListenersForEvents(producer.TaskContextEvents, context, matlab.buildtool.Scope.Task, eventLocation);
        end
    end
    
    methods (Access = private)
        function listeners = addListenersForEvents(producer, eventNames, instance, eventScope, eventLocation)
            listeners = event.listener.empty(1,0);
            for k = 1:numel(eventNames)
                eventName = eventNames(k);
                if eventName == "DiagnosticLogged"
                    listeners(k) = instance.addlistener(eventName, @(~,eventData) ...
                        producer.produceLoggedDiagnosticEventRecord(eventData,eventScope,eventLocation));
                elseif eventName == "ValidationFailed"
                    listeners(k) = instance.addlistener(eventName, @(~,eventData) ...
                        producer.produceValidationEventRecord(eventData,eventScope,eventLocation));
                elseif eventName == "ExceptionThrown"
                    listeners(k) = instance.addlistener(eventName, @(~,eventData) ...
                        producer.produceExceptionEventRecord(eventData,eventScope,eventLocation));
                elseif eventName == "AssertionFailed"
                    listeners(k) = instance.addlistener(eventName, @(~,eventData) ...
                        producer.produceQualificationEventRecord(eventData,eventScope,eventLocation));
                end
            end
        end

        function produceLoggedDiagnosticEventRecord(producer, eventData, eventScope, eventLocation)
            import matlab.buildtool.internal.eventrecords.LoggedDiagnosticEventRecord;

            if eventData.Verbosity <= producer.LoggingLevel
                record = LoggedDiagnosticEventRecord.fromEventData(eventData, eventScope, eventLocation);
                producer.processEventRecord(record);
            end
        end

        function produceValidationEventRecord(producer, eventData, eventScope, eventLocation)
            import matlab.buildtool.internal.eventrecords.ValidationEventRecord;

            record = ValidationEventRecord.fromEventData(eventData, eventScope, eventLocation);
            producer.processEventRecord(record);
        end
        
        function produceExceptionEventRecord(producer, eventData, eventScope, eventLocation)
            import matlab.buildtool.internal.eventrecords.ExceptionEventRecord;
            
            record = ExceptionEventRecord.fromEventData(eventData, eventScope, eventLocation);
            producer.processEventRecord(record);
        end

        function produceQualificationEventRecord(producer, eventData, eventScope, eventLocation)
            import matlab.buildtool.internal.eventrecords.QualificationEventRecord;
            
            record = QualificationEventRecord.fromEventData(eventData, eventScope, eventLocation);
            producer.processEventRecord(record);
        end
    end
end

