classdef View < handle
    % Launcher class for MATLAB Test Shared Run Tests Settings Dialog UI.

    %   Copyright 2022 The MathWorks, Inc.

    properties (SetAccess=private)
        Browser (1,1) {mustBeA(Browser, ["matlab.internal.webwindow", "missing"])} = missing;
    end

    properties (Constant, Hidden)
        TITLE = message("MATLAB:testbrowser:TestSettings:RunTestsSettings").getString();
    end

    properties
        Debug (1,1) logical = false;
        UseDebugPort (1,1) logical = false;
    end

    methods
        function [view, url] = View(options)
            arguments
                options.Browser {mustBeMember(options.Browser, ["webwindow", "system", "none"])} = "webwindow";
                options.Debug (1,1) logical = false;
                options.UseDebugPort (1,1) logical = false;
            end

            % create or get the singleton
            if isempty(instance("get"))
                instance("set", view);
            else
                view = instance("get");
            end

            view.Debug = options.Debug;
            view.UseDebugPort = options.UseDebugPort;

            % close the existing browser if requesting a different one
            if ~ismissing(view.Browser) && (options.Browser == "system" || options.Browser == "none")
                view.close();
            end

            url = view.makeURL();

            switch options.Browser
                % webwindow is the production version for singleton UI.
                % Open in System default opt. is given for debugging
                % purposes.
                case "webwindow"
                    view.launchWebWindow();
                case "system"
                    web(url, "-browser");
                case "none"
                    return;
            end
        end

        function close(view)
            if ~ismissing(view.Browser)
                if view.Browser.isvalid()
                    view.Browser.close();
                end
                view.Browser = missing;
            end
        end

        function delete(view)
            view.close();
            if isequal(view, instance("get")) % deleting the singleton
                instance("set", matlab.unittest.internal.runtestssettings.View.empty);
            end
        end
    end

    methods (Access=private)
        function launchWebWindow(view)
            % reuse the existing webwindow if it is still valid
            if isa(view.Browser, "matlab.internal.webwindow") && isvalid(view.Browser) && view.Browser.isWindowValid()
                % reload & bring to front
                view.Browser.URL = view.makeURL();
                view.Browser.bringToFront();
            else
                args = { view.makeURL() };
                if view.UseDebugPort
                    args{end+1} = matlab.internal.getDebugPort();
                end
                args = [args { 'Position', matlab.unittest.internal.runtestssettings.View.findCentrePosition() }];
                view.Browser = matlab.internal.webwindow(args{:});
                view.Browser.Title = view.TITLE;
                view.Browser.setResizable(false);
                view.Browser.show();
            end

            if view.Debug
                view.Browser.executeJS("cefclient.sendMessage('openDevTools')");
            else
                view.Browser.executeJS("cefclient.sendMessage('closeDevTools')");
            end
        end

        function url = makeURL(view)
            if view.Debug
                index = "index-debug.html";
            else
                index = "index.html";
            end
            url = connector.getUrl("toolbox/matlab/testframework/shared/testbrowser/runtestssettings/" + index);
        end
    end

    methods(Static, Access = private)
        function position = findCentrePosition()
            % find the screen where the mouse cursor is located
            pointer = get(0, 'PointerLocation');
            screens = get(0, 'MonitorPositions');
            target = screens(1, :); % default to screen 1
            for screen=screens'
                if pointer(1) >= screen(1) && pointer(1) < screen(1) + screen(3) ...
                        && pointer(2) >= screen(2) && pointer(2) < screen(2) + screen(4)
                    target = screen';
                    break;
                end
            end

            % center window on target screen
            winSize = [650 385];
            position = target(1:2) + target(3:4)/2 - winSize/2;
            position = [position winSize];
        end
    end

    methods(Static, Access = public)
        function closeBeforeRun()
            view = instance("get");
            if ~isempty(view)
                view.close();
            end
        end
    end
end

function out = instance(op, in)
    persistent inst;
    switch op
        case "get"
            out = inst;
        case "set"
            if isempty(in)
                munlock();
            else
                mlock();
            end
            inst = in;
    end
end


