classdef webwindowmanager < handle
%webwindowmanager keeps track of number of webwindows created using
%CEF (Chromium Embedded Framework)component

%Copyright 2014-2024 The MathWorks, Inc.

    methods(Access=private)
        function newObj = webwindowmanager()
            newObj.BrowserRunningInProc = false;
            newObj.BrowserRunningExtProc = false;
            newObj.DebugPortExtProc = 0;
            newObj.DebugPortInProc = 0;
            newObj.ProxyCredentials = [];
            newObj.StartupOptions = [];
            newObj.CurrentBrowserStartupOptions = [];
            newObj.InterfaceObject = matlab.internal.WebwindowManagerInterface;
            if getenv('MW_CEF_ENABLE_BINARY_TRANSPORT') ~= "0"
                newObj.InterfaceObject.initializeTransport();
                newObj.TransportInitialized = true;
            else
                newObj.TransportInitialized = false;
            end
            newObj.StartupOptions = '';
        end

    end

    methods(Static)
        function obj = instance()
            persistent uniqueInstance;
            if isempty(uniqueInstance)
                obj = matlab.internal.cef.webwindowmanager();
                uniqueInstance = obj;
            else
                obj = uniqueInstance;
            end
        end
    end

    properties( SetAccess = private, GetAccess = public )

        windowList= matlab.internal.cef.webwindow.empty();

        windowListInProc= matlab.internal.cef.webwindow.empty();

        % "StartupOptions" displays what options that user has passed to the browser process.
        % User can pass various startup options to the browser.
        % All the options that can be passed are in this link http://peter.sh/experiments/chromium-command-line-switches/
        % This property does not get cleared when the browser is closed. It retains
        % the value for the current MATLAB session. User can manually
        % overwrite it or clear it. To view all the browser options on a currently running
        % browser use getCurrentStartupOptions() method.
        StartupOptions

    end

    properties( SetAccess = private, GetAccess = private )

        BrowserRunningExtProc

        BrowserRunningInProc

        DebugPortExtProc

        DebugPortInProc

        % The stores the credentials for authenticated proxy server.
        % User can set the credentials using setProxyCredentials() method
        % before the first webwindow is launched.
        % The format of ProxyCredentials should be in username:password
        ProxyCredentials

        % This property stores all the options passed to the browser process
        CurrentBrowserStartupOptions

        % Store the object that holds the interface to the C++ implementation
        % of the webwindowmanager
        InterfaceObject

        % Indicator if Catapult transport has been initialized

        TransportInitialized
    end


    methods (Access={?matlab.internal.webwindowmanager, ?matlab.internal.webwindow, ?matlab.internal.cef.webwindow})

        function requiredOptions = requiredStartupOptions(obj, mode)
            requiredOptions = [];
            if ~obj.isBrowserRunning(mode)

                requiredOptions = [ '-from-webwindow' ' ' ...
                                    '-custom-close-listener-enable=1' ' ' ...
                                    '-processid=',int2str(int32(feature('getpid')))
                                  ];
            end
        end

        function startupOptions = buildDefaultStartupOptions(obj, mode)
            startupOptions = [];
            if ~obj.isBrowserRunning(mode)
                startupOptions = [  '-log-severity=disable'  ];

                % Append any StartupOptions set by user in the end
                % which over-rides the previous options
                if char(obj.StartupOptions)
                    startupOptions = [startupOptions ' ' obj.StartupOptions];
                end
                % DebugPort must be set at the end to over-write the
                % debugport set earlier as it can be set
                % using setStartupOptions()
                if obj.DebugPortExtProc && strcmp(mode,'ExternalProcess')
                    startupOptions = [startupOptions ' ' '-remote-debugging-port=',int2str(obj.DebugPortExtProc)];
                else
                    if obj.DebugPortInProc && strcmp(mode,'InProcess')
                        startupOptions = [startupOptions ' ' '-remote-debugging-port=',int2str(obj.DebugPortInProc)];
                    end
                end

                if (computer('arch') == "glnxa64")
                    % On Linux, DPI configurations are managed by a MATLAB setting. Since
                    % MATLABWindow doesn't have access to MATLAB settings, get them here
                    % and pass them along.
                    settingsGroup = matlab.settings.internal.settings;
                    desktopSettings = settingsGroup.matlab.desktop;
                    if (desktopSettings.hasSetting('DisplayScaleFactor'))
                        displayScaleFactorSetting = desktopSettings.DisplayScaleFactor;
                        if (displayScaleFactorSetting.hasActiveValue && displayScaleFactorSetting.ActiveValue ~= 1)
                            startupOptions = [startupOptions ' ' '--force-device-scale-factor=' num2str(displayScaleFactorSetting.ActiveValue)];
                        end
                    end
                end

                if ~isdeployed
                    startupOptions = [startupOptions ' ' '--from-matlab'];
                end

                % Update the StartupOptions value in windowmanager
                obj.CurrentBrowserStartupOptions = startupOptions;
            end

        end

        function credentials = readProxyCredentials(obj)
            credentials = []; %#ok<NASGU>
            if char(obj.ProxyCredentials)
                credentials = obj.ProxyCredentials;
            else
                wmi = matlab.internal.WebwindowManagerInterface();
                credentials = wmi.queryProxyCredentials();
            end
        end

        function resetAllExtProcBrowser(obj)
            obj.BrowserRunningExtProc = false;
            obj.DebugPortExtProc = 0;
            obj.ProxyCredentials = [];
            obj.CurrentBrowserStartupOptions = [];
            %obj.windowList= matlab.internal.webwindow.empty();
        end

        function setBrowserRunStatus(obj, mode, isRunning)
            if strcmp (mode,'InProcess')
                obj.BrowserRunningInProc = isRunning;
            else
                obj.BrowserRunningExtProc = isRunning;
            end
        end

        function setDebugPort(obj, port)
            obj.DebugPortExtProc = port;
            if ~obj.isBrowserRunning('InProcess')
                %obj.DebugPortInProc = obj.InterfaceObject.DebugPort;
                obj.DebugPortInProc = port;
            end
        end

        function registerWindow(obj,value)
            if strcmp(value.BrowserMode,'ExternalProcess')
                obj.windowList(end+1)=value;
            else
                obj.windowListInProc(end+1)=value;
            end

            % Lock the file to prevent warning messages being displayed when
            % clear classes is called.
            mlock;
        end

        function deregisterWindow(obj,value)
            if isvalid(obj) && ~isempty(obj.windowList) && strcmp(value.BrowserMode,'ExternalProcess')
                obj.windowList(obj.windowList == value) = [];

                % If the window list is empty, we no longer need to lock the
                % instance.
                if isempty(obj.windowList)
                    munlock;
                end
            else
                if isvalid(obj) && ~isempty(obj.windowListInProc) && strcmp(value.BrowserMode,'InProcess')
                    obj.windowListInProc(obj.windowListInProc == value) = [];

                    % If the window list is empty, we no longer need to lock the
                    % instance.
                    if isempty(obj.windowListInProc)
                        munlock;
                    end
                end
            end
        end
    end

    % Public methods
    methods
        % Get all startupOptions for the current running browser
        function allOptions = getCurrentStartupOptions(obj)
            allOptions = obj.CurrentBrowserStartupOptions;
        end
        % Gets all the webwindow handle
        function list = findAllWebwindows(obj)
            list= obj.windowList;
        end

        function setProxyCredentials(obj, proxyUser)

            narginchk(1, 2);
            validateattributes(proxyUser,{'char'},{'nrows',1});
            if obj.BrowserRunning
                % Display warning to let user know that proxy setting
                % will be ignored as browser is already running
                warning(message('cefclient:webwindow:ProxyWillBeIgnored'));
            end

            if char (proxyUser)
                obj.ProxyCredentials = proxyUser;
            end
        end

        function setStartupOptions(obj,mode, configOptions)
        % If browser is already running display error
            if obj.isBrowserRunning(mode)
                warning(message('cefclient:webwindow:StartupOptionsIgnored'));
            end

            if contains(configOptions,'remote-debugging-port')
                error(message('cefclient:webwindow:DebugportInStartupOptions'));
            end

            obj.StartupOptions = char(configOptions);
        end

        function value = isBrowserRunning(obj,mode)
            if strcmp(mode,'InProcess')
                value = obj.BrowserRunningInProc;
            else
                value = obj.BrowserRunningExtProc;
            end
        end

        function value = DebugPort(obj,varargin)
            if obj.InterfaceObject.DebugPort ~= 0
                % If the debug port has been set by the startup
                % plugin, use that value by default.
                value = obj.InterfaceObject.DebugPort;
                return;
            end
            p = inputParser;
            addParameter(p,'BrowserMode','ExternalProcess',@ischar);
            p.parse(varargin{:});
            % If there are no arguments return DebugPort for external
            % process as it's the default.
            if isempty(varargin)
                value = obj.DebugPortExtProc;
            else
                if strcmp(p.Results.BrowserMode,'InProcess')
                    value = obj.DebugPortInProc;
                else
                    value = obj.DebugPortExtProc;
                end
            end
        end

        function value = getOpenPort(obj)
        % Return the next openport from the OpenPortFinder
            value = obj.InterfaceObject.getOpenPort;
        end
    end

    methods (Access = private)

        function delete(obj)
            if obj.TransportInitialized
                obj.InterfaceObject.terminateTransport();
            end
        end

    end


end
