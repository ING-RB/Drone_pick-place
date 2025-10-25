classdef(Hidden) ConciseEventReportPrinter < matlab.unittest.internal.plugins.EventReportPrinter
    % This class is undocumented and may change in a future release.

    % Copyright 2018-2023 The MathWorks, Inc.

    properties(Constant, Access=private)
        EventReportDeliminator = repmat('-',1,90);
    end

    methods(Access=?matlab.unittest.internal.plugins.EventReportPrinter)
        function printer = ConciseEventReportPrinter(varargin)
            % Must be constructed via EventReportPrinter.withVerbosity(...) static method.
            printer = printer@matlab.unittest.internal.plugins.EventReportPrinter(varargin{:});
        end
    end

    methods(Sealed)
        function printQualificationEventReport(printer,eventRecord)
            import matlab.unittest.internal.diagnostics.LabelAlignedListString;

            testDiagnosticStrings = eventRecord.FormattableTestDiagnosticResults.toFormattableStrings();
            frameworkDiagnosticStrings = eventRecord.FormattableFrameworkDiagnosticResults.toFormattableStrings();
            additionalDiagnosticStrings = eventRecord.FormattableAdditionalDiagnosticResults.toFormattableStrings();

            listStr = LabelAlignedListString();
            listStr = printer.addDiagnosticResults(listStr,'TestDiagnosticLabel', testDiagnosticStrings);
            listStr = printer.addDiagnosticResults(listStr,'FrameworkDiagnosticLabel', frameworkDiagnosticStrings);
            listStr = printer.addDiagnosticResults(listStr,'AdditionalDiagnosticLabel', additionalDiagnosticStrings);
            listStr = printer.addStackInfo(listStr,eventRecord.Stack);

            printer.printEventDescription(eventRecord);
            printer.printFormatted(appendNewlineIfNonempty(listStr.indentIfNonempty("  ")));
        end

        function printAssumptionFailedEventMiniReport(printer, eventRecord)
            import matlab.unittest.Scope;
            import matlab.unittest.internal.diagnostics.AlternativeRichString;
            import matlab.unittest.internal.diagnostics.DeferredFormattableString;

            detailsString = printer.Catalog.getString('Details');
            detailsLinkTxt = DeferredFormattableString(@()matlab.unittest.internal.plugins.EventReportPrinter.createDetailedEventReportLink(...
                detailsString, eventRecord));
            spaceAndDetailsStr = AlternativeRichString('',sprintf(' (%s)',detailsLinkTxt));
            if eventRecord.EventScope == Scope.TestMethod
                locationTxt = eventRecord.EventLocation;
            elseif eventRecord.EventScope == Scope.TestClass
                locationTxt = printer.Catalog.getString('AllTestsIn',...
                    eventRecord.EventLocation);
            elseif eventRecord.EventScope == Scope.SharedTestFixture
                locationTxt = printer.Catalog.getString('AllTestsUsing',...
                    eventRecord.EventLocation);
            end

            printer.printLine(sprintf('%s %s%s',...
                printer.Catalog.getString('SkippedLabel'),...
                locationTxt, ...
                spaceAndDetailsStr));
        end

        function printExceptionEventReport(printer, eventRecord)
            import matlab.unittest.internal.diagnostics.LabelAlignedListString;
            import matlab.unittest.internal.diagnostics.PlainString;
            
            exception = eventRecord.Exception;
            additionalDiagnosticStrings = eventRecord.FormattableAdditionalDiagnosticResults.toFormattableStrings();

            str = LabelAlignedListString();
            str = str.addLabelAndString(printer.Catalog.getString('IdentifierLabel'),"'" + exception.identifier + "'");
            msgText = PlainString(exception.message).toSingleLine;
            str = str.addLabelAndString(printer.Catalog.getString('MessageLabel'), msgText);
            str = printer.addDiagnosticResults(str,'AdditionalDiagnosticLabel',additionalDiagnosticStrings);
            str = printer.addStackInfo(str,eventRecord.Stack);

            printer.printEventDescription(eventRecord);
            printer.printLine(indent(str,"  "));
        end

        function printEventReportDeliminator(printer)
            printer.printLine(printer.EventReportDeliminator);
        end
    end

    methods(Access=private)
        function printEventDescription(printer,eventRecord)
            import matlab.unittest.internal.diagnostics.AlternativeRichString;
            import matlab.unittest.internal.diagnostics.BoldableString;
            import matlab.unittest.internal.diagnostics.DeferredFormattableString;
            import matlab.unittest.internal.diagnostics.MessageString;

            descriptionStartTxt = printer.Catalog.getString(...
                [eventRecord.EventName 'EventDescriptionStart']);
            detailedReportLinkTxt = DeferredFormattableString(@()matlab.unittest.internal.plugins.EventReportPrinter.createDetailedEventReportLink(...
                descriptionStartTxt,eventRecord));
            descriptionStartTxt = AlternativeRichString(descriptionStartTxt,detailedReportLinkTxt);
            if strlength(eventRecord.EventLocation) > 0
                descriptionTxt = BoldableString(MessageString(['MATLAB:unittest:EventReportPrinter:' ...
                    eventRecord.EventName 'In' char(eventRecord.EventScope) 'EventDescription'],...
                    descriptionStartTxt,...
                    eventRecord.EventLocation));
            else
                descriptionTxt = BoldableString(sprintf('%s.',descriptionStartTxt));
            end
            printer.printLine(descriptionTxt);
        end

        function str = addDiagnosticResults(printer, str, labelMsgKey, diagnosticStrings)
            labelTxt = printer.Catalog.getString(labelMsgKey);
            for k = 1:numel(diagnosticStrings)
                str = str.addLabelAndString(labelTxt, diagnosticStrings(k).toSingleLine);
            end
        end

        function str = addStackInfo(printer, str, stack)
            import matlab.unittest.internal.diagnostics.createStackInfo;
            if isempty(stack)
                return;
            end
            str = str.addLabelAndString(printer.Catalog.getString('StackLabel'),...
                createStackInfo(stack,'MaxHeight',3,'ExcludeInText',true));
        end
    end
end

% LocalWords:  unittest plugins Formattable Boldable strlength
