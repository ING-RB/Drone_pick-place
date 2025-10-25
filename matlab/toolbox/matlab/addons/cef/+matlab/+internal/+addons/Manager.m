classdef (Sealed = true) Manager < handle
    % Manager: This class manages an instance of Add-Ons Manager window
    
    % Copyright: 2016-2024 The MathWorks, Inc.
    
    
    properties (Access = private)
        windowStateUtil = matlab.internal.addons.WindowStateUtil;

        addOnsWindowInstance
        
        WINDOW_TITLE = message('matlab_addons:addonsManager:addOnManagerWindowTitle').getString;
    end
    
    properties (Constant)
        SERVER_TO_CLIENT_CHANNEL = "/mw/addons/manager/servertoclient"
        
        CLIENT_TO_SERVER_CHANNEL = "/mw/addons/manager/clienttoserver";
    end
    
    methods (Access = private)
        
        function this = Manager()
            this.addOnsWindowInstance = matlab.internal.addons.AddOnsWindow.empty();
            % Subscribe to clientToServer channel
            uiMessageHandler = matlab.internal.addons.UiMessageHandler(matlab.internal.addons.Manager.SERVER_TO_CLIENT_CHANNEL);
            message.subscribe(matlab.internal.addons.Manager.CLIENT_TO_SERVER_CHANNEL, @(msg) uiMessageHandler.handleMessage(msg));
            if ~matlab.internal.addons.Configuration.isClientRemote
                this.subscribeForThemeAppliedMessage();
            end
        end
    end
    
    methods (Static, Access = public)
        
        function obj = getInstance()
            mlock;
            persistent uniqueManagerInstance;
            if(isempty(uniqueManagerInstance))
                obj = matlab.internal.addons.Manager();
                uniqueManagerInstance = obj;
            else
                obj = uniqueManagerInstance;
            end
        end
    end
    
    methods (Access = public)

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %   1. Creates new Add-Ons Manager if it is not already open
        %   2. If Add-Ons Manager is already open, the function brings it to front
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function show(obj, navigationData)
            if(obj.windowExists)
                obj.sendMessage(constructClientMessage('navigateTo', navigationData.getNavigationDataAsJson));
                obj.addOnsWindowInstance.bringToFront();
            else
                obj.createNewWindow;
                obj.loadUrlForNavigationData(navigationData);
                if matlab.internal.addons.Configuration.isClientRemote
                    obj.addOnsWindowInstance.bringToFront();   
                end
            end
        end
        
        function exists = windowExists(obj)
            exists = ~(isempty(obj.addOnsWindowInstance));
        end
        
        function debugPort = getDebugPort(obj)
            debugPort = obj.addOnsWindowInstance.getDebugPort;
        end
        
        function url = getUrl(obj)
            url = obj.addOnsWindowInstance.getUrl;
        end
        
        function close(obj)
            obj.addOnsWindowInstance.cleanup;
            if matlab.internal.addons.Configuration.isClientRemote
                obj.disposeForEmbeddedWindow;
            else
                obj.disposeForCef;
            end
        end
    end
    
    methods (Access = private)
        
        function createNewWindow(obj)
            clientType = '';
            if usejava('jvm')
                clientType = com.mathworks.addons.ClientType.MANAGER;
            end
            if matlab.internal.addons.Configuration.isClientRemote
                obj.addOnsWindowInstance = matlab.internal.addons.AddOnsWindow(obj.WINDOW_TITLE, clientType);
                addlistener(obj.addOnsWindowInstance, 'EmbeddedAddOnWindowClosed', @obj.disposeForEmbeddedWindow);
            else
                obj.addOnsWindowInstance = matlab.internal.addons.AddOnsWindow(obj.WINDOW_TITLE, clientType, obj.windowStateUtil.getPositionForManager);
                addlistener(obj.addOnsWindowInstance, 'AddOnsWindowClosing', @obj.disposeForCef);
            end
        end
        
        function disposeForCef(obj,~,~)
            currentPosition = obj.addOnsWindowInstance.getNormalWindowPosition;
            isMaximized = obj.addOnsWindowInstance.isMaximized;
            obj.addOnsWindowInstance.close();
            obj.windowStateUtil.setManagerPositionSetting(currentPosition);
            obj.windowStateUtil.setManagerWindowMaximizedSetting(isMaximized);
            obj.addOnsWindowInstance = matlab.internal.addons.AddOnsWindow.empty();
        end
        
        function disposeForEmbeddedWindow(obj,~,~)
            if ~isempty(obj.addOnsWindowInstance)
                obj.addOnsWindowInstance = matlab.internal.addons.AddOnsWindow.empty();
            end
        end

        function loadUrlForNavigationData(obj, navigationData)
            if obj.useDebugPage
                urlGenerator = matlab.internal.addons.AddOnWindowUrl(connector.getUrl("toolbox/matlab/addons/AddonsManager-debug.html"));
            else
                urlGenerator = matlab.internal.addons.AddOnWindowUrl(connector.getUrl("toolbox/matlab/addons/AddonsManager.html"));
            end
            matlabVersion = ['R' version('-release')];

            if (strcmpi(version('-description'), 'Prerelease')) 
                matlabVersion = [matlabVersion '_Prerelease'];
            end
            matlabUpdateLevel = matlabRelease.Update;
            url = urlGenerator.addQueryParameter("navigateTo", navigationData.getNavigationDataAsJson)...
                    .addQueryParameter("viewer", matlab.internal.addons.Configuration.viewer)...
                        .addQueryParameter("release", matlabVersion)...
                        .addQueryParameter("matlabUpdateLevel", matlabUpdateLevel)...
                        .addQueryParameter("currentTheme", obj.theme)...
                        .addQueryParameter("useRegFwk", obj.useRegFwk)...
                        .addQueryParameter("upgrade_download_end_point", obj.getEndPointForUpgradeDownloadURL)...
                        .generate;
            if matlab.internal.addons.Configuration.isClientRemote
                obj.addOnsWindowInstance.launch(url);
            else
                obj.addOnsWindowInstance.launch(url, obj.windowStateUtil.getManagerWindowMaximizedSetting);
            end
        end

        function publish(obj, matlabToAddOnsWindowMessage)
            obj.addOnsWindowInstance.addOnsCommunicator.publish(matlabToAddOnsWindowMessage);
        end
        
        function sendMessage(~, msg)
            message.publish(matlab.internal.addons.Manager.SERVER_TO_CLIENT_CHANNEL, msg);
        end
        
        function value = useRegFwk(~)
            % Always use reg-fwk in JavaScript Desktop
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

        function value = useDebugPage(~)            
            settingsAPI = settings;
            managerSettings = settingsAPI.matlab.addons.manager;
            value = false;
            if managerSettings.hasSetting('UseDebugPage')
                value = managerSettings.UseDebugPage.PersonalValue;
            end
        end

        % Get theme value from setting
        function themeValue = theme(~)            
            themeValue = 'Light';
            try
                settingsAPI = settings;
                themeSettings = settingsAPI.matlab.appearance;
                if themeSettings.hasSetting('CurrentTheme')
                    themeValue = themeSettings.CurrentTheme.ActiveValue;
                end
            catch
                themeValue = 'Light';
            end
        end

        function subscribeForThemeAppliedMessage(this)
            message.subscribe(this.CLIENT_TO_SERVER_CHANNEL, @(msg)this.themeAppliedMessageHandler(msg));
        end

        function themeAppliedMessageHandler(this, msg)
            if strcmpi(msg.type,'themeApplied') == 1
                this.addOnsWindowInstance.bringToFront();
            end
        end

        function value = getEndPointForUpgradeDownloadURL(~)
            urlManager = matlab.internal.UrlManager;
            value = urlManager.MATHWORKS_DOT_COM;

            % Get sandbox override if exists
            settingsAPI = settings;

            if settingsAPI.matlab.hasSetting('latestgr') && settingsAPI.matlab.latestgr.hasSetting('wsendpointoverride')
                value = settingsAPI.matlab.latestgr.wsendpointoverride.ActiveValue;                
            end
        end
        
    end
end
