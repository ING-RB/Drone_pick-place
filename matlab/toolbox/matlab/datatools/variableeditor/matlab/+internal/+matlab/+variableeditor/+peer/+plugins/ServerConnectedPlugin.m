classdef ServerConnectedPlugin < internal.matlab.variableeditor.peer.plugins.PluginBase
    % Base Plugin that communicates with server.
    % To be implemented by other plugins that require Server Communication.

    % Copyright 2019-2024 The MathWorks, Inc.

    methods(Abstract=true)
        handled = handleEventFromClient(this, ed);
    end
end
