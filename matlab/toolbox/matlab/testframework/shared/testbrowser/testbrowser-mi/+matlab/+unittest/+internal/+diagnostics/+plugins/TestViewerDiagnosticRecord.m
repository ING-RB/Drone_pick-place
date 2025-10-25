classdef TestViewerDiagnosticRecord < matlab.unittest.internal.diagnostics.plugins.TestViewerRecord
    %  TestViewerDiagnosticRecord - Data Structure that stores diagnostics
    %  records for TestBrowser and Test Manager
    % The TestViewerDiagnosticRecord is a data structure created by
    % TestViewerDiagnosticsPlugin.
    % 


    % Copyright 2021-2023 The MathWorks, Inc.

    properties(Access=public)
        DiagnosticSummary;
    end

     properties(Hidden, Dependent, Access=protected)
        Passed;
        Failed;
        Incomplete;
     end

     properties(Hidden, Access=protected)
        Logged = false;
     end

     methods
        function failed = get.Failed(record)
            failed = any(strcmp(record.Event, ...
                {'VerificationFailed', 'AssertionFailed', 'FatalAssertionFailed', 'ExceptionThrown'}));
        end
        
        function incomplete = get.Incomplete(record)
            incomplete = any(strcmp(record.Event, ...
                {'AssumptionFailed', 'AssertionFailed', 'FatalAssertionFailed', 'ExceptionThrown'}));
        end
        
        function passed = get.Passed(record)
            passed = ~record.Failed && ~record.Incomplete;
        end
     end

    methods
        function record = TestViewerDiagnosticRecord(eventRecord, eventData, reportVerbosity, summaryVerbosity)
            record = record@matlab.unittest.internal.diagnostics.plugins.TestViewerRecord(eventRecord, reportVerbosity);
            prepareDiagnosticSummary(record,eventRecord, eventData, summaryVerbosity);
        end
    end

    methods(Access=private)
        
        function prepareDiagnosticSummary(record, eventRecord, eventData, summaryVerbosity)
            if(isequal(summaryVerbosity, matlab.unittest.Verbosity.Concise))
                constructSummaryUsingReport(record, eventRecord);
            else
                constructSummaryUsingFrameworkDiag(record, eventData, summaryVerbosity);
            end
        end

        function constructSummaryUsingReport(record, eventRecord)
            import matlab.unittest.internal.diagnostics.MessageString;
           
            descriptionStartTxt = MessageString(['MATLAB:unittest:EventReportPrinter:'...
                eventRecord.EventName 'EventDescriptionStart']);
            if strlength(eventRecord.EventLocation) > 0
                descriptionTxt = MessageString(['MATLAB:unittest:EventReportPrinter:' ...
                    eventRecord.EventName 'In' char(eventRecord.EventScope) 'EventDescription'],...
                    descriptionStartTxt,...
                    eventRecord.EventLocation);
            else
                descriptionTxt = sprintf('%s.',descriptionStartTxt);
            end
            record.DiagnosticSummary = descriptionTxt.Text;
        end



        function constructSummaryUsingFrameworkDiag(record, eventData, SummaryVerbosity)

            if eventData.EventName == "ExceptionThrown"
                record.DiagnosticSummary = getCatalogString("ExceptionEvent");

            else
                frameworkDiagnosticResults = eventData.FrameworkDiagnosticResultsStore.getFormattableResults('verbosity',SummaryVerbosity);

                if isempty(frameworkDiagnosticResults)
                    record.DiagnosticSummary  = getCatalogString("EmptyFrameworkDiagnostics");
                else
                    diagnosticText = splitlines(frameworkDiagnosticResults(1).FormattableDiagnosticText.Text);
                    record.DiagnosticSummary  = diagnosticText{1};
                end
            end
        end

    end
end

function str = getCatalogString(msgKey, varargin)
str = getString(message("MATLAB:testbrowser:TestDiagnostics:" + msgKey, varargin{:}));
end

