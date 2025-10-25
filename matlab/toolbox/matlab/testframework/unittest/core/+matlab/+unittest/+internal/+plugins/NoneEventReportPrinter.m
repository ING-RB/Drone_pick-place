classdef(Hidden) NoneEventReportPrinter < matlab.unittest.internal.plugins.EventReportPrinter
    % This class is undocumented and may change in a future release.
    
    % Copyright 2018 The MathWorks, Inc.
    
    methods(Access=?matlab.unittest.internal.plugins.EventReportPrinter)
        function printer = NoneEventReportPrinter(varargin)
            % Must be constructed via EventReportPrinter.withVerbosity(...) static method.
            printer = printer@matlab.unittest.internal.plugins.EventReportPrinter(varargin{:});
        end
    end
    
    methods(Sealed)
        function printQualificationEventReport(varargin)
            % No output to print for Verbosity.None reports
        end
        
        function printAssumptionFailedEventMiniReport(varargin)
            % No output to print for Verbosity.None reports
        end
        
        function printExceptionEventReport(varargin)
            % No output to print for Verbosity.None reports
        end
        
        function printLoggedDiagnosticEventReport(varargin)
            % No output to print for Verbosity.None reports
        end
        
        function printEventReportDeliminator(varargin)
            % No output to print for Verbosity.None reports
        end
    end
end