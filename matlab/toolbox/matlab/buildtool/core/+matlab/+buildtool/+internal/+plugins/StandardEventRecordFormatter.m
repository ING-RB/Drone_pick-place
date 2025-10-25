classdef StandardEventRecordFormatter < matlab.buildtool.internal.eventrecords.EventRecordFormatter
    % This class is unsupported and might change or be removed without notice
    % in a future version.
    
    % Copyright 2021-2024 The MathWorks, Inc.
    
    properties
        ReportVerbosity (1,1) matlab.automation.Verbosity = matlab.automation.Verbosity.Concise
    end
    
    methods
        function str = getValidationEventReport(formatter, eventRecord)
            arguments
                formatter (1,1) matlab.buildtool.internal.plugins.StandardEventRecordFormatter
                eventRecord (1,1) matlab.buildtool.internal.eventrecords.ValidationEventRecord
            end
            printer = formatter.createEventReportPrinter();
            printer.printEventReportDeliminator();
            printer.printValidationEventReport(eventRecord);
            printer.printEventReportDeliminator();
            str = getLoggedString(printer);
        end

        function str = getExceptionEventReport(formatter, eventRecord)
            arguments
                formatter (1,1) matlab.buildtool.internal.plugins.StandardEventRecordFormatter
                eventRecord (1,1) matlab.buildtool.internal.eventrecords.ExceptionEventRecord
            end
            printer = formatter.createEventReportPrinter();
            printer.printEventReportDeliminator();
            printer.printExceptionEventReport(eventRecord);
            printer.printEventReportDeliminator();
            str = getLoggedString(printer);
        end

        function str = getLoggedDiagnosticEventReport(formatter, eventRecord)
            arguments
                formatter (1,1) matlab.buildtool.internal.plugins.StandardEventRecordFormatter
                eventRecord (1,1) matlab.buildtool.internal.eventrecords.LoggedDiagnosticEventRecord
            end
            printer = formatter.createEventReportPrinter();
            printer.printLoggedDiagnosticEventReport(eventRecord);
            str = getLoggedString(printer);
        end

        function str = getQualificationEventReport(formatter, eventRecord)
            arguments
                formatter (1,1) matlab.buildtool.internal.plugins.StandardEventRecordFormatter
                eventRecord (1,1) matlab.buildtool.internal.eventrecords.QualificationEventRecord
            end

            printer = formatter.createEventReportPrinter();
            printer.printEventReportDeliminator();
            printer.printQualificationEventReport(eventRecord);
            printer.printEventReportDeliminator();
            str = getLoggedString(printer);
        end
    end
    
    methods (Access = private)
        function printer = createEventReportPrinter(formatter)
            import matlab.buildtool.internal.plugins.EventReportPrinter;
            import matlab.automation.internal.streams.LoggingStream;
            
            printer = EventReportPrinter.withVerbosity( ...
                formatter.ReportVerbosity, LoggingStream());
        end
    end
end

function str = getLoggedString(printer)
str = printer.OutputStream.FormattableLog;
str = regexprep(str, "\n+$", "");
end
