function sendMessageToExplorer(messageType, messageBody)
%   sendMessageToExplorer: Sends a message to Add-on Explorer, in case if
%   it is already open. Today this is used to open an installer in Add-on
%   Explorer when user clicks on Add/install button
%   Example:  matlab.internal.addons.launchers.sendMessageToExplorer("openUrl", openUrlMessage)
%      opens a URL that is part of openUrlMessage in Add-on Explorer in
%      case if it is already open. OpenUrlMessage can be constructed using
%      matlab.internal.addons.launchers.util.getOpenUrlMessage
%
% See also: matlab.internal.addons.launchers.showExplorer

% Copyright: 2019 The MathWorks, Inc.

    messageToExplorer = struct('type', messageType, 'body', messageBody);
    matlab.internal.addons.Explorer.getInstance.sendMessage(jsonencode(messageToExplorer));
end