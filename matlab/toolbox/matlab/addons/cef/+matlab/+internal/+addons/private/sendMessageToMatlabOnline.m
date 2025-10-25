% SENDMESSAGETOMATLABONLINE: Utility method to send a message to client

% Copyright: 2020 The MathWorks, Inc.
function sendMessageToMatlabOnline(msgType, msgBody)
    PUBLISH_CHANNEL = "/matlab/addons/serverToClient";   
    if nargin > 1
        messageToClient = struct('type', msgType, 'body', msgBody);
    else
       messageToClient = struct('type', msgType); 
    end
    message.publish(PUBLISH_CHANNEL, messageToClient);
end