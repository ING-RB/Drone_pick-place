classdef BrowserControllerFactory < handle
    % BrowserControllerFactory An object capable of launching a web browser
    %
    % BrowserControllerFactory is an enumerated class offering a finite set of
    % browsers
    %
    % - CEF
    % - Chrome
    % - None
    %
    % Example : Launch a web page with CEF
    %
    %   BrowserControllerFactory = appdesservices.internal.peermodel.BrowserControllerFactory.CEF
    %   BrowserControllerFactory.launch('www.mathworks.com');
    
    %   Copyright 2015 - 2022 The MathWorks, Inc.
    
    properties(Access = 'private')
        
        CallbackMethod
    end
    
    methods (Access=private)
        % Private Constructor since this class is scoped to enumerated use
        function obj = BrowserControllerFactory(callbackMethod)
            obj.CallbackMethod = callbackMethod;
        end
    end
    
    enumeration
        % Chromium Embedded Framework
        CEF(@appdesservices.internal.peermodel.BrowserControllerFactory.launchWebwindow);
        
        % Chrome
        Chrome(@appdesservices.internal.peermodel.BrowserControllerFactory.launchChrome);
        
        % MATLAB Online
        MATLABOnline(@appdesservices.internal.peermodel.BrowserControllerFactory.launchMATLABOnline);        
        
        % System
        System(@appdesservices.internal.peermodel.BrowserControllerFactory.launchSystem);        
        
        % No browser
        None(@appdesservices.internal.peermodel.BrowserControllerFactory.launchNoBrowser);
    end
    
    
    methods
        function browserController = launch(obj, varargin)
            % launch() has the following signature:
            %
            %   launch(obj, options)
            %
            %   where options is specified as a pvPair array or struct
            %   (any format inputParser can handle)
            %
            %  'url'      - absolute path to the initial address for the Browser
            %
            %  'size'     - A 2 element vector, [width height], controlling where
            %               the Browser's window's size.
            %
            %  'location' - A 2 element vector, [x, y], controlling the Browser
            %               window's position on screen
            %
            %  'title'    - A string to control the window's Title
            %
            %  'debuggingport' - An integer for a port to open the remote debugging
            %                    tools
            %
            %  'windowstate' - A string to control the window's state:
            %                  "Normal|Maximized"
            %
            %  'Visible' - A logical for if the browser should launch
            %              visible
            %
            % Outputs:
            %
            %   browserCleanup  - An onCleanup object which when deleted...
            %                     will stop the browser
            
            % Create browser controller which will launch the browser
            browserController = obj.CallbackMethod(varargin{:});
            browserController.start();
        end
    end
    
    methods(Static, Access=private)
        
        function browserController = launchWebwindow(varargin)
            % Create WebWindowController which will launch webwindow
            varargin{1}.WebWindowClassName = 'matlab.internal.webwindow';
            % Manually enable zoom for CEF window only, this can be commonized in the future when MATLAB online webwindow shadow handles zoom
            varargin{1}.WebWindowPVPairs = {'EnableZoom', true};
            browserController = appdesservices.internal.browser.WebWindowController(varargin{:});
        end
        
        function browserController = launchMATLABOnline(varargin)
            % Create MATLABOnlineController which will launch popup window
            % in browser for MATLAB Online

            % When ready, will need to create a web window controller with
            % this syntax:             
            
            varargin{1}.WebWindowClassName = 'matlab.internal.webwindow';
            varargin{1}.WebWindowPVPairs = {'WindowContainer', 'Tabbed'};
            browserController = appdesservices.internal.browser.WebWindowController(varargin{:});                        
        end
        
        function browserController = launchChrome(varargin)
            % Create ChromeController which will launch Chrome
            browserController = appdesservices.internal.browser.ChromeController(varargin{:});
        end                
        
          function browserController = launchSystem(varargin)
            % Create ChromeController which will launch Chrome
            browserController = appdesservices.internal.browser.SystemController(varargin{:});
        end    
        
        function browserController = launchNoBrowser(varargin)
            % This creates NoneBrowserController
            browserController = appdesservices.internal.browser.NoBrowserController(varargin{:});
        end
        
    end
    
end
