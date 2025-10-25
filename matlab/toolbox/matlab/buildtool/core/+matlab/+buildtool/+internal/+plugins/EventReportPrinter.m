classdef EventReportPrinter < matlab.buildtool.internal.plugins.LinePrinter
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % Copyright 2021-2024 The MathWorks, Inc.

    properties (Constant, Hidden, Access = protected)
        Catalog (1,1) matlab.internal.Catalog = matlab.internal.Catalog("MATLAB:buildtool:EventReportPrinter")
    end

    methods (Abstract)
        printValidationEventReport(printer, eventRecord)
        printExceptionEventReport(printer, eventRecord)
        printEventReportDeliminator(printer)
        printQualificationEventReport(printer, eventRecord)
    end

    methods (Static)
        function printer = withVerbosity(verbosity, arg)
            arguments
                verbosity (1,1) matlab.automation.Verbosity
            end
            arguments (Repeating)
                arg
            end

            import matlab.automation.Verbosity;
            import matlab.buildtool.internal.plugins.NoneEventReportPrinter;
            import matlab.buildtool.internal.plugins.TerseEventReportPrinter;
            import matlab.buildtool.internal.plugins.ConciseEventReportPrinter;
            import matlab.buildtool.internal.plugins.DetailedEventReportPrinter;
            import matlab.buildtool.internal.plugins.VerboseEventReportPrinter;

            if verbosity == Verbosity.None
                printer = NoneEventReportPrinter(arg{:});
            elseif verbosity == Verbosity.Terse
                printer = TerseEventReportPrinter(arg{:});
            elseif verbosity == Verbosity.Concise
                printer = ConciseEventReportPrinter(arg{:});
            elseif verbosity == Verbosity.Detailed
                printer = DetailedEventReportPrinter(arg{:});
            elseif verbosity == Verbosity.Verbose
                printer = VerboseEventReportPrinter(arg{:});
            end
        end
    end

    methods
        function printLoggedDiagnosticEventReport(printer, eventRecord)
            arguments
                printer (1,1) matlab.buildtool.internal.plugins.EventReportPrinter
                eventRecord (1,1) matlab.buildtool.internal.eventrecords.LoggedDiagnosticEventRecord
            end

            diagnostics = string({eventRecord.DiagnosticResult.DiagnosticText});
            for d = diagnostics
                printer.printLine(d);
            end
        end
    end

    methods (Access = protected)
        function printer = EventReportPrinter(varargin)
            printer = printer@matlab.buildtool.internal.plugins.LinePrinter(varargin{:});
        end
    end

    methods (Static, Hidden)
        function link = createDetailedEventReportLink(linkLabel, eventRecord)
            arguments
                linkLabel (1,1) string
                eventRecord (1,1) matlab.buildtool.internal.eventrecords.EventRecord
            end
            
            import matlab.buildtool.internal.plugins.EventReportPrinter;
            import matlab.automation.internal.streams.LoggingStream;
            import matlab.automation.internal.createWebWindowHyperlink;
            
            if eventRecord.EventName == "ExceptionThrown"
                printFcn = @printExceptionEventReport;
            else
                printFcn = @printQualificationEventReport;
            end
            detailedPrinter = EventReportPrinter.withVerbosity(3, LoggingStream);
            printFcn(detailedPrinter, eventRecord);

            richDetailedLog = enrich(detailedPrinter.OutputStream.FormattableLog);
            windowTitle = eventRecord.EventName;
            if strlength(eventRecord.EventLocation) > 0
                windowTitle = sprintf("%s: %s", windowTitle, eventRecord.EventLocation);
            end
            link = createWebWindowHyperlink(richDetailedLog.Text, windowTitle, linkLabel);
        end
    end
end

