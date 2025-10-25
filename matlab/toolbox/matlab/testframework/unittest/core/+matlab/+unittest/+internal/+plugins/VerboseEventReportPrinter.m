classdef(Hidden) VerboseEventReportPrinter < matlab.unittest.internal.plugins.EventReportPrinter
    % This class is undocumented and may change in a future release.
    
    % Copyright 2018 The MathWorks, Inc.
    
    properties(GetAccess=private,SetAccess=immutable)
        DetailedEventReportPrinter;
    end
    
    methods(Access=?matlab.unittest.internal.plugins.EventReportPrinter)
        function printer = VerboseEventReportPrinter(varargin)
            % Must be constructed via EventReportPrinter.withVerbosity(...) static method.
            import matlab.unittest.internal.plugins.DetailedEventReportPrinter;
            printer = printer@matlab.unittest.internal.plugins.EventReportPrinter(varargin{:});
            printer.DetailedEventReportPrinter = DetailedEventReportPrinter(varargin{:});
        end
    end
    
    methods(Sealed)
        function printQualificationEventReport(printer,eventRecord)
            printer.DetailedEventReportPrinter.printQualificationEventReport(eventRecord);
        end
        
        function printAssumptionFailedEventMiniReport(printer, eventRecord)
            printer.DetailedEventReportPrinter.printAssumptionFailedEventMiniReport(eventRecord);
        end
        
        function printExceptionEventReport(printer, eventRecord)
            printer.DetailedEventReportPrinter.printExceptionEventReport(eventRecord);
        end
        
        function printEventReportDeliminator(printer)
            printer.DetailedEventReportPrinter.printEventReportDeliminator();
        end
    end
end