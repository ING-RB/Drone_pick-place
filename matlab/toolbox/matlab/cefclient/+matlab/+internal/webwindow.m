classdef webwindow < handle
%webwindow A webwindow using either CEF (Chromium Embedded Framework)
%component or system browser (for remote cases, like MATLAB Online)

% Copyright 2013-2023 The MathWorks, Inc.

% Suppressing dependent property mlint messages for this file.
%#ok<*MCSUP>

    properties ( Access = public )

        % URL - A string specifying the URL of the web window.
        URL

        % Icon - A string specifying the icon path.
        Icon

        % Position - A 4x1 array of [ x y width height ] specifying the
        % size and location of the window. This is the
        % inner position, or the size of the window
        % without the OS-level chrome such as the title
        % bar.
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

        % This callback applies to MATLAB Online when the page refreshes and no-op for CEF.
        PageRefreshCallback

        Tag (1,1) string = ""
    end

    properties (Access = public, Dependent=true)
        % Title - A string specifying the title of the launched window.
        Title
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

    properties ( SetAccess = private, GetAccess = public )
        % Bool indicating if the window is valid.
        isWindowValid

        isDownloadingFile

        isModal

        isWindowActive

        isAlwaysOnTop

        isAllActive

        isResizable

        isFocused

        MaxSize

        MinSize

        windowType

        DownloadLocation

        Origin

        BrowserMode

        PersistentCachePath

        isZoomEnabled

        WinID

        isRefreshSupported
    end
    properties (SetAccess = ?matlab.internal.cef.webwindow, GetAccess = public )
        Parent = matlab.internal.webwindow.empty

        Children = matlab.internal.webwindow.empty

    end

    properties (Access={?matlab.internal.webwindowmanager})
        impl
        deleteListener
    end

    %Method wrappers
    methods

        function obj = webwindow(varargin)
            import matlab.internal.capability.Capability;
            Capability.require(Capability.WebWindow);

            obj.impl = obj.createImplementation(varargin{:});
            obj.impl.interface = obj;
            if isprop(obj.impl, 'Parent') && ~isempty(obj.impl.Parent)
                obj.Parent = obj.impl.Parent;
                obj.Parent.Children(end+1) = obj;
            end

            obj.deleteListener = addlistener(obj.impl, ...
                                             'ObjectBeingDestroyed', @(src,event) obj.delete);
        end

        function delete(obj)
            delete(obj.deleteListener);
            delete(obj.impl);
            delete@handle(obj);
        end

        function show(obj)
            show(obj.impl);
        end

        function hide(obj)
            hide(obj.impl);
        end

        function setResizable(obj,newValue)
            setResizable(obj.impl,newValue);
        end

        function setDownloadLocation(obj,newValue)
            setDownloadLocation(obj.impl,newValue);
        end

        function setMinSize(obj,Size)
            setMinSize(obj.impl,Size);
        end

        function setMaxSize(obj,Size)
            setMaxSize(obj.impl,Size);
        end

        %% no-ops if cef window
        function setIsRefreshSupported(obj,val)
            if isa(obj.impl, 'connector.internal.webwindow')
                setIsRefreshSupported(obj.impl, val);
            end
        end

        function minimize(obj)
            minimize(obj.impl);
        end

        function maximize(obj)
            maximize(obj.impl);
        end

        function restore(obj)
            restore(obj.impl);
        end

        function state = isFullscreen(obj)
            state = isFullscreen(obj.impl);
        end

        function openDevTools(obj)
            openDevTools(obj.impl);
        end

        function closeDevTools(obj)
            closeDevTools(obj.impl);
        end

        function fullscreen(obj)
            fullscreen(obj.impl);
        end

        function bringToFront(obj)
            bringToFront(obj.impl)
        end

        function allowNavigation(obj,newValue)
            allowNavigation(obj.impl,newValue)
        end

        function stopDownload(obj)
            stopDownload(obj.impl)
        end

        function close(obj)
            close(obj.impl)
        end

        function setActivateCurrentWindow(obj,newValue)
            setActivateCurrentWindow(obj.impl,newValue)
        end

        function setAlwaysOnTop(obj,newValue)
            setAlwaysOnTop(obj.impl,newValue)
        end

        function value = isWindowActivated(obj)
            value = isWindowActivated(obj.impl);
        end

        function enableDragAndDrop(obj)
            enableDragAndDrop(obj.impl)
        end

        function enableDragAndDropAll(obj)
            enableDragAndDropAll(obj.impl)
        end

        function setActivateAllWindows(obj,newValue)
            setActivateAllWindows(obj.impl,newValue);
        end

        function value = allWindowActivated(obj)
            value = allWindowActivated(obj.impl);
        end

        function setWindowAsModal(obj,newValue)
            setWindowAsModal(obj.impl,newValue);
        end

        function value = isWindowModal(obj)
            value = isWindowModal(obj.impl);
        end

        function state = isMaximized(obj)
            state = isMaximized(obj.impl);
        end

        function state = isMinimized(obj)
            state = isMinimized(obj.impl);
        end

        function state = isVisible(obj)
            state = isVisible(obj.impl);
        end

        function result = executeJS(obj, jsStr, timeout)
            narginchk(2,3);
            switch nargin
              case 2
                result = executeJS(obj.impl, jsStr);
              otherwise
                result = executeJS(obj.impl, jsStr, timeout);
            end
        end

        function img = getScreenshot(obj)
            img = getScreenshot(obj.impl);
        end

        function success = printToPDF(obj, filename)
            success = printToPDF(obj.impl, filename);
        end

        function list = findAllWebwindows(obj)
            list = findAllWebwindows(obj.impl);
        end

    end

    methods (Access=private)

        function implObj = createImplementation(obj, varargin)
            mgr = matlab.internal.webwindowmanager;
            if isequal(mgr.provider, 'remote') && exist('connector.internal.webwindow','class')
                implObj = connector.internal.webwindow(varargin{:});
            else
                implObj = matlab.internal.cef.webwindow(varargin{:});
            end
        end

    end

    %Public property setters/getters
    methods

        function set.URL(obj,val)
            obj.impl.URL = val;
        end

        function val = get.URL(obj)
            val = obj.impl.URL;
        end

        function set.Icon(obj,val)
            obj.impl.Icon = val;
        end

        function val = get.Icon(obj)
            val = obj.impl.Icon;
        end

        function set.Position(obj,val)
            obj.impl.Position = val;
        end

        function val = get.Position(obj)
            val = obj.impl.Position;
        end

        function set.OuterPosition(obj,val)
            obj.impl.OuterPosition = val;
        end

        function val = get.OuterPosition(obj)
            val = obj.impl.OuterPosition;
        end

        function set.ZoomLevel(obj,val)
            obj.impl.ZoomLevel = val;
        end

        function val = get.ZoomLevel(obj)
            val = obj.impl.ZoomLevel;
        end

        function val = get.CurrentURL(obj)
            val = obj.impl.CurrentURL;
        end

        function set.CustomWindowClosingCallback(obj,val)
            obj.impl.CustomWindowClosingCallback = val;
        end

        function val = get.CustomWindowClosingCallback(obj)
            val = obj.impl.CustomWindowClosingCallback;
        end

        function set.CustomWindowResizingCallback(obj,val)
            obj.impl.CustomWindowResizingCallback = val;
        end

        function val = get.CustomWindowResizingCallback(obj)
            val = obj.impl.CustomWindowResizingCallback;
        end

        function set.WindowResizing(obj,val)
            obj.impl.WindowResizing = val;
        end

        function val = get.WindowResizing(obj)
            val = obj.impl.WindowResizing;
        end

        function set.WindowResized(obj,val)
            obj.impl.WindowResized = val;
        end

        function val = get.WindowResized(obj)
            val = obj.impl.WindowResized;
        end

        function set.FocusGained(obj,val)
            obj.impl.FocusGained = val;
        end

        function val = get.FocusGained(obj)
            val = obj.impl.FocusGained;
        end

        function set.FocusLost(obj,val)
            obj.impl.FocusLost = val;
        end

        function val = get.FocusLost(obj)
            val = obj.impl.FocusLost;
        end

        function set.DownloadCallback(obj,val)
            obj.impl.DownloadCallback = val;
        end

        function val = get.DownloadCallback(obj)
            val = obj.impl.DownloadCallback;
        end

        function set.PageLoadFinishedCallback(obj,val)
            obj.impl.PageLoadFinishedCallback = val;
        end

        function val = get.PageLoadFinishedCallback(obj)
            val = obj.impl.PageLoadFinishedCallback;
        end

        function set.MATLABClosingCallback(obj,val)
            obj.impl.MATLABClosingCallback = val;
        end

        function val = get.MATLABClosingCallback(obj)
            val = obj.impl.MATLABClosingCallback;
        end

        function set.MATLABWindowExitedCallback(obj,val)
            obj.impl.MATLABWindowExitedCallback = val;
        end

        function val = get.MATLABWindowExitedCallback(obj)
            val = obj.impl.MATLABWindowExitedCallback;
        end

        function set.PopUpWindowCallback(obj,val)
            obj.impl.PopUpWindowCallback = val;
        end

        function val = get.PopUpWindowCallback(obj)
            val = obj.impl.PopUpWindowCallback;
        end

        function set.WindowStateCallback(obj,val)
            obj.impl.WindowStateCallback = val;
        end

        function val = get.WindowStateCallback(obj)
            val = obj.impl.WindowStateCallback;
        end

        function set.ZoomCallback(obj,val)
            obj.impl.ZoomCallback = val;
        end

        function val = get.ZoomCallback(obj)
            val = obj.impl.ZoomCallback;
        end

        function set.FileDragDropCallback(obj,val)
            obj.impl.FileDragDropCallback = val;
        end

        function val = get.FileDragDropCallback(obj)
            val = obj.impl.FileDragDropCallback;
        end

        function set.PageRefreshCallback(obj,val)
            obj.impl.PageRefreshCallback = val;
        end

        function val = get.PageRefreshCallback(obj)
            val = obj.impl.PageRefreshCallback;
        end

        function set.Title(obj,val)
            obj.impl.Title = val;
        end

        function val = get.Title(obj)
            val = obj.impl.Title;
        end

    end

    %Public getter, private setter properties
    methods

        function val = get.RemoteDebuggingPort(obj)
            val = obj.impl.RemoteDebuggingPort;
        end

        function val = get.CEFVersion(obj)
            val = obj.impl.CEFVersion;
        end

        function val = get.ChromiumVersion(obj)
            val = obj.impl.ChromiumVersion;
        end

        function val = get.isWindowValid(obj)
            val = obj.impl.isWindowValid;
        end

        function val = get.isDownloadingFile(obj)
            val = obj.impl.isDownloadingFile;
        end

        function val = get.isModal(obj)
            val = obj.impl.isModal;
        end

        function val = get.isWindowActive(obj)
            val = obj.impl.isWindowActive;
        end

        function val = get.isAlwaysOnTop(obj)
            val = obj.impl.isAlwaysOnTop;
        end

        function val = get.isAllActive(obj)
            val = obj.impl.isAllActive;
        end

        function val = get.isResizable(obj)
            val = obj.impl.isResizable;
        end

        function val = get.isFocused(obj)
            val = obj.impl.isFocused;
        end

        function val = get.MaxSize(obj)
            val = obj.impl.MaxSize;
        end

        function val = get.MinSize(obj)
            val = obj.impl.MinSize;
        end

        function val = get.windowType(obj)
            val = obj.impl.windowType;
        end

        function val = get.DownloadLocation(obj)
            val = obj.impl.DownloadLocation;
        end

        function val = get.Origin(obj)
            val = obj.impl.Origin;
        end

        function val = get.BrowserMode(obj)
            val = obj.impl.BrowserMode;
        end

        function val = get.WinID(obj)
            val = obj.impl.WinID;
        end

        function val = get.isRefreshSupported(obj)
            val = obj.impl.isRefreshSupported;
        end

    end

    methods
        function set.Parent(obj, val)
            obj.Parent = val;
        end
        function set.Children(obj, val)
            obj.Children = val;
        end

    end

    methods (Static)
        function missingLibraries = findMissingLibraries()
            missingLibraries = matlab.internal.cef.webwindow.findMissingLibraries();
        end
    end

end
