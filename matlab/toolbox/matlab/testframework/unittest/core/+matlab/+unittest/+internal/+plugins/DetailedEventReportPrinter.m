classdef(Hidden) DetailedEventReportPrinter < matlab.unittest.internal.plugins.EventReportPrinter
    % This class is undocumented and may change in a future release.
    
    % Copyright 2018-2023 The MathWorks, Inc.
    
    properties(Constant, Access=private)
        EventReportDeliminator = repmat('=',1,80);
    end
    
    methods(Access=?matlab.unittest.internal.plugins.EventReportPrinter)
        function printer = DetailedEventReportPrinter(varargin)
            % Must be constructed via EventReportPrinter.withVerbosity(...) static method.
            printer = printer@matlab.unittest.internal.plugins.EventReportPrinter(varargin{:});
        end
    end
    
    methods(Sealed)
        function printQualificationEventReport(printer,eventRecord)
            testDiagnosticStrings = eventRecord.FormattableTestDiagnosticResults.toFormattableStrings();
            frameworkDiagnosticStrings = eventRecord.FormattableFrameworkDiagnosticResults.toFormattableStrings();
            additionalDiagnosticStrings = eventRecord.FormattableAdditionalDiagnosticResults.toFormattableStrings();
            
            printer.printEventDescription(eventRecord);
            printer.printDiagnosticResults('TestDiagnosticLabel', testDiagnosticStrings);
            printer.printDiagnosticResults('FrameworkDiagnosticLabel', frameworkDiagnosticStrings);
            printer.printDiagnosticResults('AdditionalDiagnosticLabel', additionalDiagnosticStrings);
            printer.printStackInfo(eventRecord.Stack);
        end
        
        function printAssumptionFailedEventMiniReport(printer, eventRecord)
            import matlab.unittest.internal.plugins.DetailedEventReportPrinter;
            import matlab.unittest.internal.diagnostics.AlternativeRichString;
            import matlab.unittest.internal.diagnostics.DeferredFormattableString;
            import matlab.unittest.internal.diagnostics.TextIndentedString;
            
            % Create summary header message
            miniSummaryText = printer.Catalog.getString( ...
                ['AssumptionFailedIn' char(eventRecord.EventScope) 'EventMiniSummary'],...
                eventRecord.EventLocation);
            
            % Create details link
            detailsString = printer.Catalog.getString('Details');
            detailsLinkStr = DeferredFormattableString(@()matlab.unittest.internal.plugins.EventReportPrinter.createDetailedEventReportLink(...
                detailsString, eventRecord));
            detailsLinkStr = AlternativeRichString('', sprintf('%s\n',detailsLinkStr));
            
            % Print output
            printer.printLine(miniSummaryText);
            if ~isempty(eventRecord.FormattableTestDiagnosticResults)
                testDiagnosticStrings = eventRecord.FormattableTestDiagnosticResults.toFormattableStrings();
                % Only print the first test diagnostic with an inline label:
                printer.printIndentedLine(TextIndentedString(testDiagnosticStrings(1),...
                    printer.Catalog.getString('TestDiagnosticLabel') + " "));
            end
            printer.printFormatted(detailsLinkStr);
        end
        
        function printExceptionEventReport(printer, eventRecord)
            import matlab.unittest.internal.TrimmedException;
            import matlab.unittest.internal.diagnostics.PlainString;
            import matlab.unittest.internal.diagnostics.ExceptionReportString;
            import matlab.unittest.internal.diagnostics.WrappableStringDecorator;
            
            exception = eventRecord.Exception;
            exceptionIdStr = PlainString(sprintf("'%s'", exception.identifier));
            exceptionReportStr = WrappableStringDecorator(ExceptionReportString(TrimmedException(exception)));
            additionalDiagnosticStrings = eventRecord.FormattableAdditionalDiagnosticResults.toFormattableStrings();
            
            printer.printEventDescription(eventRecord);
            printer.printDashedHeaderAndText('ErrorIDLabel',exceptionIdStr);
            printer.printDashedHeaderAndText('ErrorDetailsLabel',exceptionReportStr);
            printer.printDiagnosticResults('AdditionalDiagnosticLabel', additionalDiagnosticStrings);
        end
        
        function printEventReportDeliminator(printer)
            printer.printLine(printer.EventReportDeliminator);
        end
    end
    
    methods(Access=private)
        function printEventDescription(printer,eventRecord)
            import matlab.unittest.internal.diagnostics.MessageString;
            import matlab.unittest.internal.diagnostics.BoldableString;
            descriptionStartTxt = printer.Catalog.getString(...
                [eventRecord.EventName 'EventDescriptionStart']);
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
        
        function printDiagnosticResults(printer, headerMsgKey, diagnosticStrings)
            for k = 1:numel(diagnosticStrings)
                printer.printDashedHeaderAndText(headerMsgKey,diagnosticStrings(k));
            end
        end
        
        function printStackInfo(printer, stack)
            import matlab.unittest.internal.diagnostics.createStackInfo;
            if isempty(stack)
                return;
            end
            printer.printDashedHeaderAndText('StackInformationLabel',createStackInfo(stack));
        end
        
        function printDashedHeaderAndText(printer, headerMsgKey, bodyTxt)
            import matlab.unittest.internal.diagnostics.wrapHeader;
            
            result = concatenateIfNonempty(newline, bodyTxt);
            result = concatenateIfNonempty(wrapHeader(printer.Catalog.getString(headerMsgKey)), result);
            result = indentIfNonempty(result);
            result = appendNewlineIfNonempty(result);
            printer.printFormatted(result);
        end
    end
end

% LocalWords:  unittest plugins Formattable Wrappable Boldable strlength
