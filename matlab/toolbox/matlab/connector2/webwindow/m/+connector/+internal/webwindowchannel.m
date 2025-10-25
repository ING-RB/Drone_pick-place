classdef webwindowchannel < handle

    properties ( Access = public )
        
        isFocused

        ParentWindow

    end

    properties ( SetAccess = private, GetAccess = public, Transient )
        
        ChannelName = ''

        windowList = connector.internal.webwindow.empty();

        isConnected = false

        FocusChannel = '/channel/webwindow/focus'

    end

    methods

        function obj = webwindowchannel(channelName)
            obj.ChannelName = channelName;
        end

        function connect(obj, handler)
            if ~isempty(obj.ChannelName)
                message.subscribe(obj.ChannelName, handler);
                message.subscribe(obj.FocusChannel, @obj.handleFocus);
                obj.isConnected = true;
            end
        end

        function addWindow(obj, value)
            obj.windowList(end+1)=value;
        end

        function removeWindow(obj, value)
            obj.windowList(obj.windowList == value) = [];
        end

        function publishMessage(obj, data)
            message.publish(obj.ChannelName, data);
        end

        function set.isFocused(obj, value)
            obj.isFocused = value;
        end
    end


    methods(Access=private)
        function handleFocus(obj, data)
            if isequal(data.channelName, obj.ChannelName)
                windowMgr = connector.internal.webwindowmanager.instance();
                for win = windowMgr.windowList
                    if win.isFocused && isempty(obj.ParentWindow) && win.WebWindowChannel ~= obj
                        obj.ParentWindow = win;
                    end
                end
                obj.isFocused = true;
            else
                obj.isFocused = false;
            end
        end
    end
end
