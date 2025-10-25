classdef(Hidden) TerseEventReportPrinter < matlab.unittest.internal.plugins.EventReportPrinter
    % This class is undocumented and may change in a future release.

    % Copyright 2018-2023 The MathWorks, Inc.

    methods(Access=?matlab.unittest.internal.plugins.EventReportPrinter)
        function printer = TerseEventReportPrinter(varargin)
            % Must be constructed via EventReportPrinter.withVerbosity(...) static method.
            printer = printer@matlab.unittest.internal.plugins.EventReportPrinter(varargin{:});
        end
    end

    methods(Sealed)
        function printQualificationEventReport(printer,eventRecord)
            import matlab.unittest.Scope;
            import matlab.unittest.internal.diagnostics.AlternativeRichString;
            import matlab.unittest.internal.diagnostics.BoldableString;
            import matlab.unittest.internal.diagnostics.DeferredFormattableString;

            if contains(eventRecord.EventName,'Passed')
                passFailTxt = printer.Catalog.getString('PassUpper');
            else
                passFailTxt = printer.Catalog.getString('FailUpper');
            end
            detailedReportLinkTxt = DeferredFormattableString(@() ...
                matlab.unittest.internal.plugins.EventReportPrinter.createDetailedEventReportLink(...
                passFailTxt, eventRecord));
            passFailTxt = AlternativeRichString(passFailTxt,detailedReportLinkTxt);
            reportTxt = BoldableString(passFailTxt);
            locationTxt = eventRecord.EventLocation;
            if strlength(locationTxt) > 0
                if eventRecord.EventScope ~= Scope.TestMethod
                    locationTxt = printer.Catalog.getString('SettingUpOrTearingDown',...
                        locationTxt);
                end
                reportTxt = sprintf('%s: %s',reportTxt,locationTxt);
            end

            reportTxt = addStackInfoIfNeeded(reportTxt,eventRecord);

            if ~isempty(eventRecord.FormattableFrameworkDiagnosticResults)
                diagStrings = eventRecord.FormattableFrameworkDiagnosticResults.toFormattableStrings();
                singleLineFirstDiag = diagStrings(1).toSingleLine;
                reportTxt = joinNonempty([reportTxt, singleLineFirstDiag], " :: ");
            end

            printer.printLine(reportTxt);
        end

        function printAssumptionFailedEventMiniReport(printer, eventRecord)
            import matlab.unittest.Scope;
            import matlab.unittest.internal.diagnostics.AlternativeRichString;
            import matlab.unittest.internal.diagnostics.DeferredFormattableString;

            skipTxt = printer.Catalog.getString('SkipUpper');
            if eventRecord.EventScope == Scope.TestMethod
                locationTxt = eventRecord.EventLocation;
            elseif eventRecord.EventScope == Scope.TestClass
                locationTxt = printer.Catalog.getString('AllTestsIn',...
                    eventRecord.EventLocation);
            elseif eventRecord.EventScope == Scope.SharedTestFixture
                locationTxt = printer.Catalog.getString('AllTestsUsing',...
                    eventRecord.EventLocation);
            end
            reportTxt = sprintf('%s: %s',skipTxt,locationTxt);

            detailedString = printer.Catalog.getString('Details');
            detailedReportLinkTxt = DeferredFormattableString(@()...
                matlab.unittest.internal.plugins.EventReportPrinter.createDetailedEventReportLink(...
                detailedString,eventRecord));
            reportTxt = AlternativeRichString(reportTxt, ...
                sprintf('%s (%s)',reportTxt,detailedReportLinkTxt));

            printer.printLine(reportTxt);
        end

        function printExceptionEventReport(printer, eventRecord)
            import matlab.unittest.Scope;
            import matlab.unittest.internal.diagnostics.AlternativeRichString;
            import matlab.unittest.internal.diagnostics.BoldableString;
            import matlab.unittest.internal.diagnostics.DeferredFormattableString;

            failTxt = printer.Catalog.getString('FailUpper');
            detailedReportLinkTxt = DeferredFormattableString(@()...
                matlab.unittest.internal.plugins.EventReportPrinter.createDetailedEventReportLink(...
                   failTxt,eventRecord));
            failTxt = AlternativeRichString(failTxt,detailedReportLinkTxt);
            failTxt = BoldableString(failTxt);
            if eventRecord.EventScope == Scope.TestMethod
                locationTxt = eventRecord.EventLocation;
            else
                locationTxt = printer.Catalog.getString('SettingUpOrTearingDown',...
                    eventRecord.EventLocation);
            end
            reportTxt = sprintf('%s: %s',failTxt,locationTxt);

            reportTxt = addStackInfoIfNeeded(reportTxt,eventRecord);

            reportTxt = sprintf('%s :: %s', reportTxt,...
                printer.Catalog.getString('ErrorWithIdentifierOccurred',...
                eventRecord.Exception.identifier));

            printer.printLine(reportTxt);
        end

        function printEventReportDeliminator(~)
            % Print no deliminator for Terse reports
        end
    end
end

function reportTxt = addStackInfoIfNeeded(reportTxt,eventRecord)
import matlab.unittest.internal.diagnostics.createStackInfo;
import matlab.unittest.internal.diagnostics.MessageString;
if isempty(eventRecord.Stack)
    return;
end
stackInfoTxt = createStackInfo(eventRecord.Stack,'MaxHeight',1,'ExcludeInText',true,'ExcludeFileText',true);
reportTxt = MessageString('MATLAB:unittest:EventReportPrinter:TerseEventDescription',...
    reportTxt, stackInfoTxt);
end

% LocalWords:  unittest plugins Boldable strlength Formattable
