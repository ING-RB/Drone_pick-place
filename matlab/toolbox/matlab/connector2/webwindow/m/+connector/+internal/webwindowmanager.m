classdef webwindowmanager < handle

    methods(Access=private)
        function newObj = webwindowmanager()
            %subscribe to message service
            newObj.Channel = connector.internal.webwindowchannel('/channel/webwindow');
            newObj.channelList(end+1) = newObj.Channel;
            newObj.Channel.connect(@newObj.handleMessage);
        end
    end

    methods(Static)
        function obj = instance()
            persistent uniqueInstance;
            if isempty(uniqueInstance)
                obj = connector.internal.webwindowmanager();
                container = getenv('MW_CONNECTOR_DEFAULT_WINDOW_CONTAINER');
                if ~isempty(container)
                    obj.defaultWindowContainer = container;
                end
                uniqueInstance = obj;
            else
                obj = uniqueInstance;            
            end
        end

        function setClientDefaults(defaults)
            obj = connector.internal.webwindowmanager.instance();
            if isstruct(defaults)
                if isfield(defaults, 'position')
                    obj.defaultPosition = reshape(defaults.position,[1,4]);
                end
            end
        end

        function setDefaultWindowContainer(container)
            obj = connector.internal.webwindowmanager.instance();
            obj.defaultWindowContainer = container;
        end

        function pageRefreshed()
            import matlab.internal.capability.Capability;
            useLocal = Capability.isSupported(Capability.LocalClient);
            % Only support if remote client
            if ~useLocal
                obj = connector.internal.webwindowmanager.instance();
                % Set main channel to have focus
                obj.setChannelFocus(obj.Channel);
                for elm = obj.windowList
                    if ~isequal(elm.WindowContainer, 'Tabbed') && ~isequal(elm.WindowContainer, 'Popup')
                        obj.reregisterWindow(elm);
                    end
                end
            end
        end
    end


    properties ( Access = public )
        %print to the console if unsupported operation used
        debugMode= false
    end

    properties (SetAccess = private, GetAccess = public )

        %windows that are open
        windowList= connector.internal.webwindow.empty();

        channelList = connector.internal.webwindowchannel.empty();

        Channel = '/channel/webwindow'

        defaultPosition = [ 100 100 600 400 false]

        defaultWindowContainer = 'WebDialog';
    end

    methods

        % Gets all the webwindow handles
        function list = findAllWebwindows(obj)
            list= obj.windowList;
        end

    end

    methods(Hidden=true)


        function publishMessage(obj, channel, data)
            if isfield(data, 'args') && isfield(data.args, 'url')
                if startsWith(data.args.url, connector.getBaseUrl)
                    %strip url so that its just path
                    data.args.url = strrep(data.args.url, connector.getBaseUrl, '/');
                end
            end
            channel.publishMessage(data);
        end


        %route the message from index.js to the correct webwindow.m object
        function handleMessage(obj, data)
            child = {};
            if strcmp(data.type, 'registerChannel')
                obj.registerChannel(data.channelName);
            end
            if strcmp(data.type, 'unregisterChannel')
                obj.unregisterChannel(data.channelName);
            end
            if strcmp(data.type, 'pageRefreshed')
                obj.pageRefreshed();
            end
            for elm = obj.windowList
                if isvalid(elm)
                    if strcmp(data.type, 'killAll') && ~elm.isRefreshSupported
                        obj.deregisterWindow(elm);
                    end
                    if strcmp(elm.WinID,data.winId)
                        child = elm;
                        break;
                    end
                end
            end
            if ~isempty(child)
                switch(data.type)
                    case 'windowResized'
                        child.WindowResizedListener(data.bounds);
                    case 'windowClosing'
                        child.WindowClosingListener();
                    case 'MATLABWindowExited'
                        obj.unregisterChannel(child);
                        child.MATLABWindowExitedCallbackListener();
                    case 'focusLost'
                        child.FocusLostListener();
                    case 'focusGained'
                        child.FocusGainedListener();
                    case 'pageLoadFinished'
                        child.PageLoadFinishedCallbackListener();
                    case 'visibilityChanged'
                        child.VisibilityChangedListener(data.isVisible);
                    case 'WindowInvalid'
                        child.MATLABWindowExitedCallbackListener();
                    case 'windowMinimized'
                        child.WindowMinimizedListener();
                    case 'windowMaximized'
                        child.WindowMaximizedListener();
                    case 'windowRestored'
                        child.WindowRestoredListener();
                end
            end
        end

        %record the existence of a new window
        function registerWindow(obj,value)
            data.args.winId = value.WinID;
            data.args.url = value.URL;
            data.args.windowContainer = value.WindowContainer;
            %TODO: remove support for this
            data.args.forceSameDomainAsParent = false;
            data.args.origin = value.Origin;
            data.args.isRefreshSupported = value.isRefreshSupported;
            data.type = 'register';

            % Get active channel if refresh is supported and window is not tabbed otherwise 
            % use main and window is not tabbed.
            channel = obj.Channel;
            focusedChannel = channel;

            for elm = obj.channelList
                if elm.isFocused
                    focusedChannel = elm;
                end
            end

            if value.isRefreshSupported && ~isequal(value.WindowContainer, 'Tabbed') && ~isequal(value.WindowContainer, 'Popup')
                channel = focusedChannel;
            end


            % Override list for allowing apps to be on a different channel
            % based on focus for now until AppContainer supports this
            % workflow directly.
            if contains(value.URL,'ScopeContainer','IgnoreCase',true) 
                channel = focusedChannel;
            end

            if ~value.isRefreshSupported && focusedChannel ~= channel
                obj.bringParentToFront
            end

            value.WebWindowChannel = channel;
            channel.addWindow(value);

            obj.publishMessage(channel, data);

            obj.windowList(end+1)=value;
        end

        function reregisterWindow(obj, window)
            % Some clients such as AppContainer don't natively support refresh,
            % but we still want to alert them that the window has been refreshed.
            if ~isempty(window.PageRefreshCallback)
                internal.Callback.execute(window.PageRefreshCallback,obj);
            end

            if (isvalid(window) && window.isWindowValid) 
                if (window.isRefreshSupported)
                    data.args.winId = window.WinID;
                    data.args.url = window.URL;
                    data.args.windowContainer = window.WindowContainer;
                    data.args.forceSameDomainAsParent = false;
                    data.args.origin = window.Origin;
                    data.args.isRefreshSupported = window.isRefreshSupported;
                    data.type = 'register';

                    channel = window.WebWindowChannel;

                    obj.publishMessage(channel, data);

                    window.show;
                end
            end
        end

        function bringParentToFront(obj)
            data = struct('type', 'bringParentToFront');
            obj.publishMessage(obj.Channel, data);
        end

        %forget a window
        function deregisterWindow(obj,value)
            if isvalid(obj) && ~isempty(obj.windowList)
                obj.windowList(obj.windowList == value) = [];
                channel = value.WebWindowChannel;
                channel.removeWindow(value);
                delete(value);
            end
        end

        function centerOnScreen(obj, value)
            browserWindow = pf.display.DisplayRect;
            dialogWindow = pf.display.DisplayRect;
            browserWindow.x = obj.defaultPosition(1);
            browserWindow.y = obj.defaultPosition(2);
            browserWindow.width = obj.defaultPosition(3);
            browserWindow.height = obj.defaultPosition(4);

            dialogWindow.x = value.Position(1);
            dialogWindow.y = value.Position(2);
            dialogWindow.width = value.Position(3);
            dialogWindow.height = value.Position(4);

            dialogWindow = pf.display.getCenterRect(dialogWindow, browserWindow, 5);
            value.Position = [dialogWindow.x dialogWindow.y dialogWindow.width dialogWindow.height];
        end

        function ensureOnScreen(obj, value)
            browserWindow = pf.display.DisplayRect;
            dialogWindow = pf.display.DisplayRect;
            browserWindow.x = obj.defaultPosition(1);
            browserWindow.y = obj.defaultPosition(2);
            browserWindow.width = obj.defaultPosition(3);
            browserWindow.height = obj.defaultPosition(4);

            dialogWindow.x = value.Position(1);
            dialogWindow.y = value.Position(2);
            dialogWindow.width = value.Position(3);
            dialogWindow.height = value.Position(4);

            dialogWindow = pf.display.onScreenRect(dialogWindow, browserWindow, 5);
            value.Position = [dialogWindow.x dialogWindow.y dialogWindow.width dialogWindow.height];
        end

        function displayWarning(obj, operation)
            if obj.debugMode
                disp(['Warning: ', operation,' is not supported in MATLAB Online webwindow.'])
            end
        end

        function registerChannel(obj, channelName)
            newChannel = connector.internal.webwindowchannel(channelName);
            obj.channelList(end+1) = newChannel;
            newChannel.connect(@obj.handleMessage);

            for win = obj.windowList
                if win.WebWindowChannel ~= newChannel && win.isFocused
                    newChannel.ParentWindow = win;
                end
            end
        end

        function unregisterChannel(obj, window)
            for elm = obj.channelList
                % Loop through the channels and if the window is a parent,
                % move all the windows back to the main channel.
                if elm.ParentWindow == window
                    for win = elm.windowList
                        obj.changeWindowChannel(win, obj.Channel);
                    end

                    break;
                end
            end
        end

        function changeWindowChannel(obj, window, newChannel)
            oldChannel = window.WebWindowChannel;
            oldChannel.removeWindow(window);
            window.WebWindowChannel = newChannel;
            newChannel.addWindow(window);
            obj.reregisterWindow(window);
        end

        function setChannelFocus(obj, channel)
            for elm = obj.channelList
                if isequal(channel, elm.ChannelName)
                    elm.isFocused = true;
                else
                    elm.isFocused = false;
                end
            end
        end
    end

end
