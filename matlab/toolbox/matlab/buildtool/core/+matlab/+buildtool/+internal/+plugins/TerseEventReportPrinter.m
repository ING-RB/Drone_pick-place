classdef TerseEventReportPrinter < ...
        matlab.buildtool.internal.plugins.EventReportPrinter
    % This class is unsupported and might change or be removed without notice
    % in a future version.
    
    % Copyright 2024 The MathWorks, Inc.
    
    methods (Access = ?matlab.buildtool.internal.plugins.EventReportPrinter)
        function printer = TerseEventReportPrinter(varargin)
            printer = printer@matlab.buildtool.internal.plugins.EventReportPrinter(varargin{:});
        end
    end
    
    methods (Sealed)
        function printValidationEventReport(printer, eventRecord)
            arguments
                printer (1,1) matlab.buildtool.internal.plugins.TerseEventReportPrinter
                eventRecord (1,1) matlab.buildtool.internal.eventrecords.ValidationEventRecord
            end

            import matlab.automation.internal.diagnostics.BoldableString;
            import matlab.automation.internal.diagnostics.PlainString;

            status = BoldableString(printer.Catalog.getString("FailUpper"));
            failure = eventRecord.Failure;
            failureLocation = printer.Catalog.getString(string(failure.Location.Type) + "Location", failure.Location.Name);
            report = sprintf("%s: %s %s", status, eventRecord.EventLocation, failureLocation);

            singleLineFirstDiag = PlainString(failure.Message).toSingleLine();
            report = joinNonempty([report, singleLineFirstDiag], " :: ");

            printer.printLine(report);
        end

        function printExceptionEventReport(printer, eventRecord)
            arguments
                printer (1,1) matlab.buildtool.internal.plugins.TerseEventReportPrinter
                eventRecord (1,1) matlab.buildtool.internal.eventrecords.ExceptionEventRecord
            end
            
            import matlab.buildtool.internal.plugins.EventReportPrinter;
            import matlab.automation.internal.diagnostics.AlternativeRichString;
            import matlab.automation.internal.diagnostics.BoldableString;
            import matlab.automation.internal.diagnostics.DeferredFormattableString;

            status = printer.Catalog.getString("ErrorUpper");
            link = DeferredFormattableString(@()EventReportPrinter.createDetailedEventReportLink(status, eventRecord));
            status = AlternativeRichString(status, link);
            status = BoldableString(status);

            report = sprintf("%s: %s", status, eventRecord.EventLocation);
            report = addStackInfoIfNeeded(report, eventRecord);
            report = sprintf("%s :: %s", report, ...
                printer.Catalog.getString("ErrorWithIdentifierOccurred", eventRecord.Exception.identifier));

            printer.printLine(report);
        end
        
        function printEventReportDeliminator(varargin)
            % Print no deliminator for Verbosity.Terse reports
        end

        function printQualificationEventReport(printer, eventRecord)
            arguments
                printer (1,1) matlab.buildtool.internal.plugins.TerseEventReportPrinter
                eventRecord (1,1) matlab.buildtool.internal.eventrecords.QualificationEventRecord
            end

            import matlab.buildtool.internal.plugins.EventReportPrinter;
            import matlab.automation.internal.diagnostics.AlternativeRichString;
            import matlab.automation.internal.diagnostics.BoldableString;
            import matlab.automation.internal.diagnostics.DeferredFormattableString;

            status = printer.Catalog.getString("FailUpper");
            link = DeferredFormattableString(@()EventReportPrinter.createDetailedEventReportLink(status, eventRecord));
            status = AlternativeRichString(status, link);

            report = BoldableString(status);
            location = eventRecord.EventLocation;
            if strlength(location) > 0
                report = sprintf("%s: %s", report, location);
            end
            report = addStackInfoIfNeeded(report, eventRecord);

            if ~isempty(eventRecord.FormattableTaskDiagnosticResults)
                diag = eventRecord.FormattableTaskDiagnosticResults.toFormattableStrings();
                singleLineFirstDiag = diag(1).toSingleLine();
                report = joinNonempty([report, singleLineFirstDiag], " :: ");
            end

            printer.printLine(report);
        end
    end
end

function report = addStackInfoIfNeeded(report, eventRecord)
import matlab.automation.internal.diagnostics.createStackInfo;
import matlab.automation.internal.diagnostics.MessageString;
if isempty(eventRecord.Stack)
    return;
end
stackInfo = createStackInfo(eventRecord.Stack, MaxHeight=1, ExcludeInText=true, ExcludeFileText=true);
report = MessageString("MATLAB:buildtool:EventReportPrinter:TerseEventDescription", report, stackInfo);
end