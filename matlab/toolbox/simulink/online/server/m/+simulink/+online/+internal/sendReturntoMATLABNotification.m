function sent = sendReturntoMATLABNotification()
sent = false;
studios = DAS.Studio.getAllStudiosSortedByMostRecentlyActive;
if ~~isempty(studios)
    return;
end
studio = studios(1);
editor = studio.App.getActiveEditor;

notificationTag = 'SimulinkOnline:ui:returnMATLABNotification';
notification = message(notificationTag).getString();
editor.deliverInfoNotification(notificationTag, notification);

sent = true;
end
