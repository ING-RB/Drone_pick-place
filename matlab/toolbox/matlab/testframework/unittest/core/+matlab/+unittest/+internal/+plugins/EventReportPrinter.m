classdef(Hidden) EventReportPrinter < matlab.unittest.internal.plugins.LinePrinter
    % This class is undocumented and may change in a future release.
    
    % Copyright 2018-2024 The MathWorks, Inc.
    
    properties(Constant, Hidden, Access=protected)
        Catalog = matlab.internal.Catalog('MATLAB:unittest:EventReportPrinter');
    end
    
    methods(Abstract)
        printQualificationEventReport(printer,eventRecord)
        
        printAssumptionFailedEventMiniReport(printer, eventRecord)
        
        printExceptionEventReport(printer, eventRecord)
        
        printEventReportDeliminator(printer)
    end
    
    methods(Static)
        function printer = withVerbosity(verbosity,varargin)
            import matlab.unittest.Verbosity;
            import matlab.unittest.internal.plugins.NoneEventReportPrinter;
            import matlab.unittest.internal.plugins.TerseEventReportPrinter;
            import matlab.unittest.internal.plugins.ConciseEventReportPrinter;
            import matlab.unittest.internal.plugins.DetailedEventReportPrinter;
            import matlab.unittest.internal.plugins.VerboseEventReportPrinter;
            if verbosity == Verbosity.None
                printer = NoneEventReportPrinter(varargin{:});
            elseif verbosity == Verbosity.Terse
                printer = TerseEventReportPrinter(varargin{:});
            elseif verbosity == Verbosity.Concise
                printer = ConciseEventReportPrinter(varargin{:});
            elseif verbosity == Verbosity.Detailed
                printer = DetailedEventReportPrinter(varargin{:});
            elseif verbosity == Verbosity.Verbose
                printer = VerboseEventReportPrinter(varargin{:});
            end
        end
    end
    
    methods
        function printLoggedDiagnosticEventReport(printer,eventRecord)
            diagnosticStrings = eventRecord.FormattableDiagnosticResults.toFormattableStrings();
            numDiags = numel(diagnosticStrings);
            
            reportTxt = sprintf('[%s] %s (%s)', ...
                char(eventRecord.Verbosity), ...
                printer.Catalog.getString('DiagnosticLogged'), ...
                datestr(eventRecord.Timestamp, 'yyyy-mm-dd HH:MM:SS'));
            
            if numDiags == 0
                printer.printLine(reportTxt);
            elseif numDiags == 1 && ~contains(char(diagnosticStrings), newline) %keep as single line
                printer.printLine(sprintf('%s: %s',reportTxt,diagnosticStrings));
            else
                printer.printLine(sprintf('%s:',reportTxt));
                for k = 1:numDiags
                    printer.printLine(diagnosticStrings(k));
                end
                printer.printEmptyLine();
            end
        end
    end
    
    methods(Access=protected)
        function printer = EventReportPrinter(varargin)
            printer = printer@matlab.unittest.internal.plugins.LinePrinter(varargin{:});
        end
    end
    
    methods(Static, Access=protected)
        function linkStr = createDetailedEventReportLink(linkLabel,eventRecord)
            import matlab.unittest.internal.plugins.EventReportPrinter;
            import matlab.unittest.internal.plugins.LoggingStream;
            import matlab.automation.internal.createWebWindowHyperlink;
            
            if eventRecord.EventName == "ExceptionThrown"
                printFcn = @printExceptionEventReport;
            else
                printFcn = @printQualificationEventReport;
            end
            detailedPrinter = EventReportPrinter.withVerbosity(3,LoggingStream);
            printFcn(detailedPrinter,eventRecord);
            richDetailedLog = enrich(detailedPrinter.OutputStream.FormattableLog);
            windowTitle = eventRecord.EventName;
            if strlength(eventRecord.EventLocation) > 0
                windowTitle = sprintf('%s: %s',windowTitle,eventRecord.EventLocation);
            end
            linkStr = createWebWindowHyperlink(richDetailedLog.Text,windowTitle,linkLabel);
        end
    end
end
