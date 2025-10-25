function copyProxySettingsFromEnvironment()
% copyProxySettingsFromEnvironment Sets MATLAB proxy settings from MW_PROXY environment variables

% Copyright 2020-2021 The MathWorks, Inc.

    host = getenv('MW_PROXY_HOST');
    port = getenv('MW_PROXY_PORT');
    user = getenv('MW_PROXY_USERNAME');
    pass = getenv('MW_PROXY_PASSWORD');

    % If MW_PROXY_HOST and MW_PROXY_PORT are not both set
    % leave settings alone
    if isempty(host) || isempty(port)
        return
    end

    s = settings;
    ws = s.matlab.web;
    ws.UseProxy.TemporaryValue = true;
    ws.ProxyHost.TemporaryValue = host;
    ws.ProxyPort.TemporaryValue = port;

    % Use Authentication if we have user or pass
    ws.UseProxyAuthentication.TemporaryValue = ~isempty(user) || ~isempty(pass);
    ws.ProxyUsername.TemporaryValue = user;
    ws.ProxyPassword.TemporaryValue = pass;

    if usejava('jvm')
        % Setting java prefs overrides PersonalValue, we backup and restore the current Temporary and PersonalValues
        bkup = backupSettings(ws);
        restoreSettingsFromBackup = onCleanup(@()restoreSettings(ws, bkup));

        com.mathworks.mlwidgets.html.HTMLPrefs.setUseProxy(ws.UseProxy.ActiveValue);
        com.mathworks.mlwidgets.html.HTMLPrefs.setProxyHost(ws.ProxyHost.ActiveValue);
        com.mathworks.mlwidgets.html.HTMLPrefs.setProxyPort(ws.ProxyPort.ActiveValue);
        com.mathworks.mlwidgets.html.HTMLPrefs.setUseProxyAuthentication(ws.UseProxyAuthentication.ActiveValue);
        com.mathworks.mlwidgets.html.HTMLPrefs.setProxyUsername(ws.ProxyUsername.ActiveValue);
        com.mathworks.mlwidgets.html.HTMLPrefs.setProxyPassword(ws.ProxyPassword.ActiveValue);
        com.mathworks.mlwidgets.html.HTMLPrefs.setProxySettings();
    end
end

function bkup = backupSettings(ws)
    for name = ["UseProxy", "ProxyHost", "ProxyPort", "UseProxyAuthentication", "ProxyUsername", "ProxyPassword"]
        if hasTemporaryValue(ws.(name))
            bkup.TemporaryValue.(name) = ws.(name).TemporaryValue;
        end
        if hasPersonalValue(ws.(name))
            bkup.PersonalValue.(name) = ws.(name).PersonalValue;
        end
    end
end

function clearSettings(ws)
    for name = ["UseProxy", "ProxyHost", "ProxyPort", "UseProxyAuthentication", "ProxyUsername", "ProxyPassword"]
        if hasTemporaryValue(ws.(name))
            clearTemporaryValue(ws.(name));
        end
        if hasPersonalValue(ws.(name))
            clearPersonalValue(ws.(name));
        end
    end
end

function restoreSettings(ws, bkup)
    clearSettings(ws);

    if isfield(bkup, "PersonalValue")
        for name = string(fieldnames(bkup.PersonalValue))'
            ws.(name).PersonalValue = bkup.PersonalValue.(name);
        end
    end
    if isfield(bkup, "TemporaryValue")
        for name = string(fieldnames(bkup.TemporaryValue))'
            ws.(name).TemporaryValue = bkup.TemporaryValue.(name);
        end
    end
end