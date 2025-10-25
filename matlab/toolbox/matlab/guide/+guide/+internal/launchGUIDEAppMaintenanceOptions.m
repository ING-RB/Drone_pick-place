function launchGUIDEAppMaintenanceOptions(varargin)
%launchGUIDEAppMaintenanceOptions - Launches the GUIDEAppMaintenanceOptions app 
% This launcher contains logic that forces the app to be singleton.
% This separate launcher allows for code to be executed immediately after the singleton 
% instance is brought to the front.
% NOTE: This exact behavior cannot be obtained by making the app singleton
% in App Designer.

% Copyright 2020 The MathWorks, Inc.

% Create a persistent variable to ensure only one instance of the front end app is
% created
persistent GUIDEAppMaintenanceOptionsAppInstance;

% Check if an existing app is open
if isempty(GUIDEAppMaintenanceOptionsAppInstance) || ~isvalid(GUIDEAppMaintenanceOptionsAppInstance)
    % No existing app, create a new one
    GUIDEAppMaintenanceOptionsAppInstance = guide.internal.GUIDEAppMaintenanceOptions(varargin{:});
else
    % Bring existing app to front
    figure(GUIDEAppMaintenanceOptionsAppInstance.UIFigure);
    
    % Configure the app so that the latest inputs are used.  That is, we want to
    % ensure that the latest app file name is prepopulated in the edit fields 
    % and the user's intended action (export or migrate) is reflected in
    % the selected tab.
    configureApp(GUIDEAppMaintenanceOptionsAppInstance, varargin{:});
end

% put a lock on the instance so this instance cannot be cleared by a
% "clear all".  If not "clear all" will lose handle to already open app
% causing to launch a new app
mlock;
end