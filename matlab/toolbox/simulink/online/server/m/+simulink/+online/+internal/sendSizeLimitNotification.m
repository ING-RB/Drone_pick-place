function sent = sendSizeLimitNotification(width, height)
sent = false;
studios = DAS.Studio.getAllStudiosSortedByMostRecentlyActive;
if ~~isempty(studios)
    return;
end
studio = studios(1);
editor = studio.App.getActiveEditor;

notificationTag = 'SimulinkOnline:ui:SizeLimitNotification';
notification = message(notificationTag, width, height).getString();
editor.deliverInfoNotification(notificationTag, notification);

sent = true;
end
