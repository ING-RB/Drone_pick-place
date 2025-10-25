classdef (Sealed = true) Explorer < handle
    % Explorer: This class manages an instance of Add-Ons Explorer window
    
    % Copyright: 2016-2021 The MathWorks, Inc.
    
    properties (Access = private)
        addOnsWindowInstance

        windowStateUtil = matlab.internal.addons.WindowStateUtil
        
        WINDOW_TITLE = message('matlab_addons:addonsManager:addOnExplorerWindowTitle').getString;
    end

    properties (Constant)
        SERVER_TO_CLIENT_CHANNEL = "/mw/addons/explorer/servertoclient"
        
        CLIENT_TO_SERVER_CHANNEL = "/mw/addons/explorer/clienttoserver";
    end
    
    methods (Access = private)
        
        function newObj = Explorer()
            newObj.addOnsWindowInstance = matlab.internal.addons.AddOnsWindow.empty();
            % ToDo: This is a temporary workaround to convert Explorer URL to use the
            % correct worker host name. This is meant to receive messages
            % from MATLAB Online client
            newObj.subscribeForMessageFromMatlabOnlineClient();
            
            % Subscribe to clientToServer channel to receive messages from
            % Add-on Explorer
            uiMessageHandler = matlab.internal.addons.UiMessageHandler(matlab.internal.addons.Explorer.SERVER_TO_CLIENT_CHANNEL);
            message.subscribe("/mw/addons/explorer/clienttoserver", @(msg) uiMessageHandler.handleMessage(msg));
        end
    end
    
    methods (Static, Access = public)
        
        function obj = getInstance()
            mlock;
            persistent uniqueExplorerInstance;
            if(isempty(uniqueExplorerInstance))
                obj = matlab.internal.addons.Explorer();
                uniqueExplorerInstance = obj;
            else
                obj = uniqueExplorerInstance;
            end
        end
    end
    
    methods (Access = public)

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %   1. Creates new Add-Ons Explorer if it is not already open
        %   2. If Add-Ons Explorer is already open, the function brings it to front
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function show(obj, navigationData)
            if(obj.windowExists)
                obj.sendMessage(constructClientMessage('navigateTo', navigationData.getNavigationDataAsJson));
            else
                obj.createNewWindow;
                url = char(getExplorerUrl(navigationData));
                obj.loadUrlForNavigateToMessage(url);
            end
            obj.addOnsWindowInstance.bringToFront();
        end

        function exists = windowExists(obj)
            exists = ~(isempty(obj.addOnsWindowInstance));
        end
        
        function bringToFront(obj)
            obj.addOnsWindowInstance.bringToFront();
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

        function sendMessage(obj, msg)
            if(obj.windowExists)
                message.publish(matlab.internal.addons.Explorer.SERVER_TO_CLIENT_CHANNEL, msg);
            end
        end
    end
    
    methods (Access = private)

        function createNewWindow(obj)
            clientType = '';
            if usejava('jvm')
                clientType = com.mathworks.addons.ClientType.EXPLORER;
            end
            if matlab.internal.addons.Configuration.isClientRemote
                obj.addOnsWindowInstance = matlab.internal.addons.AddOnsWindow(obj.WINDOW_TITLE, clientType);
                addlistener(obj.addOnsWindowInstance, 'EmbeddedAddOnWindowClosed', @obj.disposeForEmbeddedWindow);
            else
                obj.addOnsWindowInstance = matlab.internal.addons.AddOnsWindow(obj.WINDOW_TITLE, clientType, obj.windowStateUtil.getPositionForExplorer);
                addlistener(obj.addOnsWindowInstance, 'AddOnsWindowClosing', @obj.disposeForCef);
            end
        end

        function disposeForCef(obj,~,~)
            currentPosition = obj.addOnsWindowInstance.getNormalWindowPosition;
            isMaximized = obj.addOnsWindowInstance.isMaximized;
            obj.addOnsWindowInstance.close();
            obj.windowStateUtil.setExplorerPositionSetting(currentPosition);
            obj.windowStateUtil.setExplorerWindowMaximizedSetting(isMaximized);
            obj.addOnsWindowInstance = matlab.internal.addons.AddOnsWindow.empty();
        end
        
        function disposeForEmbeddedWindow(obj,~,~)
            if ~isempty(obj.addOnsWindowInstance)
                obj.addOnsWindowInstance = matlab.internal.addons.AddOnsWindow.empty();
            end
        end

        function loadUrlForNavigateToMessage(obj, url)
            % ToDo: This is a temporary workaround to convert Explorer URL to use the
            % correct worker host name
            if matlab.internal.addons.Configuration.isClientRemote
                obj.sendResolveUrlMessageToMatlabOnline(url);
            else
                obj.addOnsWindowInstance.launch(url, obj.windowStateUtil.getExplorerWindowMaximizedSetting);
                obj.addOnsWindowInstance.bringToFront();
           end
        end
        
        % ToDo: Delete this after g2068743 is addressed  
        function sendResolveUrlMessageToMatlabOnline(~, url)
            messageToClient = struct('type', 'resolveExplorerUrlAndOpenExplorer', 'body', url);
            % Create a communicator which can be used to send/receive
            % messages to/from client
            message.publish("/matlab/addons/serverToClient", messageToClient);
        end
        
        % ToDo: Delete this after g2068743 is addressed
        function subscribeForMessageFromMatlabOnlineClient(this)
            % ToDo: Create a communicator to send and receive messages to/from
            % client
            message.subscribe("/matlab/addons/clientToServer", @(msg) this.clientMessageHandler(msg));
        end
        
        % ToDo: Delete this after g2068743 is addressed
        function clientMessageHandler(this, msg)
            if strcmp(msg.type,'openExplorerWithResolvedUrl') == 1
                this.addOnsWindowInstance.launch(msg.url);
                this.addOnsWindowInstance.bringToFront();
            end
        end

        
        function publish(obj, matlabToAddOnsWindowMessage)
            obj.addOnsWindowInstance.addOnsCommunicator.publish(matlabToAddOnsWindowMessage);
        end

        function communicationMessage = getMatlabToAddonsViewClientMessage(~, navigationData)
            communicationMessage = com.mathworks.addons.CommunicationMessage(com.mathworks.addons.CommunicationMessageType.NAVIGATE_TO, navigationData);
        end
    end
end
