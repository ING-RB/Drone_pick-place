classdef (Hidden) LoggedDiagnosticEventData < event.EventData
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % This class is similar to its counterpart in the testing frameworks. For
    % more information, see the help for 
    % matlab.unittest.diagnostics.LoggedDiagnosticEventData.
    
    % Copyright 2021-2022 The MathWorks, Inc.

    properties (SetAccess = immutable)
        % Verbosity - Verbosity level of logged message
        Verbosity (1,1) matlab.automation.Verbosity

        % Timestamp - Date and time of call to LOG method
        Timestamp (1,1) datetime

        % Diagnostic - Diagnostic specified in call to LOG method
        Diagnostic (1,:) matlab.automation.diagnostics.Diagnostic
    end
    
    methods (Hidden, Access = ?matlab.buildtool.internal.Loggable)
        function data = LoggedDiagnosticEventData(verbosity, diagnostic, timestamp)
            data.Verbosity = verbosity;
            data.Diagnostic = diagnostic;
            data.Timestamp = timestamp;
        end
    end
end

