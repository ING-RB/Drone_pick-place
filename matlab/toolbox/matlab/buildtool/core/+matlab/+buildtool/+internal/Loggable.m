classdef (Hidden) Loggable < handle
    % This class is unsupported and might change or be removed without notice
    % in a future version.
    
    % Copyright 2021-2022 The MathWorks, Inc.

    events (NotifyAccess = private)
        % DiagnosticLogged - Event triggered by calls to the log method
        DiagnosticLogged
    end

    methods (Hidden, Sealed)
        function log(loggable, varargin)
            import matlab.automation.Verbosity;
            import matlab.buildtool.diagnostics.LoggedDiagnosticEventData;
            
            narginchk(2,3);
            
            if nargin > 2
                level = varargin{1};
                level = validateVerbosityInput(level, "Verbosity");
                validateattributes(level, "matlab.automation.Verbosity", {">",0}, "", "Verbosity");
            else
                % Default verbosity level is Concise
                level = Verbosity.Concise;
            end            
            diagnostic = varargin{end};

            timestamp = datetime("now");
            
            data = LoggedDiagnosticEventData(level, diagnostic, timestamp);
            loggable.notify("DiagnosticLogged", data);
        end
    end
end

function validVerbosity = validateVerbosityInput(verbosity, varargin)
if isstring(verbosity) || ischar(verbosity)
    validateattributes(verbosity, ["char","string"], "scalartext","",varargin{:});
else
    validateattributes(verbosity, ["numeric","matlab.automation.Verbosity"], "scalar","",varargin{:});
end

% Validate that the verbosity value is valid
validVerbosity = matlab.automation.Verbosity(verbosity); 
end

