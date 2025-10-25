function sent = closeReturnToMATLABNotification()
    sent = false;
    studios = DAS.Studio.getAllStudiosSortedByMostRecentlyActive;
    if ~~isempty(studios)
        return;
    end
    studio = studios(1);
    editor = studio.App.getActiveEditor;
    
    notificationTag = 'SimulinkOnline:ui:returnMATLABNotification';
    editor.closeNotificationByMsgID(notificationTag);
    
    sent = true;
end
    