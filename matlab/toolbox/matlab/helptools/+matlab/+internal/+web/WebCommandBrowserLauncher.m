classdef WebCommandBrowserLauncher < handle
    properties (Constant)
        WebCommandNotifier = matlab.internal.web.WebCommandNotifier
    end

    properties (GetAccess = private, SetAccess = immutable)
        Flags string
        WarnOnSystemError (1,1) logical
    end

    properties (Access = private)
        Location string
        Uri matlab.net.URI = matlab.net.URI.empty
        isHTMLViewer (1,1) logical = matlab.internal.web.WebCommandBrowserLauncher.isHTMLViewerSupported
    end

    properties (SetAccess = private)
        Browser = [];
        Success = false;
        Message message = message.empty;
    end

    properties (Dependent, SetAccess = private)
        LoadUrl string
    end

    methods
        function obj = WebCommandBrowserLauncher(location, flags, warnOnSystemError)
            arguments
                location string;
                flags string = string.empty;
                warnOnSystemError (1,1) logical = false;
            end

            obj.Location = location;
            obj.Flags = flags;
            obj.WarnOnSystemError = warnOnSystemError;
        end

        function f = hasFlag(obj, flagName)
            if ~startsWith(flagName, "-")
                flagName = "-" + flagName;
            end
            f = any(obj.Flags == flagName);
        end

        function url = get.LoadUrl(obj)
            if isempty(obj.Uri)
                url = obj.Location;
            else
                url = string(obj.Uri);
            end
        end        

        function openBrowser(obj)
            try
                handleSpecialSchemes(obj);
                if ~obj.Success && isempty(obj.Message)
                    obj.Uri = matlab.internal.web.resolveLocation(obj.Location);
                    if ~isempty(obj.Uri)
                        openUri(obj);
                    elseif isempty(obj.LoadUrl)
                        if obj.hasFlag("-browser") || isdeployed
                            obj.Message = message('MATLAB:web:NoURL');
                        else
                            openMatlabBrowser(obj);
                        end
                    else
                        openLocalBrowser(obj);
                    end
                end
                % Notify the web command listener.
                obj.WebCommandNotifier.browserLaunched(obj.Success, true, '');
            catch ME
                if isdeployed
                    % If we're deployed, we probably failed due to a
                    % function or class that's not accessible from a
                    % deployed app. Try to recover by opening the
                    % system browser. If that fails, the openSystemBrowser 
                    % method will set the object's Success and Message.
                    openSystemBrowser(obj);
                else
                    % If we're not deployed, set the object's Success and
                    % Message.
                    obj.Success = false;
                    obj.Message = message('MATLAB:web:ErrorResolvingOrOpeningURL', ME.identifier);
                end
                % Notify the web command listener.
                obj.WebCommandNotifier.browserLaunched(obj.Success, false, ME.identifier);
            end
        end
    end

    methods (Static)
        function l = addBrowserListener(listenerFcn)
            notifier = matlab.internal.web.WebCommandBrowserLauncher.WebCommandNotifier;
            l = listener(notifier, "BrowserLaunched", listenerFcn);
        end
    end    

    methods (Access = private)
        function handleSpecialSchemes(obj)
            scheme = extractBefore(obj.Location, ":");
            switch (scheme)
                case "mailto"
                    obj.Location = replace(obj.Location, "mailto:" + asManyOfPattern("/"), "mailto:");
                    openSystemBrowser(obj);
                case {"text", "about"}
                    if isLocalBrowserSupported(obj)
                        openMatlabBrowser(obj);
                    else
                        obj.Success = false;
                        obj.Message = message('MATLAB:web:UnsupportedSyntax');
                    end 
            end
        end        

        function openUri(obj)
            docPage = matlab.internal.doc.url.parseDocPage(obj.Uri);
            if ~isempty(docPage) && docPage.IsValid && ~docPage.isPastReleasePage && ~obj.hasFlag("-browser")
                launcher = matlab.internal.doc.ui.DocPageLauncher.getLauncherForDocPage(docPage);
                obj.Success = launcher.openDocPage;
            elseif isLocalContent(obj) || isOpenExternalInLocalBrowser(obj)
                openLocalBrowser(obj);
            else
                openSystemBrowser(obj);
            end
        end

        function openLocalBrowser(obj)
            if obj.hasFlag("-browser") || ~isLocalBrowserSupported(obj)
                openSystemBrowser(obj);
            else
                openMatlabBrowser(obj);
            end 
        end

        function openSystemBrowser(obj)
            launcher = matlab.internal.web.SystemBrowserLauncher;
            [stat, msg] = launcher.openSystemBrowser(obj.LoadUrl);
            obj.Success = stat == 0;            
            if obj.WarnOnSystemError && isa(msg, "message")
                obj.Message = msg;
            end
        end

        function openMatlabBrowser(obj)
            obj.Browser = getActiveBrowser(obj);
            obj.Success = ~isempty(obj.Browser);
            if obj.Success
                if startsWith(obj.Location, "text:")
                    if obj.isHTMLViewer
                        text = obj.Location;
                    else
                        text = extractAfter(obj.Location, "text:" + asManyOfPattern("/"));
                    end
                    obj.Browser.setHtmlText(text);
                else
                    if isempty(obj.LoadUrl)
                        browserLoc = string(obj.Browser.getCurrentLocation);
                        obj.Uri = matlab.internal.web.resolveLocation(browserLoc);
                    else
                        obj.Browser.setCurrentLocation(obj.LoadUrl);
                    end
                end
            end
        end

        function browser = getActiveBrowser(obj)
            browser = [];
            if ~obj.hasFlag("-new")
                % User doesn't want a new browser, so find the active browser.
                if obj.isHTMLViewer
                    browser = matlab.htmlviewer.internal.getActiveWindow();
                else
                    browser = com.mathworks.mde.webbrowser.WebBrowser.getActiveBrowser;
                end
            end

            if isempty(browser)
                % If there is no active browser, create a new one.
                toolbar = ~obj.hasFlag("-notoolbar");
                addressbox = ~obj.hasFlag("-noaddressbox");
                if obj.isHTMLViewer
                    browser = htmlviewer('ShowToolbar',toolbar,'NewTab',true);
                else
                    browser = com.mathworks.mde.webbrowser.WebBrowser.createBrowser(toolbar, addressbox);
                end
            end
        end

        function is_local_content = isLocalContent(obj)
            is_local_content = matlab.internal.web.isLocalContent(obj.Uri);
        end        

        function open_local_browser = isOpenExternalInLocalBrowser(obj)
            % Its not local content, but our setting is set to view
            % external content in the local MATLAB browser.
            open_local_browser = ~isLocalContent(obj) && ~matlab.internal.web.WebCommandBrowserLauncher.isSystemBrowserForExternalSites;
        end

        function supported = isLocalBrowserSupported(obj)
            if obj.isHTMLViewer
                supported = matlab.htmlviewer.internal.HTMLViewerManager.canOpenInHTMLViewer(obj.LoadUrl);
            else
                supported = ~matlab.internal.web.isMatlabOnlineEnv;
            end
        end
    end

    methods (Static, Access = private)
        function system_browser_for_external_sites = isSystemBrowserForExternalSites
            s = settings;
            systemBrowserSetting = s.matlab.web.RedirectExternalSites;
            system_browser_for_external_sites = systemBrowserSetting.ActiveValue;
        end

        function is_HTML_viewer = isHTMLViewerSupported
            if ~isdeployed
                is_HTML_viewer = matlab.htmlviewer.internal.isHTMLViewer;
            else
                is_HTML_viewer = false;
            end
        end
    end
end

%   Copyright 2021-2022 The MathWorks, Inc.