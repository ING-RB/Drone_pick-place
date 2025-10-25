classdef TAPOriginalFormatPlugin < matlab.unittest.internal.plugins.tap.InternalTAPPlugin
    % TAPOriginalFormatPlugin - Plugin that produces the original TAP format
    %
    %   A TAPOriginalFormatPlugin is constructed only with the
    %   TAPPlugin.producingOriginalFormat method.
    %
    %   TAPOriginalFormatPlugin Properties:
    %       IncludePassingDiagnostics - Indicator if diagnostics are included for passing events
    %       LoggingLevel              - Maximum verbosity level at which logged diagnostics are included
    %       OutputDetail              - Verbosity level that defines amount of displayed information
    %
    %   See also:
    %       matlab.unittest.plugins.TAPPlugin
    %       matlab.unittest.plugins.TAPPlugin.producingOriginalFormat
    
    % Copyright 2013-2023 The MathWorks, Inc.
    
    methods(Hidden, Access={?matlab.unittest.plugins.TAPPlugin})
        function plugin = TAPOriginalFormatPlugin(parser)
            plugin@matlab.unittest.internal.plugins.tap.InternalTAPPlugin(parser);
        end
        
    end
    
    methods(Hidden, Access=protected)
        function printFormattedDiagnostics(plugin, eventRecords)
            import matlab.unittest.internal.plugins.StandardEventRecordFormatter;
            import matlab.unittest.internal.diagnostics.FormattableString;
            
            formatter = StandardEventRecordFormatter();
            formatter.AddDeliminatorsToExceptionEventReport = true;
            formatter.AddDeliminatorsToLoggedDiagnosticEventReport = true;
            formatter.AddDeliminatorsToQualificationEventReport = true;
            formatter.UseAssumptionFailedEventMiniReport = true;
            formatter.ReportVerbosity = plugin.OutputDetail;
            
            reports = arrayfun(@(r) r.getFormattedReport(formatter), ...
                eventRecords, 'UniformOutput', false);
            reportStrs = [FormattableString.empty, reports{:}];
            report = reportStrs.joinNonempty(newline);
            report = report.indentIfNonempty("# ");
            plugin.Printer.printFormatted(report.appendNewlineIfNonempty);
        end
    end
end

% LocalWords:  Formattable unittest plugins formatter Strs
