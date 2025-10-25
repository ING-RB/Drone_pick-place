function fig = divfigure(varargin)
%DIVFIGURE Create a web figure configured to be embedded in a div
%    DIVFIGURE creates a web figure using default property values configured
%    for building apps that embed one or more figures in their DOM.
%
%    DIVFIGURE(Name, Value) specifies properties using one or more Name,
%    Value pair arguments.
%
%    fig = DIVFIGURE(___) returns the figure object, fig. Use this
%    option with any of the input argument combinations in the previous
%    syntaxes.
%
%    Example 1: Create Default divfigure
%       fig = matlab.ui.internal.divfigure;
%
%    Example 2: Create a divfigure with a specific Color.
%       fig = matlab.ui.internal.divfigure('Color', [.9 .95 1]);
%
%    See also UIFIGURE

%    Copyright 2020 The MathWorks, Inc.


nargoutchk(0,1);

% signal that this is not only a web figure but also a divfigure
% Set div to 'hold' to indicate that the creating app will pick up
% the DivFigurePacket and deliver it to the client
controllerInfo.ControllerClassName = 'matlab.ui.internal.controller.FigureController';
controllerInfo.div = 'hold';

% Set up figure feature capabilities
FigureConfigurations.canKeyPressForward = false;
FigureConfigurations.alwaysUndockable = false;
FigureConfigurations.isAppBuilding = true;
FigureConfigurations.Embedded = true;

% Create the divfigure, configured for app building.
% Set defaults for unsupported properties first.
% After setting ControllerInfo, unsupported property sets will error.
% Set Internal true to protect from close all, findobj, findall, allchild,
% gcf, and gco: the app is responsible for tracking its content.

%Retrieve cell array of default name-pair values of objects for App
%Building to be appended with user constructor arguments
vararginWithDefaultObjectProperties = matlab.ui.internal.FigureServices.mergeDefaultObjectPropertiesForAppBuildingWithVarargin(varargin{:});

try
CreateDivFigure  
window = appwindowfactory('WindowStyle','normal',...
                          'DockControls','off',...
                          'HandleVisibility','off',...
                          'IntegerHandle','off',...
                          'MenuBar','none',...
                          'NumberTitle','off',...
                          'Toolbar','none',...
                          'MenuBarMode','auto',...
                          'ToolBarMode','auto',...
                          'ControllerInfo',controllerInfo,...
                          'FigureConfigurations', FigureConfigurations,...
                          'AutoResizeChildren', 'on',...
                          'Internal', true,...
                          vararginWithDefaultObjectProperties{:});
CreateDivFigureReset
catch ME %#ok<NASGU>
    CreateDivFigureReset
end

fig = window;
