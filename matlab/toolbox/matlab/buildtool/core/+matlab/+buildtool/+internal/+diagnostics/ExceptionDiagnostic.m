classdef ExceptionDiagnostic < matlab.automation.diagnostics.Diagnostic
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % Copyright 2021-2023 The MathWorks, Inc.
    
    properties (SetAccess = immutable)
        Exception MException {mustBeScalarOrEmpty}
        MessageIdentifier (1,1) string
    end
    
    methods
        function diag = ExceptionDiagnostic(exception, msgID)
            arguments
                exception (1,1) MException
                msgID (1,1) string
            end
            diag.Exception = exception;
            diag.MessageIdentifier = msgID;
        end

        function diagnose(diag)
            import matlab.buildtool.internal.TrimmedException;
            report = getReport(TrimmedException(diag.Exception));
            diag.DiagnosticText = getString(message(diag.MessageIdentifier, report));
        end
    end
end

