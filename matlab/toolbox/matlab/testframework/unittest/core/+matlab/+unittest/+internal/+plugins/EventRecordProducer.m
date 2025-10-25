classdef EventRecordProducer < handle
    %This class is undocumented and may change in a future release.
    
    %  Copyright 2016-2021 The MathWorks, Inc.
    
    properties
        %FixtureEvents - Fixture events from which to produce event records
        %
        %   The FixtureEvents property is a string array containing the names of
        %   the Fixture events to listen to in order to produce corresponding
        %   EventRecords.
        FixtureEvents = matlab.unittest.internal.plugins.EventRecordProducer.AllExceptPassingFixtureEvents;
        
        %TestCaseEvents - TestCase events from which to produce event records
        %
        %   The TestCaseEvents property is a string array containing the names of
        %   the TestCase events to listen to in order to produce corresponding
        %   EventRecords.
        TestCaseEvents = matlab.unittest.internal.plugins.EventRecordProducer.AllExceptPassingTestCaseEvents;
        
        %LoggingLevel - Maximum verbosity level at which logged diagnostics are recorded
        LoggingLevel (1,1) matlab.unittest.Verbosity = matlab.unittest.Verbosity.Terse;
        
        %OutputDetail -  Verbosity level that controls amount of displayed information
        OutputDetail (1,1) matlab.unittest.Verbosity = matlab.unittest.Verbosity.Detailed;
    end
    
    properties(Constant,Access=private)
        AllFixtureEvents = [...
            matlab.unittest.internal.plugins.EventRecordProducer.AllExceptPassingFixtureEvents,...
            "AssertionPassed","FatalAssertionPassed","AssumptionPassed"];
        
        AllTestCaseEvents = [...
            matlab.unittest.internal.plugins.EventRecordProducer.AllExceptPassingTestCaseEvents,...
            "AssertionPassed","FatalAssertionPassed","AssumptionPassed","VerificationPassed"];

        AllExceptPassingFixtureEvents = ["DiagnosticLogged","ExceptionThrown",...
            "AssertionFailed","FatalAssertionFailed","AssumptionFailed"];
        
        AllExceptPassingTestCaseEvents = [...
            matlab.unittest.internal.plugins.EventRecordProducer.AllExceptPassingFixtureEvents,...
            "VerificationFailed"];
    end
    
    properties(Hidden, Access=private)
        Buffer;
    end
    
    methods(Abstract)
        processEventRecord(producer,eventRecord,indices)
    end
    
    methods
        
        function producer = EventRecordProducer()
            import matlab.unittest.internal.plugins.TestResultDetailsBuffer;
            producer.Buffer = TestResultDetailsBuffer;
        end
        
        function set.FixtureEvents(producer,value)
            value = toUniqueRow(string(value));
            assert(isempty(setdiff(value,producer.AllFixtureEvents))); %Internal validation
            producer.FixtureEvents = value;
        end
        
        function set.TestCaseEvents(producer,value)
            value = toUniqueRow(string(value));
            assert(isempty(setdiff(value,producer.AllTestCaseEvents))); %Internal validation
            producer.TestCaseEvents = value;
        end
        
        function addListenersToSharedTestFixture(producer, fixture, eventLocation, locationProvider)
            validateattributes(eventLocation,{'char'},{'nonempty','row'},'','eventLocation');
            eventScope = matlab.unittest.Scope.SharedTestFixture;
            eventNames = producer.FixtureEvents;
            producer.addListenersForEvents(eventNames, fixture, eventScope, eventLocation, locationProvider);
        end
        
        function addListenersToTestClassInstance(producer, testClassInstance, eventLocation, locationProvider)
            validateattributes(eventLocation,{'char'},{'nonempty','row'},'','eventLocation');
            eventScope = matlab.unittest.Scope.TestClass;
            eventNames = producer.TestCaseEvents;
            producer.addListenersForEvents(eventNames, testClassInstance, eventScope, eventLocation, locationProvider);
        end
        
        function addListenersToTestRepeatLoopInstance(producer, testRepeatLoopInstance, eventLocation, locationProvider)
            validateattributes(eventLocation,{'char'},{'nonempty','row'},'','eventLocation');
            eventScope = matlab.unittest.Scope.TestMethod;
            eventNames = producer.TestCaseEvents;
            producer.addListenersForEvents(eventNames, testRepeatLoopInstance, eventScope, eventLocation, locationProvider);
        end
        
        function addListenersToTestMethodInstance(producer, testMethodInstance, eventLocation, locationProvider)
            validateattributes(eventLocation,{'char'},{'nonempty','row'},'','eventLocation');
            eventScope = matlab.unittest.Scope.TestMethod;
            eventNames = producer.TestCaseEvents;
            producer.addListenersForEvents(eventNames, testMethodInstance, eventScope, eventLocation, locationProvider);
        end
        
        function removeFailureEvents(producer)
            failureEvents = ["AssertionFailed","AssumptionFailed","ExceptionThrown","FatalAssertionFailed","VerificationFailed"];
            producer.FixtureEvents = setdiff(producer.FixtureEvents, failureEvents);
            producer.TestCaseEvents = setdiff(producer.TestCaseEvents, failureEvents);
        end
        
        function addPassingEvents(producer)
            passingEvents = ["AssertionPassed","AssumptionPassed","FatalAssertionPassed"];
            producer.FixtureEvents = [producer.FixtureEvents, passingEvents];
            producer.TestCaseEvents = [producer.TestCaseEvents, passingEvents,"VerificationPassed"];
        end
    end
    
    methods(Access = protected)
        function addListenersForEvents(producer, eventNames, instance, eventScope, eventLocation, locationProvider)
            for k=1:numel(eventNames)
                eventName = eventNames{k};
                if strcmp(eventName,"DiagnosticLogged")
                    if producer.LoggingLevel ~= matlab.unittest.Verbosity.None
                        instance.addlistener(eventName,@(~,eventData) ...
                            producer.produceLoggedDiagnosticEventRecord(eventData,eventScope,eventLocation,locationProvider));
                    end
                elseif strcmp(eventName,"ExceptionThrown")
                    instance.addlistener(eventName,@(~,eventData) ...
                        producer.produceExceptionEventRecord(eventData,eventScope,eventLocation,locationProvider));
                else % Qualification
                    instance.addlistener(eventName,@(~,eventData) ...
                        producer.produceQualificationEventRecord(eventData,eventScope,eventLocation,locationProvider));
                end
            end
        end
        
        
        function produceExceptionEventRecord(producer,eventData,eventScope,eventLocation,locationProvider)
            import matlab.unittest.internal.eventrecords.ExceptionEventRecord;
            
            eventRecord = ExceptionEventRecord.fromEventData(eventData,eventScope,eventLocation,...
                    'Verbosity',producer.OutputDetail);
            producer.produceEventRecordAtAffectedIndices(eventRecord,locationProvider);
        end
        
        function produceQualificationEventRecord(producer,eventData,eventScope,eventLocation,locationProvider)
            import matlab.unittest.internal.eventrecords.QualificationEventRecord;
            
            eventRecord = QualificationEventRecord.fromEventData(eventData,eventScope,eventLocation,...
                    'Verbosity',producer.OutputDetail);
            producer.produceEventRecordAtAffectedIndices(eventRecord,locationProvider);
        end
        
        function produceEventRecordAtAffectedIndices(producer,eventRecord,locationProvider)
            import matlab.unittest.internal.plugins.TestResultDetailsEventTask;    
            
            producer.Buffer.insert(TestResultDetailsEventTask(eventRecord, locationProvider, producer));    
        end
    end

    methods(Access=private)
        function produceLoggedDiagnosticEventRecord(producer,eventData,eventScope,eventLocation,locationProvider)
            import matlab.unittest.internal.eventrecords.LoggedDiagnosticEventRecord;
            
            if eventData.Verbosity <= producer.LoggingLevel
                eventRecord = LoggedDiagnosticEventRecord.fromEventData(eventData,eventScope,eventLocation,...
                    'Verbosity',producer.OutputDetail);
                producer.produceEventRecordAtAffectedIndices(eventRecord,locationProvider);
            end
        end
    end
end

function value = toUniqueRow(value)
value = unique(reshape(value,1,[]));
end

% LocalWords:  eventrecords
