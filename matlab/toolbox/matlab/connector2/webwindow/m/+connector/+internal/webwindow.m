classdef webwindow < handle

    properties ( Access = public )
        URL     

        % Icon - A string specifying the icon path.
        Icon

        % Position - A 4x1 array of [ x y width height ] specifying the
        % size and location of the window.
        Position

        % OuterPosition - A 4x1 array of [x y width
        % height] specifying the size and location of the
        % window including the OS-level chrome such as the
        % title bar.
        OuterPosition

        ZoomLevel

        % This callback is fired when the webwindow is attempted to be closed
        % by a user. If the CustomWindowClosingCallback is defined, the webwindow
        % will not be automatically closed and the responsibility of
        % actually closing the webwindow or not will be on the listener.
        CustomWindowClosingCallback

        % This callback is fired when the webwindow is resized by a user. 
        CustomWindowResizingCallback

        WindowResizing 

        WindowResized 

        FocusGained

        FocusLost

        % This callback is fired when a file is downloaded. 
        % The eventData is a structure with two string 
        % values "DownloadStatus" and "DownloadFilepath"
        % "DownloadStatus" will let user know the 
        % status i.e "downloadStarting/downloadFinished/downloadCancelled"
        % "DownloadFilepath" is the full file path of the downloaded file
        % including the file name
        DownloadCallback

        % This callback is fired when the url load is finished.
        PageLoadFinishedCallback

        % This callback is fired when MATLAB is closing. If a value is
        % specified, webwindow will veto MATLAB closing and then fire the
        % callback. It is up to the client to then decide if MATLAB exit
        % should continue and call exit if necessary
        MATLABClosingCallback

        % This callback is fired when the MATLABWindow process has exited
        % unexpectedly.
        MATLABWindowExitedCallback

        PopUpWindowCallback

        WindowStateCallback

        ZoomCallback

        FileDragDropCallback

        PageRefreshCallback

        Tag (1,1) string = ""

        % Title - A string specifying the title of the launched window.
        Title = ''

        WebWindowChannel
    end

    properties ( SetAccess = private, GetAccess = public, Transient )
        
        % RemoteDebuggingPort - A port that can be used for debugging. This
        % can be specified during construction, otherwise a default is
        % chosen.
        RemoteDebuggingPort = 0;
        
        % CEFVersion - Chromium Embedded Framework Version being used by
        % this webwindow.
        CEFVersion
        
        % ChromiumVersion - Chromium Version being used by this webwindow.
        ChromiumVersion

        % CurrentURL - Returns the currently loaded URL for the top-level frame
        % of the window
        CurrentURL
    end

    % should this be private
    properties( Access = private )
        minimized

        maximized
    end

    properties ( SetAccess = private, GetAccess = public )
        % Bool indicating if the window is valid.
        isWindowValid
        
        isDownloadingFile
        
        isModal
        
        isWindowActive
        
        isAlwaysOnTop
        
        isAllActive
        
        isResizable
        
        MaxSize
        
        MinSize
        
        windowType

        WindowContainer

        forceSameDomainAsParent
        
        DownloadLocation
        
        Origin
        
        BrowserMode
        
        PersistentCachePath
        
        isZoomEnabled

        isFocused
        
        % Internal ID of the window, used to identify window on browser and
        % manage parent/child relationships
        WinID
        
        isRefreshSupported
    end
    
    properties (SetAccess = {?matlab.internal.webwindow,...
            ?matlab.internal.webwindowmanager}, GetAccess = public )
        Parent = matlab.internal.webwindow.empty
        
        Children = matlab.internal.webwindow.empty
        
    end
    
    properties (Access={?matlab.internal.webwindow,?matlab.internal.webwindowmanager})
        ParentOwnsChild
        interface
    end

    methods
        
        function obj = webwindow( arg, varargin )
            arg = convertStringsToChars(arg);
            [varargin{:}] = convertStringsToChars(varargin{:});

            obj.isWindowValid = false;
            obj.windowType = 'Standard';
            obj.Origin = 'BottomLeft';
            obj.BrowserMode = 'ExternalProcess';
            obj.forceSameDomainAsParent = false;
            obj.isFocused = false;
            obj.minimized = false;
            obj.maximized = false;
            obj.isRefreshSupported = false;

            windowMgr = connector.internal.webwindowmanager.instance();
            % To center on middle 75% of the screen, put left/bottom
            % at one-eigth (0.125) of the width/height and set
            % width/height to be three-fourths (0.75) of the window width/height
            obj.InitialPosition = [windowMgr.defaultPosition(3) * 0.125 ...
                                   windowMgr.defaultPosition(4) * 0.125 ...
                                   windowMgr.defaultPosition(3) * 0.75 ...
                                   windowMgr.defaultPosition(4) * 0.75];
            obj.WindowContainer = windowMgr.defaultWindowContainer;
            % For popUpWindow Callback we send the WinID as arguments in
            % a struct.
            if isstruct(arg)
                windowURL = arg.URL;
                obj.WindowHandle = uint64(arg.WindowHandle);
                % For popUp Window pass the WinID to create a channel between
                % the MATLABWindow and MATLAB
                obj.WinID = int32(arg.WinID);
            else
                % URL
                windowURL = arg;
                
                %create a unique id
                obj.WinID = char(matlab.lang.internal.uuid);
                
                p = inputParser;
                
                if length(varargin) >= 1
                    % If second argument is numeric the arguments are non-PV pair
                    % get the debugPort
                    if nargin >= 2 && isnumeric(varargin{1})
                        narginchk(1, 4);
                        addOptional(p, 'DebugPort', 0 , ...
                                 @(x) validateattributes(x,{'numeric'}, ...
                                 {'size',[1 1]}));
                        % Check if there is Position
                        if nargin >= 3 && isnumeric(varargin{2})
                            addOptional(p, 'Position', obj.InitialPosition, ...
                                @(x) validateattributes(x,{'numeric'}, ...
                                {'size',[1 4]}));
                        else
                            % Set default position
                            addOptional(p, 'Position', obj.InitialPosition);
                        end 
                    else
                        % Parse the property value pair
                        addParameter(p,'Position',obj.InitialPosition, ...
                                @(x) validateattributes(x,{'numeric'}, ...
                                {'size',[1 4]}));
                        addParameter(p,'DebugPort',0, ...
                                 @(x) validateattributes(x,{'numeric'}, ...
                                 {'size',[1 1]}));
                    end

                    % Set default windowType as 'Standard'
                    addParameter(p,'WindowType','Standard',@ischar);
                    addParameter(p,'WindowContainer', obj.WindowContainer, @ischar);
                    addParameter(p,'forceSameDomainAsParent', false, @islogical);
                    addParameter(p,'Origin','BottomLeft',@ischar);
                    addParameter(p,'BrowserMode','ExternalProcess', @ischar);
                    addParameter(p,'WinID', obj.WinID, @ischar);
                    addParameter(p,'Certificate',char(fileread(connector.getCertificateLocation)),@ischar);
                    addParameter(p,'PersistentCache','', @ischar); 
                    addParameter(p,'EnableZoom',false, @islogical);
                    addParameter(p, 'Parent', [], @(x) isscalar(x) && isa(x, 'matlab.internal.webwindow') && isvalid(x) && x.isWindowValid);
                    addParameter(p, 'ParentOwnsChild',true, @islogical);
                    addParameter(p, 'RefreshSupported', false, @islogical);

                    p.parse(varargin{:});
					obj.WinID = p.Results.WinID;
                    obj.windowType = p.Results.WindowType;
                    obj.WindowContainer = p.Results.WindowContainer;
                    obj.forceSameDomainAsParent = p.Results.forceSameDomainAsParent;
                    obj.InitialPosition = p.Results.Position;
                    remoteDebuggingPort = p.Results.DebugPort;
                    obj.Origin = p.Results.Origin;
                    obj.BrowserMode = p.Results.BrowserMode;
                    obj.PersistentCachePath = p.Results.PersistentCache;
                    obj.isZoomEnabled = p.Results.EnableZoom;
                    obj.isRefreshSupported = p.Results.RefreshSupported;
                end
            end
            
            %add the extra item so theres no callback
            s = size(obj.InitialPosition);
            if s(2) ~= 5
                obj.InitialPosition = cat(2, obj.InitialPosition, false);
            end
            
            obj.Position = obj.InitialPosition;
            
            validateattributes(windowURL,{'char'},{'nrows',1});
            
            obj.newURL = windowURL;

            if matlab.internal.feature('WebWindowRefresh') == 2
                obj.isRefreshSupported = true; %% if feature 2, all windows should refresh
            end

            obj.initialize

        end

        function show(obj)

            % Error if window is not valid
            obj.errorOnInValidWindow();

            %convert location to 0 based index and send to window manager
            args.bounds = {};
            args.bounds.x = int32(obj.Position(1) - 1);
            args.bounds.y = int32(obj.Position(2) - 1);
            args.bounds.w = int32(obj.Position(3));
            args.bounds.h = int32(obj.Position(4));   
            args.url = obj.newURL;
            args.title = obj.Title;
            args.modal = obj.isModal;
            args.alwaysOnTop = obj.isAlwaysOnTop;
            args.origin = obj.Origin;

            data = struct('type', 'show', 'args', args);
            obj.publishMessageToManager(data);

            obj.isWindowShown = true;
        end

        function hide(obj)
            % Error if window is not valid
            obj.errorOnInValidWindow()

            data = struct('type', 'hide');
            obj.publishMessageToManager(data);
        end

        function setResizable(obj,newValue)
            % Error if window is not valid
            obj.errorOnInValidWindow()
            
            newValue = logical(newValue);
            
            if strcmp(obj.windowType,'Standard') || strcmp(obj.windowType,'FixedSize')
                
                data = struct('type', 'setResizable');
                data.args.isResizable = newValue;
                obj.publishMessageToManager(data);

                obj.isResizable = newValue;
            else
                error(message('cefclient:webwindow:UnsupportedOpForWindowType'));
            end            

        end

        function setDownloadLocation(obj,newValue)
            connector.internal.webwindowmanager.instance().displayWarning('setDownloadLocation');
        end

        function setMinSize(obj,Size)
            % Error if window is not valid
            obj.errorOnInValidWindow()
            
            validateattributes(Size,{'numeric'},{'nonnegative','size',[1 2]});
            if obj.MaxSize
                if obj.MaxSize(1) < Size(1) || obj.MaxSize(2) < Size(2)
                    error(message('cefclient:webwindow:invalidMinSize'));
                end
            end
            
            updatePosition = false;
            newPosition = obj.Position;
            if (obj.Position(3) < Size(1))
                newPosition(3) = Size(1);
                updatePosition = true;
            end
            
            if (obj.Position(4) < Size(2))
                newPosition(4) = Size(2);
                updatePosition = true;
            end
            
            if updatePosition
                obj.Position = newPosition;
                warning(message('cefclient:webwindow:updatePositionMinSize'));
            end
            
            obj.MinSize = Size;
            
            data = struct('type', 'setMinSize');
            data.args.minSize.w = int32(Size(1));
            data.args.minSize.h = int32(Size(2));
            obj.publishMessageToManager(data);
            
        end   

        function setMaxSize(obj,Size)
            % Error if window is not valid
            obj.errorOnInValidWindow()
            
            validateattributes(Size,{'numeric'},{'nonnegative','size',[1 2]});

            if obj.MinSize
                if obj.MinSize(1) > Size(1) || obj.MinSize(2) > Size(2)
                    error(message('cefclient:webwindow:invalidMaxSize'));
                end
            end
            
            updatePosition = false;
            newPosition = obj.Position;
            if (obj.Position(3) > Size(1))
                newPosition(3) = Size(1);
                updatePosition = true;
            end
            
            if (obj.Position(4) > Size(2))
                newPosition(4) = Size(2);
                updatePosition = true;
            end
            
            if updatePosition
                obj.Position = newPosition;
                warning(message('cefclient:webwindow:updatePositionMaxSize'));
            end
            
            obj.MaxSize = Size;
            
            data = struct('type', 'setMaxSize');
            data.args.maxSize.w = int32(Size(1));
            data.args.maxSize.h = int32(Size(2));
            obj.publishMessageToManager(data);
        end

        function setIsRefreshSupported(obj, val)
            obj.errorOnInValidWindow()

            if islogical(val)
                obj.isRefreshSupported = val;
            end

            data = struct('type', 'setRefreshSupported');
            data.args.isRefreshSupported = obj.isRefreshSupported;
            obj.publishMessageToManager(data);
        end

        function minimize(obj)
            % Error if window is not valid
            obj.errorOnInValidWindow()

            data = struct('type', 'minimize');
            obj.publishMessageToManager(data);
        end

        function maximize(obj)
            % Error if window is not valid
            obj.errorOnInValidWindow()
            
            % Don't maximize if non-resizable.
            if ~obj.isResizable
                if strcmp(obj.windowType,'Standard')
                    error(message('cefclient:webwindow:nonresizable'));
                else
                    error(message('cefclient:webwindow:UnsupportedOpForWindowType'));
                end
            end
            
            data = struct('type', 'maximize');
            obj.publishMessageToManager(data);
        end

        function restore(obj)
            connector.internal.webwindowmanager.instance().displayWarning('restore');
        end 

        function openDevTools(obj)
            connector.internal.webwindowmanager.instance().displayWarning('openDevTools');
        end

        function closeDevTools(obj)
            connector.internal.webwindowmanager.instance().displayWarning('closeDevTools');
        end  

        function state = isFullscreen(obj)
            connector.internal.webwindowmanager.instance().displayWarning('isFullscreen');
            state = false;
        end   


        %needs to be in click event so this doesn't work on most browsers
        function fullscreen(obj)
            % Error if window is not valid
            obj.errorOnInValidWindow()

            % This is supported for only 'Standard' window type.
            % Other window types are non-resizable and utility windows like
            % 'Dialog' or 'NoTitlebar' does not require fullscreen support
            if ~strcmp(obj.windowType, 'Standard')
                error(message('cefclient:webwindow:UnsupportedOpForWindowType'));
            elseif ~obj.isResizable
                error(message('cefclient:webwindow:nonresizable'));
            else
                data = struct('type', 'fullscreen');
                obj.publishMessageToManager(data);
            end
        end
        
        function bringToFront(obj)

            % Error if window is not valid
            obj.errorOnInValidWindow()

            if ~obj.isVisible
                show(obj);
            end

            data = struct('type', 'bringToFront');
            data.args.title = obj.Title;
            obj.publishMessageToManager(data);
        end

        function stopDownload(obj)
            connector.internal.webwindowmanager.instance().displayWarning('bringToFront');
        end
        
        function close(obj)
            if ~obj.isWindowValid
                return;
            end
            obj.isWindowValid = false;
            data = struct('type', 'close');
            obj.publishMessageToManager(data);
            obj.isWindowShown = false;

            delete(obj.CustomEventListener);
            delete(obj.PropertyEventListener);
        end

        function setActivateCurrentWindow(obj,newValue)
            connector.internal.webwindowmanager.instance().displayWarning('setActivateCurrentWindow');
        end

        function setAlwaysOnTop(obj,newValue)
            arguments
                obj (1,1) connector.internal.webwindow
                newValue (1,1) {mustBeA(newValue, 'logical')}
            end

            % Error if window is not valid
            obj.errorOnInValidWindow()

            if ~any(strcmp(obj.WindowContainer,{ 'Floating', 'WebDialog'}))
                % Can only set always on top on floating webwindows
                connector.internal.webwindowmanager.instance().displayWarning('setAlwaysOnTop');
                return;
            end

            if isequal(obj.isAlwaysOnTop, newValue)
                return;
            end
            
            obj.isAlwaysOnTop = newValue;
            
            data = struct('type', 'setAlwaysOnTop');
            data.args.alwaysOnTop = newValue;
            obj.publishMessageToManager(data);
        end

        function value = isWindowActivated(obj)
            value = false;
            connector.internal.webwindowmanager.instance().displayWarning('isWindowActivated');
        end

        function enableDragAndDrop(obj)
            connector.internal.webwindowmanager.instance().displayWarning('enableDragAndDrop');
        end 

        function setActivateAllWindows(obj,newValue)
            connector.internal.webwindowmanager.instance().displayWarning('setActivateAllWindows');
        end

        function value = allWindowActivated(obj)
            connector.internal.webwindowmanager.instance().displayWarning('allWindowActivated');
            value = false;
        end 

        function setWindowAsModal(obj,newValue)
            % Error if window is not valid
            obj.errorOnInValidWindow()
            
            if ~any(strcmp(obj.WindowContainer, { 'Floating', 'Dialog', 'WebDialog'}))
                % Can only set modality on floating / dialog webwindows
                connector.internal.webwindowmanager.instance().displayWarning('setWindowAsModal');
                return;
            end
            if (obj.isWindowShown)
                % Can only set modality before showing window
                connector.internal.webwindowmanager.instance().displayWarning('setWindowAsModal');
            else
                obj.isModal = newValue;
            end
        end

        function value = isWindowModal(obj)
            % Error if window is not valid
            obj.errorOnInValidWindow()

            value = obj.isModal;
        end

        function state = isMaximized(obj)
            state = obj.maximized;
        end
        
        function state = isMinimized(obj)
            state = obj.minimized;
        end

        function state = isVisible(obj)
            state = obj.visible;
        end
        
        function success = printToPDF(obj, filename)
            connector.internal.webwindowmanager.instance().displayWarning('printToPDF');
            success = false;
        end

        function result = executeJS(obj, jsStr, timeout)
            connector.internal.webwindowmanager.instance().displayWarning('executeJS');
            result = '';
        end

        function img = getScreenshot(obj)
            connector.internal.webwindowmanager.instance().displayWarning('getScreenshot');
            img = [];
        end

        function WindowClosingListener(obj)
            if ~isempty(obj.CustomWindowClosingCallback)
                internal.Callback.execute(obj.CustomWindowClosingCallback,obj);
            else
                % Default is to honor what the user tried doing -
                % closing the window by default.
                obj.close();
            end
        end

        function WindowResizedListener(obj, args)
            %if a user manually changes the window size, this listener will
            %be called and will update the Position variable automatically
            obj.Position = [args.x, args.y, args.w, args.h, false];

            if ~isempty(obj.WindowResized)
                internal.Callback.execute(obj.WindowResized,obj);
            end
        end

        function MATLABWindowExitedCallbackListener(obj)
            if ~isempty(obj.MATLABWindowExitedCallback)
                internal.Callback.execute(obj.MATLABWindowExitedCallback,obj);
            end
            windowMgr = connector.internal.webwindowmanager.instance();
            deregisterWindow(windowMgr,obj);
        end

        function FocusLostListener(obj)
            obj.isFocused = false;
            if ~isempty(obj.FocusLost)
                internal.Callback.execute(obj.FocusLost,obj);
            end
        end

        function FocusGainedListener(obj)
            obj.isFocused = true;
            if ~isempty(obj.FocusGained)
                internal.Callback.execute(obj.FocusGained,obj);
            end
        end

        function PageLoadFinishedCallbackListener(obj)
            if ~isempty(obj.PageLoadFinishedCallback)
                internal.Callback.execute(obj.PageLoadFinishedCallback,obj);
            end
        end

        function VisibilityChangedListener(obj, isVisible)
            obj.visible = isVisible;
        end

        function WindowMinimizedListener(obj)
            obj.minimized = true;
        end

        function WindowMaximizedListener(obj)
            obj.maximized = true;
        end
        function WindowRestoredListener(obj)
            obj.minimized = false;
        end
        

    end
    
    methods
        function value = get.isAlwaysOnTop(obj)
            % Error if window is not valid
            obj.errorOnInValidWindow()
            
            value = obj.isAlwaysOnTop;
        end

        function set.ZoomLevel(obj,newValue)
            connector.internal.webwindowmanager.instance().displayWarning('set.ZoomLevel');
        end
        
        function zoom = get.ZoomLevel(obj)
            connector.internal.webwindowmanager.instance().displayWarning('get.ZoomLevel');
            zoom = 0;
        end

        function set.URL(obj,newValue)
            % Error if window is not valid
            obj.errorOnInValidWindow()
            
            newValue = convertStringsToChars(newValue);
            validateattributes(newValue,{'char'},{'2d'});
            
            % Apply connector nonce
            newValue = connector.applyNonce(newValue);
            
            data = struct('type', 'setURL');
            data.args.url = newValue;
            obj.publishMessageToManager(data);
            
            % Change it on webwindow
            obj.newURL = newValue;
        end

        function url = get.URL(obj)
            url = obj.newURL;
        end

        function title = get.Title(obj)
            % Error if window is not valid
            obj.errorOnInValidWindow()
            
            title = obj.Title;
        end

        function set.Title(obj,newValue)
            
            % Error if window is not valid
            obj.errorOnInValidWindow()
            
            newValue = convertStringsToChars(newValue);
            validateattributes(newValue,{'char'},{'2d'});

            if isequal(obj.Title, newValue)  && ~isempty(obj.Title)
                return;
            end
            
            obj.Title = newValue;
            
            data = struct('type', 'setTitle');
            data.args.title = newValue;
            obj.publishMessageToManager(data);
        end

        function set.WebWindowChannel(obj, newVal)
            % Error if window is not valid
            obj.errorOnInValidWindow()

            obj.WebWindowChannel = newVal;
        end

        function wwchannel = get.WebWindowChannel(obj)
            wwchannel = obj.WebWindowChannel;
        end

        function set.Icon(obj,newValue)
            connector.internal.webwindowmanager.instance().displayWarning('set.Icon');
        end

        function set.Position(obj, newPosition)
            
            %newPosition may have an extra element to flag that the window
            %is already aware of the position change so no need to post
            %back to it (otherwise it turns into an infinite loop). Only copy
            %the first four elements.
            obj.Position = [newPosition(1), newPosition(2), newPosition(3), newPosition(4)];

            % MATLAB uses 1-based indices for position, the window manager
            % uses 0-based.
            args.bounds = {};
            args.bounds.x = int32(newPosition(1) - 1);
            args.bounds.y = int32(newPosition(2) - 1);
            args.bounds.w = int32(newPosition(3));
            args.bounds.h = int32(newPosition(4));
            
            %if there is an extra argument, don't post back
            s = size(newPosition);
            if s(2) ~= 5
                data = struct('type', 'setPosition', 'args', args);
                obj.publishMessageToManager(data);
            end
        end

        function set.OuterPosition(obj,newPosition)
            connector.internal.webwindowmanager.instance().displayWarning('set.OuterPosition');
        end

        function set.CustomWindowClosingCallback(obj,newValue)
            if(~internal.Callback.validate(newValue))
                error(message('cefclient:webwindow:invalidCallback'));
            end
            obj.CustomWindowClosingCallback = newValue;
        end

        %this was supposed to be deprecated on the desktop version, so not implementing it
        function set.CustomWindowResizingCallback(obj,newValue)
            if(~internal.Callback.validate(newValue))
                error(message('cefclient:webwindow:invalidCallback'));
            end
            obj.CustomWindowResizingCallback = newValue;
        end

        %not supported
        function set.WindowResizing(obj,newValue)
            if(~internal.Callback.validate(newValue))
                error(message('cefclient:webwindow:invalidCallback'));
            end
            obj.WindowResizing = newValue;
        end

        function set.WindowResized(obj,newValue)
            if(~internal.Callback.validate(newValue))
                error(message('cefclient:webwindow:invalidCallback'));
            end
            obj.WindowResized = newValue;
        end
        
        function set.FocusGained(obj,newValue)
            if(~internal.Callback.validate(newValue))
                error(message('cefclient:webwindow:invalidCallback'));
            end
            obj.FocusGained = newValue;
        end
        
        function set.FocusLost(obj,newValue)
            if(~internal.Callback.validate(newValue))
                error(message('cefclient:webwindow:invalidCallback'));
            end
            obj.FocusLost = newValue;
        end
        
        %not supported
        function set.DownloadCallback(obj,newValue)
            if(~internal.Callback.validate(newValue))
                error(message('cefclient:webwindow:invalidCallback'));
            end
            obj.DownloadCallback = newValue;
        end
        
        function set.PageLoadFinishedCallback(obj,newValue)
            if(~internal.Callback.validate(newValue))
                error(message('cefclient:webwindow:invalidCallback'));
            end
            obj.PageLoadFinishedCallback = newValue;
        end
        
        %not supported
        function set.PopUpWindowCallback(obj,newValue)
            if(~internal.Callback.validate(newValue))
                error(message('cefclient:webwindow:invalidCallback'));
            end
            obj.PopUpWindowCallback = newValue;
        end
        
        %not supported
        function set.WindowStateCallback(obj,newValue)
            if(~internal.Callback.validate(newValue))
                error(message('cefclient:webwindow:invalidCallback'));
            end
            obj.WindowStateCallback = newValue;
        end
        
        %not supported
        function set.ZoomCallback(obj,newValue)
            if(~internal.Callback.validate(newValue))
                error(message('cefclient:webwindow:invalidCallback'));
            end
            obj.ZoomCallback = newValue;
        end

        function set.MATLABClosingCallback(obj, newValue)
            %stub
        end


        function set.PageRefreshCallback(obj,newValue)
            if(~internal.Callback.validate(newValue))
                error(message('cefclient:webwindow:invalidCallback'));
            end
            obj.PageRefreshCallback = newValue;
        end

        function val = get.PageRefreshCallback(obj)
            val = obj.PageRefreshCallback;
        end
    end
    
    % Internal properties
    properties(Access = 'private', Transient)
        % A asyncio channel that  is used to handle all communication
        % between this MCOS object and cefclient C++ interface.
        Channel
        
        % Custom event listener for any custom event from asyncio channel.
        CustomEventListener
        
        PropertyEventListener
        
        InitialPosition = [ 100 100 600 400 false];
        
        UpdatedPosition
        
        newURL
        
        % Handle of the new window that was created.
        WindowHandle
        
        % Cached position to be used when running callbacks
        CachedPosition
        
        % Store the last event data used for a resize event so that we can
        % filter out duplicate events.
        LastResizeEvent
        
        % Indicate if we are potentially in a callback so that we don't try
        % to recurse into execute
        InCallback

        visible = false

        isWindowShown = false
    end

    methods(Access='private')

        function initialize(obj)
            
            obj.isWindowValid = true;
            obj.isDownloadingFile = false;
            obj.isModal = false;
            obj.isWindowActive=true;
            obj.isAlwaysOnTop = false;
            obj.isAllActive=true;
            obj.InCallback = false;
            obj.CachedPosition = obj.InitialPosition;
            obj.LastResizeEvent = [];
            
            windowMgr = connector.internal.webwindowmanager.instance();
            registerWindow(windowMgr,obj);

            if strcmp(obj.windowType,'Standard') || strcmp(obj.windowType,'Dialog')
                obj.isResizable = true;
            else
                obj.isResizable = false;
            end
            
            lock(obj);
            
        end

        function lock(~)
            %mlock;
        end
        
        function unlock(obj)
            openWindows = findAllWebwindows(obj);
            if isempty(openWindows)
                %munlock;
            end
        end

        %route all instructions to the window through the window manager
        function publishMessageToManager(obj, data)
            data.args.winId = obj.WinID;
            data.WindowContainer = obj.WindowContainer;
            data.forceSameDomainAsParent = obj.forceSameDomainAsParent;
            windowMgr = connector.internal.webwindowmanager.instance();

            % get channel for window
            channel = obj.WebWindowChannel;

            windowMgr.publishMessage(channel, data);
        end

        function errorOnInValidWindow(obj)
            if ~obj.isWindowValid
                error(message('cefclient:webwindow:invalidWindow'));
            end
        end
   
    end

    methods

        function delete(obj)
            close(obj);
            unlock(obj);
            delete(obj.Channel);
            windowMgr = connector.internal.webwindowmanager.instance();  
            deregisterWindow(windowMgr,obj);
        end
        
        function list = findAllWebwindows(~)
            list= connector.internal.webwindowmanager.instance().windowList;
        end
    end 
end
