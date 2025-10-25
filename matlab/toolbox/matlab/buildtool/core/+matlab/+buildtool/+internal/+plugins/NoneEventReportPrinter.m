classdef NoneEventReportPrinter < ...
        matlab.buildtool.internal.plugins.EventReportPrinter
    % This class is unsupported and might change or be removed without notice
    % in a future version.
    
    % Copyright 2021-2023 The MathWorks, Inc.
    
    methods (Access = ?matlab.buildtool.internal.plugins.EventReportPrinter)
        function printer = NoneEventReportPrinter(varargin)
            printer = printer@matlab.buildtool.internal.plugins.EventReportPrinter(varargin{:});
        end
    end
    
    methods (Sealed)
        function printValidationEventReport(varargin)
            % No output to print for Verbosity.None reports
        end

        function printExceptionEventReport(varargin)
            % No output to print for Verbosity.None reports
        end
        
        function printEventReportDeliminator(varargin)
            % No output to print for Verbosity.None reports
        end

        function printQualificationEventReport(varargin)
            % No output to print for Verbosity.None reports
        end
    end
end

