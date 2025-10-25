function enableFirefoxWarning(perfVal)
    % Check preference
    import simulink.online.internal.Preference;
    groupName = Preference.groupName();
    prefName = Preference.clipboardFireFoxWarningName();
    setpref(groupName, prefName, perfVal);
end
