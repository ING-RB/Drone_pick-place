function set(preferredUrl)
    %  SET Sets Add-on Explorer to custom url identified by preferredUrl
    %  preferredUrl Url to be used to bring up Add-on Explorer

    % Copyright 2020 The MathWorks, Inc.

    s = settings;
    addonsSetting = s.matlab.addons;
    if ~s.matlab.addons.hasGroup("explorer")
        addonsSetting.addGroup("explorer");
    end

    if ~s.matlab.addons.explorer.hasSetting("preferredEndPoint")
        s.matlab.addons.explorer.addSetting("preferredEndPoint");
    end

    s.matlab.addons.explorer.preferredEndPoint.PersonalValue = preferredUrl;
end

