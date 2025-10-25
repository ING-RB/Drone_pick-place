function use_system_browser = useSystemBrowser
%MATLAB.INTERNAL.DOC.UI.USESYSTEMBROWSER

%   Copyright 2020-2023 The MathWorks, Inc.

    use_system_browser = checkConfigForSystemBrowser || isSystemBrowserForDoc;
end

function sysbrowser = checkConfigForSystemBrowser
    sysbrowser = ~usejava('mwt') || feature('webui');
end

function system_browser_doc = isSystemBrowserForDoc
    if matlab.internal.web.isMatlabOnlineEnv
        settingPlatform = 'matlabOnline';
    else
        settingPlatform = 'matlabDesktop';
    end

    system_browser_doc = isSystemBrowserForPlatform(settingPlatform);
end

function system_browser_doc = isSystemBrowserForPlatform(settingPlatform)
    s = settings;
    systemBrowserSetting = s.matlab.help.SystemBrowserForDoc;

    if systemBrowserSetting.hasActiveValue
        system_browser_doc = any(strcmp(systemBrowserSetting.ActiveValue,settingPlatform)); 
    else 
        % The setting has no value.
        system_browser_doc = 0; 
    end
end