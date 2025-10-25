function messageToClient = constructClientMessage(msgType,msgBody)
% CONSTRUCTCLIENTMESSAGE Returns a struct with the given
%                        messageType and messageBody to be communicated to
%                        Add-Ons client
% Example: {'type': 'navigateTo, 'body': 'msgBody'}

% Copyright 2021 The MathWorks, Inc.

messageToClient = struct('type', msgType, 'body', msgBody);
end

