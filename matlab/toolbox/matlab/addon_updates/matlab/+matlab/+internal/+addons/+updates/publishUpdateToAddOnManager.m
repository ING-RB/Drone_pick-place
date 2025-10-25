function publishUpdateToAddOnManager(msgToPublish)
% PUBLISHUPDATETOADDONMANAGER Publish a message to Add-On Manager

% Copyright 2022 The MathWorks, Inc.
message.publish('/mw/addons/manager/servertoclient', msgToPublish);
end
