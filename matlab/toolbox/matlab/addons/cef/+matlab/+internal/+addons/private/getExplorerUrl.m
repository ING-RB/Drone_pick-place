function urlToBeLoaded = getExplorerUrl(navigationData)
    % GETEXPLORERURL Returns the URL to be loaded to open Add-on Explorer

    % Copyright: 2019-2022 The MathWorks, Inc.
    EXPLORER_LAUNCHER_URL_OFFESET = "toolbox/matlab/addons/AddOnExplorerLauncher.html";

    if ~isExplorerSupported()
        baseUrl = connector.getUrl(EXPLORER_LAUNCHER_URL_OFFESET);
        explorerUrlGenerator = matlab.internal.addons.AddOnWindowUrl(baseUrl);
        explorerUrlGenerator.addQueryParameter("showDefaultUnsupportedMsg", true);
        urlToBeLoaded = explorerUrlGenerator.generate.EncodedURI;
    else

        platformInfo = matlab.internal.addons.util.explorer.getPlatformInfo();
        locale = strrep(get(0, 'Language'), "_", "-");
        mlRelease = ['R' version('-release')];
        docLanguageLocaleEnum = matlab.internal.doc.services.getDocLanguageLocale;
        docLanguage = docLanguageLocaleEnum.settingLocaleString;
        viewer = matlab.internal.addons.Configuration.viewer;
        connectorUrls = jsonencode(getConnectorUrls());

        baseUrl = strcat(string(matlab.internal.addons.util.explorer.baseUrl.get),"/","loading");
        urlGenerator = matlab.internal.addons.AddOnWindowUrl(baseUrl);
        explorerUrl = urlGenerator.addQueryParameter("navigateTo", navigationData.getNavigationDataAsJson)...
                        .addQueryParameter("platform", platformInfo)...
                           .addQueryParameter("language", locale)...
                                .addQueryParameter("release", mlRelease)...
                                    .addQueryParameter("docLanguage", docLanguage)...
                                        .addQueryParameter("viewer", viewer)...
                                            .addQueryParameter("connectorUrls", connectorUrls)...
                                                .addQueryParameter("entitlementId", getEntitlementId())...
                                                    .addQueryParameter("licenseMode", getLicenseMode())...
                                                        .addQueryParameter("ddux", jsonencode(getDduxKeys()))...
                                                            .addQueryParameter("theme", getCurrentTheme())...
                                                                .generate;
        explorerLauncherUrlGenerator = matlab.internal.addons.AddOnWindowUrl(string(connector.getUrl(EXPLORER_LAUNCHER_URL_OFFESET)));
        explorerLauncherUrl = explorerLauncherUrlGenerator.addQueryParameter("explorerUrl", explorerUrl.EncodedURI).generate;

        urlToBeLoaded = explorerLauncherUrl.EncodedURI;
    end

    function connectorUrls = getConnectorUrls()
        connectorUrls = struct;
        connectorUrls.matlab = getConnectorUrlForMatlab();
        connectorUrls.login = getConnectorUrlForLogin();
    end

    function url = getConnectorUrlForMatlab()
        urlGenerator = matlab.internal.addons.AddOnWindowUrl(connector.getUrl("toolbox/matlab/addons/GalleryMatlabCommunicator.html"));
        url = urlGenerator.addQueryParameter("useRegFwk", useRegFwk()).generate.EncodedURI;
    end

    function url = getConnectorUrlForLogin()
        loginUrl = matlab.internal.login.getLoginFrameUrl( ...
            "channel", "__mlfpmc__", ...
            "external", true);
        url = connector.getUrl(loginUrl);
    end

    function entitlementId = getEntitlementId()
        licenseMode = matlab.internal.licensing.getLicMode;
        entitlementId = licenseMode.entitlement_id;
    end

    function dduxKeys = getDduxKeys()
        dduxKeys = struct;
        dduxKeys.installationId = string(dduxinternal.getInstallationId);
        dduxKeys.machineHash = string(dduxinternal.getMachineHash);
        dduxKeys.sessionKey = string(dduxinternal.getSessionKey);
    end

    function licenseMode = getLicenseMode()
        if matlab.internal.licensing.canAddonsAllowTrialsForLicense
            licenseMode = "FlexLicense";
        else
            licenseMode = "WebLicense";
        end
    end

    function value = useRegFwk(~)
        % ToDo: If condition can be eliminated when Java cache is deleted.
        if feature('webui')
            value = true;
            return;
        end

        settingsAPI = settings;
        managerSettings = settingsAPI.matlab.addons.manager;
        value = false;
        if managerSettings.hasSetting('UseRegFwk')
            value = managerSettings.UseRegFwk.PersonalValue;
        end
    end

end
