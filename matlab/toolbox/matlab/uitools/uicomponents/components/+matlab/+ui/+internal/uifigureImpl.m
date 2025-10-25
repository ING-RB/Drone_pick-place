function fig = uifigureImpl(isIsolatedRequested, varargin)
% internal implementation of uifigure creation

% Copyright 2017-2024 The MathWorks, Inc.

nargoutchk(0,1);

% Import Capability to check for WebWindow if it will be needed
import matlab.internal.capability.Capability;

% Set up the controllerInfo structure to indicate a web Figure
controllerInfo.ControllerClassName = 'matlab.ui.internal.controller.FigureController';

% Modify the controllerInfo structure if so indicated by settings
s = settings;
if s.matlab.ui.figure.MoUIFigureInUIContainer.ActiveValue && ...
        s.matlab.ui.figure.ShowInMATLABOnline.ActiveValue
    % Settings indicate to render this uifigure-function Figure as a Div Figure in MATLAB Online,
    % for which we need to send the DivFigurePacket to the client
    controllerInfo.div = 'send';
elseif s.matlab.ui.figure.ShowEmbedded.ActiveValue || ...
        (s.matlab.ui.figure.ShowInWebApps.ActiveValue || ...
        (isdeployed && matlab.internal.environment.context.isWebAppServer))
    % Create an uifigure if the div figure setting is on or we are in
    % a Web Apps environment: set div to 'hold' to indicate that the creating app
    % will pick up the DivFigurePacket and deliver it to the client
    controllerInfo.div = 'hold';
    FigureConfigurations.Embedded = true;
else
    % Non-Div/Non-embedded figures use WebWindow, so make sure WebWindow capability is enabled
    % For example, WebWindow is not supported for MATLAB Mobile, in which case an error is thrown (g2071514)
    % Note: We can't make this call in FigurePlatformHostFactory because it needs to be made before the Figrue Model is created
    Capability.require(Capability.WebWindow);
end

% Set up figure feature capabilities
FigureConfigurations.canKeyPressForward = false;
FigureConfigurations.isAppBuilding = true;

if isIsolatedRequested
    FigureConfigurations.isIsolatedRequested = true;
end

% set the multifigure flag before creating the figure for deploywed web apps
if (s.matlab.ui.figure.ShowInWebApps.ActiveValue || ...
        (isdeployed && matlab.internal.environment.context.isWebAppServer))

    matlab.ui.internal.setMultipleFigureFlag();
end

window = gobjects(0);
try
    % Create the uifigure, configured for app building
    % Set defaults for unsupported properties first.
    % After setting ControllerInfo, unsupported property sets will error.
    
    %Retrieve cell array of default name-pair values of objects for App
    %Building to be appended with user constructor arguments
    vararginWithDefaultObjectProperties = matlab.ui.internal.FigureServices.mergeDefaultObjectPropertiesForAppBuildingWithVarargin(varargin{:});

    CreateUIFigure;
    window = appwindowfactory('WindowStyle','normal',...
        'DockControls','off',...
        'HandleVisibility','off',...
        'IntegerHandle','off',...
        'MenuBar','none',...
        'NumberTitle','off',...
        'Toolbar','none',...
        'MenuBarMode','auto',...
        'ToolBarMode','auto',...
        'Position',matlab.ui.internal.getUiFigureDefaultPosition(),...
        'PositionMode', 'auto',...
        'ControllerInfo',controllerInfo,...
        'FigureConfigurations', FigureConfigurations,...
        'AutoResizeChildren', 'on',...
        'HasAppBuildingDefaults', true,...
        'Units_I','pixels',... % Make sure that the Figure comes up with 'pixels' Units, without toggling UnitsMode
        vararginWithDefaultObjectProperties{:});

    CreateUIFigureReset;
catch e
    delete(window);
    CreateUIFigureReset;
    rethrow(e);
end

fig = window;

% DO NOT USE THIS PROPERTY!!! IT IS EXCLUSIVELY FOR AXES TOOLBAR
metaProp = addprop(fig, 'isUIFigure');
metaProp.Hidden = true;
fig.isUIFigure = true;
% END DO NOT USE

% Block all multi-window apps for deployed webapps
if (s.matlab.ui.figure.ShowInWebApps.ActiveValue || ...
        (isdeployed && matlab.internal.environment.context.isWebAppServer))

    % Set appdata for file IO dialog
    setappdata(window, 'MW_SessionDirectory', pwd);

    %add listerner on figure object to throw error for multiple figures
    matlab.ui.internal.preventMultiFigureAppsInWebAppServer();

end
end
