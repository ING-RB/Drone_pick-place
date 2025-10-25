classdef ExceptionDiagnostic < matlab.automation.diagnostics.Diagnostic
    % This class is undocumented and may change in a future release.
    
    %  Copyright 2016-2022 The MathWorks, Inc.
    properties(SetAccess=immutable)
        Exception MException
        MessageIdentifier char
    end
    
    methods
        function diag = ExceptionDiagnostic(exception,msgID)
            diag.Exception = exception;
            diag.MessageIdentifier = msgID;
        end
        
        function diagnose(diag)
            import matlab.automation.internal.diagnostics.MessageString;
            diag.DiagnosticText = MessageString(diag.MessageIdentifier, ...
                indent(getFormattableExceptionReport(diag.Exception)));
        end
    end
end

function report = getFormattableExceptionReport(exception)
import matlab.automation.internal.diagnostics.ExceptionReportString;
import matlab.automation.internal.diagnostics.WrappableStringDecorator;
import matlab.unittest.internal.TrimmedException;
report = WrappableStringDecorator(ExceptionReportString(TrimmedException(exception)));
end
