% Returns a PeerUtils instance

% Copyright 2014-2024 The MathWorks, Inc.

function obj = getInstance()
    mlock; % Keep persistent variables until MATLAB exits
    persistent utilsInstance;
    persistent logSubscribe; %#ok<PUSE>
    if isempty(utilsInstance) || ~isvalid(utilsInstance)
        utilsInstance = internal.matlab.variableeditor.peer.PeerUtils();
        logSubscribe = message.subscribe('/VELogChannel', @(es) internal.matlab.variableeditor.peer.PeerUtils.receivedLogMessage(es), 'enableDebugger', ~internal.matlab.datatoolsservices.WorkspaceListener.getIgnoreBreakpoints);
    end

    obj = utilsInstance;
end
