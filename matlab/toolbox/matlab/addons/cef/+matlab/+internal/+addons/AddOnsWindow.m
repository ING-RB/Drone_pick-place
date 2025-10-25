classdef (Sealed = true, Hidden = true) AddOnsWindow < handle
    % AddOnsWindow: The class represents Add-Ons Window object

    %  Copyright: 2016-2023 The MathWorks, Inc.

    properties (Access = private)
        webwindow

        debugPort

        % Browser position at normal window state for restoring from
        % maximized window state
        normalWindowPosition

        title
    end

    properties (Access = public)
        addOnsCommunicator

        uiNotifier
    end

    events
        % This event is triggered before the window is actually closed
        AddOnsWindowClosing
        % This event is triggered after the window is closed in MATLAB
        % Online
        EmbeddedAddOnWindowClosed
    end

    methods (Access = {?matlab.internal.addons.Explorer, ?matlab.internal.addons.Manager})

        function obj = AddOnsWindow(clientTitle, clientType, position)
            
            if usejava('jvm')
                obj.addOnsCommunicator = com.mathworks.addons.AddonsCommunicator(clientType.getServerToClientChannel, clientType.getClientToServerChannel);
                obj.addOnsCommunicator.startMessageService;
                obj.uiNotifier = clientType.getUINotifier(obj.addOnsCommunicator);
                com.mathworks.addons_common.notificationframework.UINotifierRegistry.register(obj.uiNotifier);
            end
            obj.debugPort = matlab.internal.getDebugPort;
            obj.title = char(clientTitle);

            if (nargin > 2)
                obj.normalWindowPosition = position;
            end
        end

        function launch(obj, url, maximized)
            obj.createWebWindowWithUrl(char(url));

            if(nargin == 3 && maximized)
                % call bringToFront before maximize
                % otherwise maximize would fail to restore the window back
                % to the pervious normalWindowPosition
                obj.webwindow.maximize;
            end
        end

        function bringToFront(obj)
            if ~isempty(obj.webwindow)
                obj.webwindow.bringToFront();
            end
        end

        function updateUrl(obj, url)
            obj.webwindow.URL = char(url.toString());
        end

        function debugPort = getDebugPort(obj)
            debugPort = obj.debugPort;
        end

        function url = getUrl(obj)
            url = replace(obj.webwindow.executeJS('window.location.href'),'"','');
        end

        function disposeForCef(obj,~,~)
            notify(obj, 'AddOnsWindowClosing');
            obj.cleanup;
        end

        function disposeForEmbeddedWindow(obj,~,~)
            notify(obj, 'EmbeddedAddOnWindowClosed');
            obj.cleanup;
        end

        function cleanup(obj)
           if usejava('jvm')
            com.mathworks.addons_common.notificationframework.UINotifierRegistry.unRegister(obj.uiNotifier);
            obj.addOnsCommunicator.unsubscribe;
           end
        end

        function close(obj)
            if usejava('jvm')
                if ismac
                    com.mathworks.util.NativeJava.macActivateIgnoringOtherApps();
                end
            end

			obj.webwindow.close();
        end

        function windowPosition = getNormalWindowPosition(obj)
            windowPosition = obj.normalWindowPosition;
        end

        function maximized = isMaximized(obj)
            maximized = obj.webwindow.isMaximized;
        end

        function handleBrowserResizing(obj, ~)
            if(~obj.webwindow.isMaximized())
                obj.normalWindowPosition = obj.webwindow.Position;
            end
        end
    end

    methods (Access = private)
        function createWebWindowWithUrl(obj, url)
            if ~isempty(obj.webwindow)
                return;
            end
            obj.webwindow = matlab.internal.webwindow(url, obj.debugPort);
            obj.webwindow.Title = obj.title;

            if (~isempty(obj.normalWindowPosition))
                obj.webwindow.Position = obj.normalWindowPosition;
                obj.webwindow.CustomWindowResizingCallback = @(cefobj, event)obj.handleBrowserResizing(event);
            end

            if ~matlab.internal.addons.Configuration.isClientRemote
                obj.webwindow.CustomWindowClosingCallback = @obj.disposeForCef;
            else
                obj.webwindow.MATLABWindowExitedCallback = @obj.disposeForEmbeddedWindow;
            end   
        end
    end
end
