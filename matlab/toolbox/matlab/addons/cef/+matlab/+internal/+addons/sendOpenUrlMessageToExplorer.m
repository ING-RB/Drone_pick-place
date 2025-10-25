function sendOpenUrlMessageToExplorer(communicationMessageFromJava)
% sendOpenUrlMessageToExplorer: Utility method to send openUrl message to
% Add-on Explorer. 

% (To be deleted as part of Jira Epic FILESYSUI-3562)

% Copyright: 2019-2021 The MathWorks, Inc.
        
    mlock;
    persistent subscriptionId;

        openUrlMessageBody = matlab.internal.addons.launchers.util.getOpenUrlMessage(string(communicationMessageFromJava.getUrl), string(communicationMessageFromJava.getContext), string(communicationMessageFromJava.getPostMessageTag));
        
        if matlab.internal.addons.Configuration.isClientRemote
            if (isempty(subscriptionId))
                % ToDo: Create a communicator to send and receive messages to/from
                % client
                subscriptionId = message.subscribe("/matlab/addons/clientToServer", @(msg) clientMessageHandler(msg));
            end
             messageToClient = struct('type', 'resolveUrlInOpenUrlMessageAndShowInExplorer', 'body', openUrlMessageBody);
             % Create a communicator which can be used to send/receive
            % messages to/from client
            message.publish("/matlab/addons/serverToClient", messageToClient);
        else
            matlab.internal.addons.launchers.sendMessageToExplorer('openUrl', openUrlMessageBody);
        end
        
        
        function clientMessageHandler(msg)
        if strcmp(msg.type,'showResolvedUrlInExplorer') == 1
            matlab.internal.addons.launchers.sendMessageToExplorer('openUrl', msg.body);
        end
    end
end