function launchSSIForBaseCode(basecode, ssiCloseCallbackFcn)
% Utility function to launch SSI for a given basecode with a callback
% function to be invoked when the SSI window is closed. Note that the
% callback function is a standard two input argument function of the type
% @(src, evt).

% Copyright 2021-2022 The MathWorks Inc.

arguments
    basecode string
    ssiCloseCallbackFcn function_handle = function_handle.empty;
end

% Launch the SSI window. Create the support package root directory if it
% doesn't exist yet

installFolder = matlabshared.supportpkg.getSupportPackageRoot('CreateDir', true);

isLaunched = matlab.hwmgr.internal.util.launchSSIWindow(installFolder, basecode);

% Get the window using the web window manager and matching the string. If
% there are other web windows get the latest window via the window ID

wmgr = matlab.internal.webwindowmanager();
windowList = wmgr.windowList();

% The SSI window is the most recently opened. 
ssiWindow = windowList(end);

% Set the window title and disable the maximize button of the SSI window.
if isLaunched
    ssiWindow.Title = message('hwmanagerapp:hwmgrstartpage:InstallAddOn').getString();
    ssiWindow.setResizable(false);
end

% Attach the close function to the window close
if ~isempty(ssiCloseCallbackFcn) && isLaunched
    addlistener(ssiWindow, 'ObjectBeingDestroyed', ssiCloseCallbackFcn);
end
end