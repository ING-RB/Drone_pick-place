function fig = embeddedfigure(varargin)
%EMBEDDEDFIGURE Create a web figure configured to be embedded in applications
%    EMBEDDEDFIGURE creates a web figure using default property values configured
%    for building apps that use URL-free figures.
%
%    EMBEDDEDFIGURE(Name, Value) specifies properties using one or more Name,
%    Value pair arguments.
%
%    fig = EMBEDDEDFIGURE(___) returns the figure object, fig. Use this
%    option with any of the input argument combinations in the previous
%    syntaxes.
%
%    Example 1: Create Default embeddedfigure
%       fig = matlab.ui.internal.embeddedfigure;
%
%    Example 2: Create an embeddedfigure with a specific Color.
%       fig = matlab.ui.internal.embeddedfigure('Color', [.9 .95 1]);
%
%    See also UIFIGURE

%    Copyright 2018-2020 The MathWorks, Inc.


nargoutchk(0,1);

% signal that this is not only a web figure but also an embeddedfigure
% Set embedded to 'hold' to indicate that the creating app will pick up
% the EmbeddedFigurePacket and deliver it to the client
controllerInfo.ControllerClassName = 'matlab.ui.internal.controller.FigureController';
controllerInfo.embedded = 'hold';

% Set up figure feature capabilities
FigureConfigurations.canKeyPressForward = false;
FigureConfigurations.isAppBuilding = true;
FigureConfigurations.Embedded = true;

% Create the embeddedfigure, configured for app building.
% Set defaults for unsupported properties first.
% After setting ControllerInfo, unsupported property sets will error.
% Set Internal true to protect from close all, findobj, findall, allchild,
% gcf, and gco: the app is responsible for tracking its content.

%Retrieve cell array of default name-pair values of objects for App
%Building to be appended with user constructor arguments
vararginWithDefaultObjectProperties = matlab.ui.internal.FigureServices.mergeDefaultObjectPropertiesForAppBuildingWithVarargin(varargin{:});

try
CreateEmbeddedFigure  
window = appwindowfactory('WindowStyle','normal',...
                          'DockControls','off',...
                          'HandleVisibility','off',...
                          'IntegerHandle','off',...
                          'MenuBar','none',...
                          'NumberTitle','off',...
                          'Toolbar','none',...
                          'ControllerInfo',controllerInfo,...
                          'FigureConfigurations', FigureConfigurations,...
                          'AutoResizeChildren', 'on',...
                          'Internal', true,...
                          vararginWithDefaultObjectProperties{:});
CreateEmbeddedFigureReset
catch ME %#ok<NASGU>
    CreateEmbeddedFigureReset
end

fig = window;

end
