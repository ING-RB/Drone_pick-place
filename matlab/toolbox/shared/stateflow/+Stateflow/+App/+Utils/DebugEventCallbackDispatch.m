function DebugEventCallbackDispatch(fileName, lineNumber)
% This wrapper function redirects debugEventCallback from cpp to the
% corresponding release

%   Copyright 2019 The MathWorks, Inc.

    Stateflow.internal.getRuntime().DebugEventCallback(fileName, lineNumber);
end
