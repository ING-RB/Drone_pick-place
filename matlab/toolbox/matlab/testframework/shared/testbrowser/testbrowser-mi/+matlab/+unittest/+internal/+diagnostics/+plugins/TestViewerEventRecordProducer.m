classdef TestViewerEventRecordProducer < matlab.unittest.internal.plugins.EventRecordProducer
    % This class is undocumented and subject to change in a future release

    %  Copyright 2021-2023 The MathWorks, Inc.

    properties
        
        %SummaryDetail -  Verbosity level that controls amount of
        %diagnostics captured for summary
        SummaryDetail (1,1) matlab.unittest.Verbosity
        ReportDetail (1,1) matlab.unittest.Verbosity 
    end

     methods(Access=protected)
        function produceQualificationEventRecord(producer,eventData,eventScope,eventLocation,locationProvider)
            import matlab.unittest.internal.eventrecords.QualificationEventRecord;
            import matlab.unittest.internal.diagnostics.plugins.TestViewerDiagnosticRecord;

            eventRecordForDiagnostics = QualificationEventRecord.fromEventData(...
                eventData,eventScope,eventLocation,'Verbosity', producer.OutputDetail);

            testBrowserEventRecord = TestViewerDiagnosticRecord(eventRecordForDiagnostics, eventData, producer.ReportDetail, producer.SummaryDetail);

            producer.produceEventRecordAtAffectedIndices(testBrowserEventRecord,...
                locationProvider);
        end

        function produceExceptionEventRecord(producer,eventData,eventScope,eventLocation,locationProvider)
            import matlab.unittest.internal.eventrecords.ExceptionEventRecord;
            import matlab.unittest.internal.diagnostics.plugins.TestViewerDiagnosticRecord;
            
            eventRecordForDiagnostics = ExceptionEventRecord.fromEventData(...
                eventData,eventScope,eventLocation, 'Verbosity', producer.OutputDetail);

            testBrowserEventRecord = TestViewerDiagnosticRecord(eventRecordForDiagnostics, eventData, producer.ReportDetail, producer.SummaryDetail);

            producer.produceEventRecordAtAffectedIndices(testBrowserEventRecord,locationProvider);
        end
    end
end



