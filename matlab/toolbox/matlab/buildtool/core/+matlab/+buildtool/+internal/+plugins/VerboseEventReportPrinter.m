classdef VerboseEventReportPrinter < ...
        matlab.buildtool.internal.plugins.EventReportPrinter
    % This class is unsupported and might change or be removed without notice
    % in a future version.
    
    % Copyright 2024 The MathWorks, Inc.

    properties (GetAccess = private, SetAccess = immutable)
        DetailedEventReportPrinter (1,1) matlab.buildtool.internal.plugins.DetailedEventReportPrinter
    end
    
    methods (Access = ?matlab.buildtool.internal.plugins.EventReportPrinter)
        function printer = VerboseEventReportPrinter(varargin)
            import matlab.buildtool.internal.plugins.DetailedEventReportPrinter;
            printer = printer@matlab.buildtool.internal.plugins.EventReportPrinter(varargin{:});
            printer.DetailedEventReportPrinter = DetailedEventReportPrinter(varargin{:});
        end
    end
    
    methods (Sealed)
        function printValidationEventReport(printer, eventRecord)
            printer.DetailedEventReportPrinter.printValidationEventReport(eventRecord);
        end

        function printExceptionEventReport(printer, eventRecord)
            printer.DetailedEventReportPrinter.printExceptionEventReport(eventRecord);
        end
        
        function printEventReportDeliminator(printer)
            printer.DetailedEventReportPrinter.printEventReportDeliminator();
        end

        function printQualificationEventReport(printer, eventRecord)
            printer.DetailedEventReportPrinter.printQualificationEventReport(eventRecord);
        end
    end
end

