classdef ConciseEventReportPrinter < matlab.buildtool.internal.plugins.EventReportPrinter
    % This class is unsupported and might change or be removed without notice
    % in a future version.
    
    % Copyright 2021-2023 The MathWorks, Inc.
    
    properties (Constant, Hidden)
        EventReportDeliminator (1,1) string = repmat('-', 1, ...
            80 - strlength(matlab.buildtool.plugins.DiagnosticsOutputPlugin.LinePrefix))
    end
    
    methods (Access = ?matlab.buildtool.internal.plugins.EventReportPrinter)
        function printer = ConciseEventReportPrinter(varargin)
            printer = printer@matlab.buildtool.internal.plugins.EventReportPrinter(varargin{:});
        end
    end
    
    methods (Sealed)
        function printValidationEventReport(printer, eventRecord)
            arguments
                printer (1,1) matlab.buildtool.internal.plugins.ConciseEventReportPrinter
                eventRecord (1,1) matlab.buildtool.internal.eventrecords.ValidationEventRecord
            end

            import matlab.automation.internal.diagnostics.LabelAlignedListString;

            failure = eventRecord.Failure;
            location = printer.Catalog.getString(string(failure.Location.Type) + "Location", failure.Location.Name);
            message = string(failure.Message);

            report = LabelAlignedListString();
            report = report.addLabelAndString(printer.Catalog.getString("LocationLabel"), location);
            report = report.addLabelAndString(printer.Catalog.getString("MessageLabel"), message);

            printer.printEventDescription(eventRecord);
            printer.printFormatted(appendNewlineIfNonempty(report.indentIfNonempty("  ")));
        end

        function printExceptionEventReport(printer, eventRecord)
            arguments
                printer (1,1) matlab.buildtool.internal.plugins.ConciseEventReportPrinter
                eventRecord (1,1) matlab.buildtool.internal.eventrecords.ExceptionEventRecord
            end
            
            import matlab.automation.internal.diagnostics.LabelAlignedListString;
            import matlab.buildtool.internal.TrimmedException;
            
            exception = TrimmedException(eventRecord.Exception);
            report = LabelAlignedListString();
            report = report.addLabelAndString(printer.Catalog.getString("IdentifierLabel"), "'"+exception.identifier+"'");
            report = report.addLabelAndString(printer.Catalog.getString("MessageLabel"), exception.message);
            report = printer.addStackInfo(report, eventRecord.Stack);

            printer.printEventDescription(eventRecord);
            printer.printFormatted(appendNewlineIfNonempty(report.indentIfNonempty("  ")));
        end
        
        function printEventReportDeliminator(printer)
            printer.printLine(printer.EventReportDeliminator);
        end

        function printQualificationEventReport(printer, eventRecord)
            arguments
                printer (1,1) matlab.buildtool.internal.plugins.ConciseEventReportPrinter
                eventRecord (1,1) matlab.buildtool.internal.eventrecords.QualificationEventRecord
            end

            import matlab.unittest.internal.diagnostics.LabelAlignedListString;
            
            taskDiagnosticStrings = eventRecord.FormattableTaskDiagnosticResults.toFormattableStrings();
            report = LabelAlignedListString();
            report = printer.addDiagnosticResults(report, "TaskDiagnosticLabel", taskDiagnosticStrings);
            report = printer.addStackInfo(report, eventRecord.Stack);

            printer.printEventDescription(eventRecord);
            printer.printFormatted(appendNewlineIfNonempty(report.indentIfNonempty("  ")));
        end
    end

    methods (Access = private)
        function printEventDescription(printer, eventRecord)
            import matlab.buildtool.Scope;
            import matlab.automation.internal.diagnostics.BoldableString;
            import matlab.automation.internal.diagnostics.MessageString;

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

        function report = addStackInfo(printer, report, stack)
            import matlab.automation.internal.diagnostics.createStackInfo;

            if isempty(stack)
                return;
            end

            report = report.addLabelAndString(printer.Catalog.getString("StackLabel"),...
                createStackInfo(stack, ExcludeInText=true));
        end

        function str = addDiagnosticResults(printer, str, labelMsgKey, diagnosticStrings)
            labelTxt = printer.Catalog.getString(labelMsgKey);
            for k = 1:numel(diagnosticStrings)
                str = str.addLabelAndString(labelTxt, diagnosticStrings(k).toSingleLine);
            end
        end
        
    end
end

