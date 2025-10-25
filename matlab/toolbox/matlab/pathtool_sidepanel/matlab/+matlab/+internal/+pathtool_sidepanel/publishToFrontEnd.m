function [messageType] = publishToFrontEnd(messageStruct)
%

%   Copyright 2023-2025 The MathWorks, Inc.
    messageToClient = struct('type', [], 'msg', [], 'id', []);
    ChannelToPublish = '/pathtool/ServerToClient';
    if strcmp(messageStruct.type, 'error') && ~isempty(messageStruct.details.msg)
        messageType = 'addPathError';
        messageToClient = struct('type', messageType, 'msg', messageStruct.details.msg, 'id', messageStruct.details.id);
    elseif strcmp(messageStruct.type, 'warning') && ~isempty(messageStruct.details.msg)
        messageType = 'addPathWarning';
        messageToClient = struct('type', messageType, 'msg', messageStruct.details.msg, 'id', messageStruct.details.id);
    else
        messageType = 'noAction';
    end
    connector.ensureServiceOn;
    message.publish(ChannelToPublish, messageToClient);
end
