classdef AbstractBrowserController < handle
    % ABSTRACTBROWSERCONTROLLER Base class for browser controller    
    
    %    Copyright 2015-2023 The MathWorks, Inc.
    
    properties (Access = public)
        % Callbacked fired when the client side has loaded, and this
        % browser is capable of communicating with it
        WindowStartedCallback
        
        % Callback fired when the browser is attempted to be closed
        % by a user.  
        %
        % The browser will not actually be closed, and it is
        % the Callback's responsibility to prompt the user if needed, and
        % eventually close the browser.
        %
        % This callback may not be supported by all browsers, and may
        % result in never being triggered.
        UserCloseRequestCallback        
        
        % Callback fired when MATLAB is attempted to be closed by MATLAB
        % being closed.
        %
        % The browser will not actually be closed, and it is
        % the Callback's responsibility to prompt the user if needed, and
        % eventually close the browser and exit MATLAB.
        %
        % This callback may not be supported by all browsers, and may
        % result in never being triggered.
        MATLABCloseRequestCallback             
        
        % Callback fired when window is completely closed.
        %
        % This event is fired for all ways the browser was closed (user,
        % MATLAB, etc..)
        WindowClosedCallback

        % Callback fired when window closing is cancelled by users from client side.
        %
        CancelClosingCallback
        
        % Callback fired when window exits as a result of window crashed
        %
        % The window is already closed, and cliends should do the best they
        % can to clean up
        WindowCrashedCallback
    end
    
    properties(Abstract, SetAccess = 'private')
        % Boolean to track if this browser is "valid"        
        %
        % This is to be managed entirely by the subclass.  This class will
        % not do any book keeping, as "being valid" varies across the
        % browser implementation and the environment
        IsBrowserValid
    end
    
    properties(Access = private)
        % Storage for arguments passed in during construction
        StartBrowserArguments
        
        % Message Service subscription ID
        %
        % This ID is needed to unsubscribe (effectively acts like a listener
        % handle)
        SubscriptionId;
    end
    
    properties (Constant, Access = protected)
        % Browser window state
        Normal = 'Normal';
        Maximized = 'Maximized';
        Minimized = 'Minimized';
        
        % Default position to start browser
        DefaultPosition = [100 100 1400 800];
        
        % Message Service Constants
        %
        % Maintain two channels to avoid needing to manage short circuiting
        
        % Channel to send messages from the server to the client
        PUB_CHANNEL =  '/windowstrategy/server';
        
        % Channel to observe messages coming from the client        
        SUB_CHANNEL =  '/windowstrategy/client';
        
        % Event Constants        
        WindowStartedEventName = 'windowStarted';                
        
        WindowRequestToCloseEvent = 'windowRequestToClose';

        MATLABRequestToCloseEvent = 'MATLABRequestToClose';
        
        WindowClosedEventName = 'windowClosed';

        CancelClosingEventName = 'cancelClosing';

        BringToFrontEventName = 'bringToFront';                     

        SetTitleEventName = 'setTitle';
    end
    
    methods(Abstract, Access = protected)
        % startBrowser() requires to be implemented by subclasses to start
        % browser
        startBrowser(obj, browserOptions)
        
        % closeBrowser() must be implemented by subclasses for destroying
        % browser
        closeBrowser(obj)
    end
    
    methods
        function obj = AbstractBrowserController(varargin)            
            % Get the browser starting options
            obj.StartBrowserArguments = obj.parseBrowserOptions(varargin{:});
            
            % Listen to messages from client
            obj.SubscriptionId = message.subscribe(obj.SUB_CHANNEL, @(event) obj.handleMessage(event));                        
        end
        
        function delete(obj)
            message.unsubscribe(obj.SubscriptionId);
            obj.closeBrowser();
        end
        
        function start(obj)
            obj.startBrowser(obj.StartBrowserArguments);
        end                
        
        function bringToFront(obj)
            % no-op by default
        end       

        function setTitle(obj, value)
            % no-op by default
        end
        
        function requestWindowClose(obj)
            % Tells the window to try to close itself
            
            % This will publish an event to client so that client can make
            % the appropriate choice, like closing, asking the user to
            % save, etc...
            event = struct;
            event.name = obj.WindowRequestToCloseEvent;
            message.publish(obj.PUB_CHANNEL, event);
        end

        function requestWindowCloseByExitMATLAB(obj)
            % Tells the window to try to close itself
            
            % This will publish an event to client so that client can make
            % the appropriate choice, like closing, asking the user to
            % save, etc...
            event = struct;
            event.name = obj.MATLABRequestToCloseEvent;
            message.publish(obj.PUB_CHANNEL, event);
        end
        
        function set.UserCloseRequestCallback(obj, callback)
            obj.UserCloseRequestCallback = callback;                        
            
            obj.handleCallbacksSet();
        end
        
        function set.MATLABCloseRequestCallback(obj, callback)
            obj.MATLABCloseRequestCallback = callback;                        
            obj.handleCallbacksSet();
        end                          
    end
    
    methods(Access = 'private')
        function handleMessage(obj, event)            
            % Handles messages from client
            %
            % event is expected to have a 'name' field corresponding to
            % what callback should be executed if not empty                        
            %
            % Note that other callbacks like WindowClosing are done through
            % client / server communication, but by the concrete browser
            % controller implementation itself
            %
            % Ex: webwindow's CustomWindowClosingCallback
            
            switch(event.name)
                
                case obj.WindowStartedEventName
                    
                    if(~isempty(obj.WindowStartedCallback))
                        obj.WindowStartedCallback(obj, [])                        
                    end
                case obj.WindowClosedEventName
                    
                    if(~isempty(obj.WindowClosedCallback))
                        obj.WindowClosedCallback(obj)
                    end
                case obj.CancelClosingEventName
                    if(~isempty(obj.CancelClosingCallback))
                        obj.CancelClosingCallback(obj)
                    end
                case obj.BringToFrontEventName                    
                    obj.bringToFront();

                case obj.SetTitleEventName
                    obj.setTitle(event.value);
            end                        
        end      
    end
    
    methods (Access = protected)
        function browserOptions = parseBrowserOptions(obj, varargin)
            % Parse the input parameters to launch browser
            
            % create default parameters for starting browser
            defaultURL = '';
            defaultPosition = obj.getLastStoredPosition();
            defaultSize = [defaultPosition(3) defaultPosition(4)];
            defaultLocation = [defaultPosition(1) defaultPosition(2)];
            defaultTitle = '';
            defaultWindowState = obj.getLastStoredWindowState();
            
            % Parse optional inputs
            p = inputParser();
            p.CaseSensitive = false;
            p.KeepUnmatched = true;
            
            addParameter(p,'URL', defaultURL);
            addParameter(p,'Size',defaultSize);
            addParameter(p,'Location',defaultLocation);
            addParameter(p,'Title',defaultTitle);
            addParameter(p, 'WindowState', defaultWindowState);
            parse(p,varargin{:});
            
            % Merge matched and unmatched
            %
            % We do this because there are some set of fixed parameters,
            % but there may be some browser specific paramters that we also
            % want to make sure are stored
            browserOptions = p.Results;            
            unmatchedFields = fieldnames(p.Unmatched);
            
            for idx = 1:length(unmatchedFields)
                browserOptions.(unmatchedFields{idx}) = p.Unmatched.(unmatchedFields{idx});
            end                                    
        end
        
        function position = getLastStoredPosition(obj)
            % determine the AppDesigner starting position
            % The subclass can override this method to provide its own
            % position setting
            
            % Default position for AppDesigner
            position = obj.DefaultPosition;
        end
        
        function windowState = getLastStoredWindowState(obj)
            % determine the AppDesigner starting window state: Normal |
            % Maximized | Minimized
            % The subclass can override this method to provide its own
            % state setting
            
            % Default state is Normal
            windowState = obj.Normal;
        end
        
        function handleCallbacksSet(obj)
            % no-op by default
        end                
    end
end

