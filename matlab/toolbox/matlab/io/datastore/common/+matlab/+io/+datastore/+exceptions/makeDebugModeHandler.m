function errorHandler = makeDebugModeHandler
%makeDebugModeHandler Returns an exception handler function that can be
%   executed using an MException object input argument with no outputs:
%
%     errorHandler(e);
%
%   If the "MW_DATASTORE_DEBUG" environment variable is set to "on", then 
%   a rethrowing exception handler is returned, which displays the full
%   stack trace. This can be helpful while debugging datastore issues.
%
%   If the "MW_DATASTORE_DEBUG" environment variable is not set to "on", 
%   then the exception handler does a throw. This swallows the stack and 
%   reduces noise in the generated error message.

% Copyright 2019 The Mathworks, Inc.

% Get the value of the debug environment variable.
debugModeEnvironmentVariable = "MW_DATASTORE_DEBUG";
debugModeEnabled = getenv(debugModeEnvironmentVariable) == "on";

if debugModeEnabled
    % Return an error function that displays the full stack.
    errorHandler = @(e) rethrow(e);
else
    % Return an error function that truncates stack.
    errorHandler = @(e) throwAsCaller(e);
end
end