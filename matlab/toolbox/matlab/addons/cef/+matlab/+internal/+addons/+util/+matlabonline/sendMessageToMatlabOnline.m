function sendMessageToMatlabOnline(messageType, messageBody)
%   sendMessageToMatlabOnline: Sends a message to Add-Ons Service on the
%   client

% Copyright: 2021 The MathWorks, Inc.

    SERVER_TO_CLIENT_CHANNEEL = "/matlab/addons/serverToClient";

    messageToMatlabOnline = struct('type', messageType, 'body', messageBody);
    message.publish(SERVER_TO_CLIENT_CHANNEEL, jsonencode(messageToMatlabOnline));
end