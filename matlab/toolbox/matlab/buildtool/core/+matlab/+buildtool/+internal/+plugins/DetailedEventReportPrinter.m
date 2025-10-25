classdef DetailedEventReportPrinter < matlab.buildtool.internal.plugins.EventReportPrinter
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % Copyright 2023 The MathWorks, Inc.

    properties (Constant, Hidden)
        EventReportDeliminator (1,1) string = repmat('=', 1, ...
            80 - strlength(matlab.buildtool.plugins.DiagnosticsOutputPlugin.LinePrefix))
    end

    methods (Access = ?matlab.buildtool.internal.plugins.EventReportPrinter)
        function printer = DetailedEventReportPrinter(varargin)
            printer = printer@matlab.buildtool.internal.plugins.EventReportPrinter(varargin{:});
        end
    end

    methods (Sealed)
        function printValidationEventReport(printer, eventRecord)
            arguments
                printer (1,1) matlab.buildtool.internal.plugins.DetailedEventReportPrinter
                eventRecord (1,1) matlab.buildtool.internal.eventrecords.ValidationEventRecord
            end

            import matlab.automation.internal.diagnostics.PlainString;

            failure = eventRecord.Failure;
            location = printer.Catalog.getString(string(failure.Location.Type) + "Location", failure.Location.Name);
            message = string(failure.Message);

            printer.printEventDescription(eventRecord);
            printer.printDashedHeaderAndText("LocationLabel", PlainString(location));
            printer.printDashedHeaderAndText("MessageLabel", PlainString(message));
        end

        function printExceptionEventReport(printer, eventRecord)
            arguments
                printer (1,1) matlab.buildtool.internal.plugins.DetailedEventReportPrinter
                eventRecord (1,1) matlab.buildtool.internal.eventrecords.ExceptionEventRecord
            end

            import matlab.buildtool.internal.TrimmedException;
            import matlab.automation.internal.diagnostics.PlainString;
            import matlab.automation.internal.diagnostics.ExceptionReportString;
            import matlab.automation.internal.diagnostics.WrappableStringDecorator;

            exception = eventRecord.Exception;
            exceptionId = PlainString(sprintf("'%s'", exception.identifier));
            exceptionReport = WrappableStringDecorator(ExceptionReportString(TrimmedException(exception)));

            printer.printEventDescription(eventRecord);
            printer.printDashedHeaderAndText("ErrorIDLabel", exceptionId);
            printer.printDashedHeaderAndText("ErrorDetailsLabel", exceptionReport);
        end

        function printQualificationEventReport(printer, eventRecord)
            arguments
                printer (1,1) matlab.buildtool.internal.plugins.DetailedEventReportPrinter
                eventRecord (1,1) matlab.buildtool.internal.eventrecords.QualificationEventRecord
            end

            import matlab.automation.internal.diagnostics.PlainString;

            taskDiagnosticResults = eventRecord.FormattableTaskDiagnosticResults.toFormattableStrings();
            printer.printEventDescription(eventRecord);
            printer.printDiagnosticResults("TaskDiagnosticLabel", taskDiagnosticResults);
            printer.printStackInfo(eventRecord.Stack);
        end

        function printEventReportDeliminator(printer)
            printer.printLine(printer.EventReportDeliminator);
        end
    end

    methods (Access = private)
        function printEventDescription(printer, eventRecord)
            import matlab.buildtool.Scope;
            import matlab.automation.internal.diagnostics.MessageString;
            import matlab.automation.internal.diagnostics.BoldableString;

            descriptionStart = printer.Catalog.getString(eventRecord.EventName + "EventDescriptionStart");

            id = "MATLAB:buildtool:EventReportPrinter:"+eventRecord.EventName+"In"+string(eventRecord.EventScope)+"EventDescription";
            if eventRecord.EventScope == Scope.Fixture
                message = MessageString(id, descriptionStart);
            else
                message = MessageString(id, descriptionStart, eventRecord.EventLocation);
            end
            description = BoldableString(message);

            printer.printLine(description);
        end

        function printDashedHeaderAndText(printer, headerMsg, body)
            import matlab.automation.internal.diagnostics.wrapHeader;

            result = concatenateIfNonempty(newline(), body);
            result = concatenateIfNonempty(wrapHeader(printer.Catalog.getString(headerMsg)), result);
            result = indentIfNonempty(result);
            result = appendNewlineIfNonempty(result);
            printer.printFormatted(result);
        end

        function printDiagnosticResults(printer, headerMsgKey, diagnosticStrings)
            for k = 1:numel(diagnosticStrings)
                printer.printDashedHeaderAndText(headerMsgKey, diagnosticStrings(k));
            end
        end
        
        function printStackInfo(printer, stack)
            import matlab.automation.internal.diagnostics.createStackInfo;
            if isempty(stack)
                return;
            end
            printer.printDashedHeaderAndText("StackLabel",createStackInfo(stack));
        end

    end
end