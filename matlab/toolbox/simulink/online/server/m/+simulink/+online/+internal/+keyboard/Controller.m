classdef Controller < handle
    % This singleton class handles the message from and to front-end

    % Copyright 2021 The MathWorks, Inc.
    properties (Constant)
        PrefGroup = 'simulink_online';
        PrefName = 'keyboard';
        Unknown = 'unknown';
    end
    properties (GetAccess = ?tKeyboardController)
        % for keep tracking the necessity of prompting user the settings dialog
        % only need to notify once per session
        % if we have updated the locale based on our best guess
        % we do not need to prompt the settings dialog
        NeedToNotify = true; 
        % for keep track the necessity of updateKeyboardLayout
        % only need to update the layout once per session
        NeedToUpdateKeyboardLayout = true;

        FirstModelListener = [];

        clientSideKeyboardLayout = '';
        clientSideLocale = '';
    end

    methods (Static)
        function obj = instance()
            persistent uniqueInstance;
            if isempty(uniqueInstance)
                uniqueInstance = simulink.online.internal.keyboard.Controller();
            end
            obj = uniqueInstance;
        end
    end

    methods

        function obj = Controller
            import simulink.online.internal.events.FirstModelOpenEmitter;
            emitter = FirstModelOpenEmitter.getInstance();
            obj.FirstModelListener = ... 
                addlistener(emitter, FirstModelOpenEmitter.EventName, @obj.handleFirstModelOpen);
        end

        function updateClientSideKeyboardInfo(obj, layout, locale)
            obj.clientSideKeyboardLayout = layout;
            obj.clientSideLocale = locale;
        end
        
        % the front-end will send suggestedLayout and locale when it loads
        % back-end should update the layout based on this priority:
        % pref > suggestedLayout > locale based
        % this function should only run once per session
        function updateKeyboardLayout(obj)
            if ~obj.NeedToUpdateKeyboardLayout
                return;
            end
            obj.NeedToUpdateKeyboardLayout = false;

            % preference is the top priority
            if ispref(obj.PrefGroup, obj.PrefName)
                layout = getpref(obj.PrefGroup, obj.PrefName);
                obj.setLayout(layout);
                obj.NeedToNotify = false;
                return;
            end
                

            % use the detected layout from front-end
            if ~isempty(obj.clientSideKeyboardLayout) 
                % if valid layout detected, set it;
                % if the layout is unknown,it could be dvorak, colemark or
                % other keyboard that is not qwerty, awerty or qwertz, 
                % we need to ask user to pick
                if ~strcmp(obj.clientSideKeyboardLayout, obj.Unknown)
                    obj.setLayout(obj.clientSideKeyboardLayout);
                    obj.NeedToNotify = false;
                end
                
                return;
            end
            
            
            % locale based suggestion for qwerty keyboard
            if ~isempty(obj.clientSideLocale)
                lInstance = simulink.online.internal.keyboard.Locale.instance;
                lInstance.set(obj.clientSideLocale);
    
                % supported by default
                if lInstance.isDefaultSupported()
                    obj.NeedToNotify = false;
                else
                    % have suggestion, but still ask user to choose
                    layout = lInstance.getLayout();
                    if ~isempty(layout)
                        obj.setLayout(layout)
                    end
                end
            end
        end

        % listener for first model open
        function handleFirstModelOpen(obj, ~, ~) 
            % update the layout
            obj.updateKeyboardLayout();
            
            % Popout the keyboard settings dialog if necessary
            if obj.NeedToNotify == false
                return;
            end

            obj.openSettings();
            obj.NeedToNotify = false;
        end

        % Popout the keyboard settings dialog for a given studio
        function openSettings(~, varargin)
            if nargin == 1
                studios = DAS.Studio.getAllStudiosSortedByMostRecentlyActive;
                if isempty(studios)
                    return;
                else
                    studio = studios(1);
                end
            else
                studio = varargin{1};
            end
            title = studio.getStudioTitle;
            toolbarGeo = slonline.getWidgetRectToWindow(title, 'slCandyBar', 'toolBar');
            winId = slonline.getWindowId(title);

            if isempty(winId) || ~toolbarGeo(3) || ~toolbarGeo(4)
                return;
            end
            
            layout = slonline.getXKBMapLayout();
            option = slonline.getXKBMapVariant();
            
            geoStruct = struct('x', toolbarGeo(1), 'y', toolbarGeo(2), 'width', toolbarGeo(3), ...
                'height', toolbarGeo(4));
                
            msg = struct('eventType', 'openKeyboardSettings', ...
                'windowTag', winId, ...
                'toolBarGeometry', geoStruct, ...
                'keyboardLayout', layout, ...
                'keyboardOption', option);
            message.publish('/web/slonlineContainer', msg);
        end
    end

    methods(Hidden = true)
        % Access by test only
        % TODO: understand if this can be called inside a tester in the
        % MOFULLSTACK case
        function listenToFirstModelEvent(obj, value)
            if isempty(obj.FirstModelListener)
                warning('First model listener is not initialized yet');
                return;
            end

            if value
                obj.FirstModelListener.Enabled = true;
            else
                obj.FirstModelListener.Enabled = false;
            end
        end
    end

    methods(Access=private)
        function setLayout(~, layout)
            % update xkbmap without change preference
            xkbParams = split(layout, '.');
            slonline.setXKBMap(xkbParams{:});
        end
    end
end