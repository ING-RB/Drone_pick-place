classdef StandardEventRecordFormatter < matlab.unittest.internal.eventrecords.EventRecordFormatter
    % This class is undocumented and may change in a future release.
    
    % Copyright 2018 The MathWorks, Inc.
    properties
        AddDeliminatorsToExceptionEventReport (1,1) logical = false;
        AddDeliminatorsToLoggedDiagnosticEventReport (1,1) logical = false;
        AddDeliminatorsToQualificationEventReport (1,1) logical = false;
        UseAssumptionFailedEventMiniReport (1,1) logical = false;
        ReportVerbosity (1,1) matlab.unittest.Verbosity = ...
            matlab.unittest.Verbosity.Detailed;
    end
    
    methods
        function str = getExceptionEventReport(formatter, eventRecord)
            deminIsNeeded = formatter.AddDeliminatorsToExceptionEventReport;
            printer = formatter.createEventReportPrinter();
            printEventReportDeliminatorIfNeeded(printer,deminIsNeeded);
            printer.printExceptionEventReport(eventRecord);
            printEventReportDeliminatorIfNeeded(printer,deminIsNeeded);
            str = getLoggedString(printer);
        end
        
        function str = getLoggedDiagnosticEventReport(formatter, eventRecord)
            delimIsNeeded = formatter.AddDeliminatorsToLoggedDiagnosticEventReport;
            printer = formatter.createEventReportPrinter();
            printEventReportDeliminatorIfNeeded(printer,delimIsNeeded);
            printer.printLoggedDiagnosticEventReport(eventRecord);
            printEventReportDeliminatorIfNeeded(printer,delimIsNeeded);
            str = getLoggedString(printer);
        end
        
        function str = getQualificationEventReport(formatter, eventRecord)
            delimIsNeeded = formatter.AddDeliminatorsToQualificationEventReport;
            printer = formatter.createEventReportPrinter();
            printEventReportDeliminatorIfNeeded(printer,delimIsNeeded);
            if formatter.UseAssumptionFailedEventMiniReport && ...
                    eventRecord.EventName == "AssumptionFailed"
                printer.printAssumptionFailedEventMiniReport(eventRecord);
            else
                printer.printQualificationEventReport(eventRecord);
            end
            printEventReportDeliminatorIfNeeded(printer,delimIsNeeded);
            str = getLoggedString(printer);
        end
    end
    
    methods(Access=private)
        function printer = createEventReportPrinter(formatter)
            import matlab.unittest.internal.plugins.EventReportPrinter;
            import matlab.unittest.internal.plugins.LoggingStream;
            printer = EventReportPrinter.withVerbosity(...
                formatter.ReportVerbosity, LoggingStream);
        end
    end
end

function printEventReportDeliminatorIfNeeded(printer,delimIsNeeded)
if delimIsNeeded
    printer.printEventReportDeliminator();
end
end

function str = getLoggedString(printer)
str = printer.OutputStream.FormattableLog;
str = regexprep(str,'\n+$','');
end