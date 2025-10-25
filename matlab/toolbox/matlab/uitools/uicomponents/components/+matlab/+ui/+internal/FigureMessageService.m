classdef FigureMessageService
% FIGUREMESSAGESERVICE Exclusively used for establishing communication with the desktop figure client.

% Copyright 2024 The MathWorks, Inc.
methods (Static)
    function subscribeToChannel()
        connector.ensureServiceOn;
        persistent msg;
        if isempty(msg)
            msg = message.internal.MessageService("FigureMessageService");
        end
        persistent sub;
        if isempty(sub)
            sub = msg.subscribe('/gbtweb/divfigure/clientSubscribed', @(m)clientIsReady(m));
        end
        msg.publish('/gbtweb/divfigure/serverRequestsInitStatus', {});
        function clientIsReady(~)
            matlab.ui.internal.setDesktopFigureReadyForLaunch(true);
            if ~isempty(sub)
                msg.unsubscribe(sub);
                sub = [];
            end
            delete(msg);
            msg = [];
        end
    end
end
end