function setSystemBrowserForDoc(value)
%

%   Copyright 2021-2024 The MathWorks, Inc.
    arguments
        value (1,1) logical = true;
    end

    if matlab.internal.web.isMatlabOnlineEnv
        settingPlatform = 'matlabOnline';
    else
        settingPlatform = 'matlabDesktop';
    end

    setSystemBrowserForPlatform(value, settingPlatform);
end

function setSystemBrowserForPlatform(value, settingPlatform)
    s = settings;
    systemBrowserSetting = s.matlab.help.SystemBrowserForDoc;

    if (value)
        systemBrowserSetting.TemporaryValue = {settingPlatform};
    else
        systemBrowserSetting.TemporaryValue = {};
    end
end