function warnOnMostRecentStudio(messageID, messageContent)
    % Check preference
    import simulink.online.internal.Preference;
    groupName = Preference.groupName();
    prefName = Preference.clipboardFireFoxWarningName();
    if ispref(groupName, prefName)
        showWarning = getpref(groupName, prefName);
    else
        showWarning = Preference.clipboardFireFoxWarningDefaultValue();
    end
    if ~showWarning
        return;
    end

    % Show warning on most recently active
    allStudios = DAS.Studio.getAllStudiosSortedByMostRecentlyActive;
    if isempty(allStudios)
        return;
    end
    studio = allStudios(1);
    editor = studio.App.getActiveEditor;
    editor.deliverWarnNotification(messageID, messageContent);
end
