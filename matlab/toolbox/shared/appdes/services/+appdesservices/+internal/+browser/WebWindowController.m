classdef WebWindowController < appdesservices.internal.browser.AbstractBrowserController
    % WebWindowController Class to start webwindow browser    
    
    %    Copyright 2015-2024 The MathWorks, Inc.
    
    properties (Access = public)
        % WebWindow object
        WebWindow
        
        % Browser position at normal window state for restoring from
        % maximized or minimized window state
        BrowserNormalPosition
        
        % Browser window state: Normal, Maximized, Minimized, by default
        % it is Normal
        BrowserPreviousWindowState

        BrowserVisible = true;
    end    
    
    properties(SetAccess = 'private')
       IsBrowserValid 
    end
    
    methods
        function obj = WebWindowController(varargin)            
            obj = obj@appdesservices.internal.browser.AbstractBrowserController(varargin{:});                        
        end
        
        function bringToFront(obj)
            if obj.BrowserVisible
                obj.WebWindow.bringToFront();
            end
        end
        
        function setTitle(obj, value)
           obj.WebWindow.Title = value;
        end

        function tf = get.IsBrowserValid(obj)
            % Determines if the window is valid
            
            % By default, assume no
            tf = false;            
            
            % If the web window is valid, then defer to asking it
            if ~isempty(obj.WebWindow) && isvalid(obj.WebWindow)            
                tf = obj.WebWindow.isWindowValid;                
            end                                   
        end        
    end
    
    methods (Access = protected)
        
        function startBrowser(obj, browserOptions)
            % Creates the command string to launch webwindow
            %
            % Ex: "cefclient.exe -url=www.mathworks.com ...."
            %
            % The webwindow format for each flag is as follows:
            %
            % URL:
            %
            %   -url=mathworks.com
            %
            % Position:
            %
            %   -position="x,y,width,height"
            %
            % Title:
            %
            %   -title="title"
            %
            %           (quotes needed for titles with white space)
            %         

            if isfield(browserOptions, 'Visible')
                obj.BrowserVisible = browserOptions.Visible;
            end
            
            try
                % Create webwindow object
                % Remote debugging port is generated using the getDebugPort API
                % to find an open port on the local machine. Using this utility
                % disables opening a Remote Debugging port for release
                debugport = matlab.internal.getDebugPort;

                webWindow = feval(browserOptions.WebWindowClassName, ...
                    ... % URL is not passed in as PV Pair perconstructor syntax
                    browserOptions.URL, ...
                    ... % PV Pairs for remaining properties
                    'DebugPort', debugport,...
                    'Position', [browserOptions.Location, browserOptions.Size],...
                    ... % Anything additional for the type of web window
                    browserOptions.WebWindowPVPairs{:} ...
                    );
                
                % Turn on Drag and Drop
                webWindow.enableDragAndDrop();
                
                % Set Title
                webWindow.Title = browserOptions.Title;
                
                % Now make it visible by bringing it to front
                %
                % Bring browser to front first, otherwise maximize() would fail for
                % getting wrong window management information
                if obj.BrowserVisible
                    webWindow.bringToFront();
                    if strcmpi(browserOptions.WindowState, 'Maximized')
                        webWindow.maximize();
                    end
                end
            catch exception
                % Catch exception of webwindow failure to report a readable
                % error message to the user
                error(message('MATLAB:appdesigner:appdesigner:AppDesignerStartFailed', exception.message));
            end
            
            % In order to restore webwindow position and state
            % which are saved since last closing, there are two cases
            % needed to be dealt with that webwindow is closed with 
            % window maximized.                 
            % 1)webwindow closed at window maximized, and next time 
            % webwindow will be launched with window maximized, but 
            % still need to remember the position of last
            % non-minimized/non-maximized window state for handling users
            % pressing 'Restore' button correctly.
            % 2)webwindow is closed at minimized window, but previous 
            % state is probably maximized. And so for closing at minimized 
            % window state, need to remember the state before minimized for restoring.
            %
            % So install a WindowResized to track the
            % position and window state of the webwindow.
            % webwindow has a plan to support PreWindowStateChanged 
            % event, and it would be better to use that event to track 
            % in the future
            webWindow.WindowResized = @(cefobj, event)obj.handleBrowserResizing(event);
            
            % This callback is called when the MATLABWindow process has 
            % exited unexpectedly, like being killed from Task Manager
            webWindow.MATLABWindowExitedCallback = @(cefobj, event)delete(obj);
            
            % Store the webwindow instance
            obj.WebWindow = webWindow;
            
            % Save the postion when browser started as the default value to
            % be stored for next time launching
            obj.BrowserNormalPosition = [browserOptions.Location,...
                browserOptions.Size];
        end        
        
        function closeBrowser(obj)
            % 1) During starting if MATLABWindow failes to open, obj.WebWindow
            % would be empty, and in order to avoid warning during object
            % destruction, need isempty() checking here
            % 2) MATLABWindow process can be killed unexpectedly, like from
            % Task Manager or Linux kill command
            obj.savePositionAndWindowState();

            if ~isempty(obj.WebWindow) && isvalid(obj.WebWindow) && obj.WebWindow.isWindowValid
                % close webwindow
                delete(obj.WebWindow);                
            end                        
        end           
        
        function position = getLastStoredPosition(obj)
            % determine the browser window starting position
            % The subclass can override this method to provide its own
            % position setting
            
            % Get default position for browser from base class method
            position = getLastStoredPosition@appdesservices.internal.browser.AbstractBrowserController(obj);
            isDefaultPosition = true;

            % Get the position saved the last-time the window closed
            s = settings;
            if s.matlab.appdesigner.hasGroup('window')
                node = s.matlab.appdesigner.window;
                if node.hasSetting('Position')
                    position = node.Position.ActiveValue;
                    
                    if ~isequal(position, node.Position.FactoryValue)
                        isDefaultPosition = false;
                    end
                end
            end
            
            % Update the position to make sure the window will be centred
            % in the screen for first time running, and be fully visible in
            % the screen
            position = obj.ensureValidPosition(position, isDefaultPosition);                       
        end
        
        function windowState = getLastStoredWindowState(obj)
            % determine the webwindow browser starting window state: Normal |
            % Maximized | Minimized
            
            % get the default window state from base class
            obj.BrowserPreviousWindowState = getLastStoredWindowState@appdesservices.internal.browser.AbstractBrowserController(obj);

            % If last remembered window state is maximized, then restore to that state
            s = settings;
            if s.matlab.appdesigner.hasGroup('window')
                node = s.matlab.appdesigner.window;
                if node.hasSetting('IsMaximized')
                    if node.IsMaximized.ActiveValue
                        obj.BrowserPreviousWindowState = 'Maximized';
                    else
                        obj.BrowserPreviousWindowState = 'Normal';
                    end
                end
            end

            windowState = obj.BrowserPreviousWindowState;
        end                                       
        
        function handleCallbacksSet(obj)
            obj.WebWindow.CustomWindowClosingCallback = obj.UserCloseRequestCallback;
            obj.WebWindow.MATLABClosingCallback = obj.MATLABCloseRequestCallback;
            obj.WebWindow.MATLABWindowExitedCallback = obj.WindowCrashedCallback;                        
        end                                
    end
    
    methods (Access = private)               
        
        function savePositionAndWindowState(obj)
            % save webwindow browser window position and window state for restoring 
            % while launching next time
            
            if isempty(obj.MATLABCloseRequestCallback)
                % Non-empty closing callback means app was run 
                % using App Designer
                %
                % Only save position and state when it is run from
                % App Designer for restoring next time launching App
                % Designer
                return;
            end

            if ~isempty(obj.WebWindow) && isvalid(obj.WebWindow) && obj.WebWindow.isWindowValid
                position = obj.WebWindow.Position;
                isMaximized = obj.WebWindow.isMaximized();

                if obj.WebWindow.isMinimized() &&...
                        isequal(obj.BrowserPreviousWindowState, obj.Maximized)
                    isMaximized = true;
                end
            else
                position = obj.BrowserNormalPosition;
                isMaximized = isequal(obj.BrowserPreviousWindowState, obj.Maximized);
            end

            if isMaximized
                % Set the position to the normal window state value for
                % doing restoring from maximized window
                % correctly next time launching
                position = obj.BrowserNormalPosition;
            end

            obj.saveSettings(position, isMaximized);
        end

        function saveSettings(obj, position, isMaximized)
            % Update entries in the window subGroup of appdesigner settings
            s = settings;
            if s.matlab.appdesigner.hasGroup('window')
                node = s.matlab.appdesigner.window;
                node.Position.PersonalValue = position;
                node.IsMaximized.PersonalValue = isMaximized;
            end
        end

        function handleBrowserResizing(obj, ~)
            % Track browser window state and position changing for saving
            % which will be used as restoring data to start webwindow browser
            
            % Remember the state before window is minimized for restoring
            % Save the last position when window is not maximized or
            % minimized for restoring from maximized window state next time
            if obj.WebWindow.isMaximized()
                obj.BrowserPreviousWindowState = obj.Maximized;
            elseif obj.WebWindow.isMinimized()
                % no-op because webwindow will not be launched by
                % restoring to minimized window state, but restoring to
                % the state before minimized
            else
                obj.BrowserPreviousWindowState = obj.Normal;
                % Only need to store position at normal window state because
                % it will be used as size and location to restore window
                % from maximized state next time launching
                obj.BrowserNormalPosition = obj.WebWindow.Position;
            end            
        end

        function updatedPosition = ensureValidPosition(obj, position, isDefaultPosition)
            updatedPosition = position;

            if ~isDefaultPosition && appdesservices.internal.windowutil.isPositionWithinAnyScreen(position)
                % Check if the saved position fits into any screen
                % Do not need to do more validationg if saved position fits into any screen
                return;
            end

            % margin for position on screen
            SCREEN_MARGIN = 10;

            % As g3042555 mentioned, pf.display.getConfig().availableScreenSize
            % and getAvailableVirtualGeometry() 
            % would not take 'display scale' setting into account, as a result,
            % the returned value would not be accurate because last saved
            % position from CEF's API is scaling based.
            % Hence, we may see App Designer window being partially out of 
            % screen on scaling screens.

            if isDefaultPosition
                % if its the first time running App Designer then let it center on
                % the screen where MATLAB window is

                screenBounds = appdesservices.internal.windowutil.convertArrayToDisplayRect(...
                    appdesservices.internal.windowutil.getScreenSizeNearestToMATLABCenter());
            else
                 screenBounds = pf.display.getAvailableVirtualGeometry();
            end

            appdesignerScreenPosition = appdesservices.internal.windowutil.convertToScreenPosition(position);

            appdesignerScreenRect = appdesservices.internal.windowutil.convertArrayToDisplayRect(appdesignerScreenPosition);

            if isDefaultPosition
                appdesignerScreenRect = pf.display.getCenterRect(appdesignerScreenRect, screenBounds, SCREEN_MARGIN);
            end

            appdesignerUpdatedScreenRect = pf.display.onScreenRect(appdesignerScreenRect, screenBounds, SCREEN_MARGIN);

            appdesignerUpdatedPosition = appdesservices.internal.windowutil.convertDisplayRectToArray(appdesignerUpdatedScreenRect);
            appdesignerUpdatedPosition = appdesservices.internal.windowutil.adjustOnScreenPosition(appdesignerUpdatedPosition, screenBounds, SCREEN_MARGIN);

            updatedPosition = appdesservices.internal.windowutil.convertToMATLABPosition(appdesignerUpdatedPosition);
        end
    end
end