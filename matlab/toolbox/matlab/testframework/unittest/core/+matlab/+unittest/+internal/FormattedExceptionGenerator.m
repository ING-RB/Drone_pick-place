classdef FormattedExceptionGenerator
% FormattedExceptionGenerator - A formatted exception generator for different event records. 

%   Copyright 2024 The MathWorks, Inc.
    
    properties
        EmptyString
        Newline
    end

    methods
        function exception = useExceptionEventRecord(generator, eventRecord, currentIndex)
            arguments
                generator
                eventRecord
                currentIndex = -1;
            end
            import matlab.unittest.internal.TrimmedException
            import matlab.automation.internal.diagnostics.ExceptionReportString
            
            eventDiagnostics = ExceptionReportString(TrimmedException(eventRecord.Exception));

            exception = generator.getFormattedException(eventRecord, eventDiagnostics, currentIndex);
        end

        function exception = useQualificationEventRecord(generator,eventRecord, currentIndex)
            arguments
                generator
                eventRecord
                currentIndex = -1;
            end
            eventDiagnostics = generator.getAllFormattableDiagnosticResults(eventRecord);

            exception = generator.getFormattedException(eventRecord, eventDiagnostics, currentIndex);
        end
    end

    methods
        function str = get.EmptyString(~)
            str = matlab.automation.internal.diagnostics.PlainString("");
        end

        function str = get.Newline(~)
            str = matlab.automation.internal.diagnostics.PlainString(newline);
        end
    end

    methods(Access=private)
        function str = getIndexAsString(~, currentIndex)
            if(currentIndex == -1)
                str = "";
            else
                str = sprintf("%d) ", currentIndex);
            end
        end

        function str = getEventLocation(generator, eventStack)
            if isempty(eventStack)
                str = generator.EmptyString;
            else
                str = matlab.automation.internal.diagnostics.createStackInfo(eventStack(1));
            end
        end

        function diagnostics = getAllFormattableDiagnosticResults(generator, eventRecord)
            userDiagnostics = generator.getDiagnosticResults("UserSpecifiedDiagnostic", ...
                                                             eventRecord.FormattableTestDiagnosticResults);

            frameWorkDiagnostics = generator.getDiagnosticResults("FrameworkDiagnostic", ...
                                                                  eventRecord.FormattableFrameworkDiagnosticResults);

            additionalDiagnostic = generator.getDiagnosticResults("AdditionalDiagnostic", ...
                                                                  eventRecord.FormattableAdditionalDiagnosticResults); 
            
            diagnostics = userDiagnostics + frameWorkDiagnostics + additionalDiagnostic; 
        end

        function diagnoticString = getDiagnosticResults(generator, identifier, diagnosticResults)
            diagnoticString = generator.EmptyString;
            for result = diagnosticResults
                diagnoticString = diagnoticString + result.FormattableDiagnosticText + generator.Newline;
            end

            if ~isempty(diagnoticString.char)
                identifier = sprintf("MATLAB:unittest:Fixture:%s",identifier);
                header = message(identifier).string;
                header = matlab.automation.internal.diagnostics.PlainString(header) + generator.Newline;
                
                diagnoticString = diagnoticString.indentIfNonempty;
                diagnoticString = diagnoticString + generator.Newline;
                diagnoticString = header + diagnoticString;
            end
            
        end

        function formattedException = getFormattedException(generator, eventRecord, eventDiagnostics, currentIndex)
            eventIdentifier = sprintf("MATLAB:unittest:Fixture:%s", eventRecord.EventName);

            eventLocation = generator.getEventLocation(eventRecord.Stack);

            currentIndex = generator.getIndexAsString(currentIndex);
            messageHeader = currentIndex + message(eventIdentifier).string;
            messageHeader = matlab.automation.internal.diagnostics.BoldableString(messageHeader);
            
            messageHeader = messageHeader + generator.Newline;
            eventLocation = eventLocation.indentIfNonempty;
            eventLocation = eventLocation + generator.Newline;
            eventDiagnostics = eventDiagnostics.indentIfNonempty;
            eventDiagnostics = eventDiagnostics + generator.Newline;

            eventMessage = messageHeader + eventLocation + eventDiagnostics;

            formattedException = MException(eventIdentifier, '%s', eventMessage.string);
        end
    end
end
