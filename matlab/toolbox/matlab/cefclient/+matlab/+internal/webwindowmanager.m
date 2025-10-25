classdef webwindowmanager < handle
%webwindowmanager keeps track of number of webwindows created

% Copyright 2014-2024 The MathWorks, Inc.

    properties( SetAccess = private, GetAccess = public, Dependent )

        windowList;

        windowListInProc;

        % "StartupOptions" displays what options that user has passed to the browser process.
        % User can pass various startup options to the browser.
        % All the options that can be passed are in this link http://peter.sh/experiments/chromium-command-line-switches/
        % This property does not get cleared when the browser is closed. It retains
        % the value for the current MATLAB session. User can manually
        % overwrite it or clear it. To view all the browser options on a currently running
        % browser use getCurrentStartupOptions() method.
        StartupOptions
    end

    methods(Static)
        function obj = instance()
            persistent uniqueInstance;
            if isempty(uniqueInstance)
                obj = matlab.internal.webwindowmanager();
                uniqueInstance = obj;
            else
                obj = uniqueInstance;
            end
        end

        function out = provider(~)
            import matlab.internal.capability.Capability;
            Capability.require(Capability.WebWindow);
            useLocal = Capability.isSupported(Capability.LocalClient) && ...
                ~connector.internal.Worker.isMATLABOnline;
            if useLocal
                out = 'cef';
            else
                out = 'remote';
            end
        end
    end

    methods (Hidden=true)
        function requiredOptions = requiredStartupOptions(~, mode)
            requiredOptions = requiredStartupOptions(matlab.internal.cef.webwindowmanager.instance, mode);
        end

        function startupOptions = buildDefaultStartupOptions(~, mode)
            startupOptions = buildDefaultStartupOptions(matlab.internal.cef.webwindowmanager.instance, mode);
        end

        function credentials = readProxyCredentials(~)
            credentials = readProxyCredentials(matlab.internal.cef.webwindowmanager.instance);
        end

        function resetAllExtProcBrowser(~)
            resetAllExtProcBrowser(matlab.internal.cef.webwindowmanager.instance);
        end

        function setBrowserRunStatus(~, mode, isRunning)
            setBrowserRunStatus(matlab.internal.cef.webwindowmanager.instance, mode, isRunning);
        end

        function setDebugPort(~, port)
            setDebugPort(matlab.internal.cef.webwindowmanager.instance, port);
        end

    end

    methods
        function allOptions = getCurrentStartupOptions(~)
            allOptions = getCurrentStartupOptions(matlab.internal.cef.webwindowmanager.instance);
        end

        function list = findAllWebwindows(obj)
            list = obj.windowList;
        end

        function setProxyCredentials(~, proxyUser)
            setProxyCredentials(matlab.internal.cef.webwindowmanager.instance, proxyUser);
        end

        function setStartupOptions(~, mode, configOptions)
            setStartupOptions(matlab.internal.cef.webwindowmanager.instance, mode, configOptions);
        end

        function value = isBrowserRunning(~, mode)
            value = isBrowserRunning(matlab.internal.cef.webwindowmanager.instance, mode);
        end
        function value = DebugPort(~, varargin)
            value = DebugPort(matlab.internal.cef.webwindowmanager.instance, varargin{:});
        end

        function value = getOpenPort(~)
            value = getOpenPort(matlab.internal.cef.webwindowmanager.instance);
        end

        function val = get.windowList(~)
            idx = 1;
            val = matlab.internal.webwindow.empty();

            implList = matlab.internal.cef.webwindowmanager.instance.windowList;
            for i = 1:numel(implList)
                if ~isempty(implList(i).interface)
                    val(idx) = implList(i).interface;
                    idx = idx + 1;
                end
            end

            if exist('connector.internal.webwindowmanager','class')
                implList = connector.internal.webwindowmanager.instance.windowList;
                for i = 1:numel(implList)
                    if ~isempty(implList(i).interface)
                        val(idx) = implList(i).interface;
                        idx = idx + 1;
                    end
                end
            end
        end

        function val = get.windowListInProc(~)
            val = matlab.internal.webwindow.empty();
            implList = matlab.internal.cef.webwindowmanager.instance.windowListInProc;
            for i = 1:numel(implList)
                val(i) = implList(i).interface;
            end
        end

        function val = get.StartupOptions(~)
            val = matlab.internal.cef.webwindowmanager.instance.StartupOptions;
        end

    end

    methods (Access=private)
        function delete(~)
        % Don't need to do anything here. This is just to prevent manual
        % deletion of the object.
        end
    end

end
