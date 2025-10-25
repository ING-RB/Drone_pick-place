function h = axes(hndl,varargin)
% Returns instance of @axes class
%
%   H = AXES(AXHANDLE) creates an @axes instance associated with the
%   HG axes AXHANDLE.
%
%   H = AXES(FIGHANDLE) automatically creates the HG axes and parents
%   them to the figure with handle FIGHANDLE.

%   Author: P. Gahinet
%   Copyright 1986-2014 The MathWorks, Inc.

% Create @axes instance
h = ctrluis.axes;
h.Size = [1 1 1 1];

% Validate first input argument
if numel(hndl)~=1 || ~ishghandle(hndl)
    ctrlMsgUtils.error('Controllib:plots:axes1')
else
    hndl = handle(hndl);
end
if ishghandle(hndl,'figure')
    % Create axes
    Visibility = hndl.Visible;
    hndl = handle(axes('Parent',hndl,'units','normalized', ...
        'Visible','off','ContentsVisible','off'));
    % Disable Default Interactions
    disableDefaultInteractivity(hndl(1));
    % Position in Normalized units
    Position = hndl.Position;
elseif ishghandle(hndl,'axes')
    Visibility = hndl.Visible;
    % Disable Default Interactions
    disableDefaultInteractivity(hndl(1));
    % Position in Normalized units
    Position = hgconvertunits(ancestor(hndl,'figure'), hndl.Position, hndl.Units, 'normalized', hndl.Parent);
    % Hide axes, consistently with h.Visible=off initially
    set(hndl,'Visible','off','ContentsVisible','off');
else
    ctrlMsgUtils.error('Controllib:plots:axes1')
end
GridState = hndl(1).XGrid;

% Create and initialize axes array
% RE: h.Axes not used
h.Axes4d = hndl;  % array of HG axes of size GRIDSIZE
h.Axes2d = hndl;
h.Parent = hndl.Parent;
h.AxesStyle = ctrluis.axesstyle(hndl);
% Branching for disabling uicontextmenu for axes under uifigure in Live Editor Task
fig = ancestor(h.Parent,'figure');
if ~controllibutils.isLiveTaskFigure(fig)
    h.UIContextMenu = uicontextmenu('Parent',ancestor(h.Parent,'figure'));
else
    h.UIContextMenu = [];
end

% Settings inherited from template axes
h.XLimMode = hndl.XLimMode;
h.XScale = hndl.XScale;
h.YLimMode = hndl.YLimMode;
h.YScale = hndl.YScale;
h.NextPlot = hndl.NextPlot;

% Turn DoubleBuffer=on to eliminate flashing with grids, labels,...
set(ancestor(h.Parent,'figure'),'DoubleBuffer','on')

Props = struct(h.AxesStyle);

% Configure axes
set(h.Axes2d,'Units','normalized','Box','on',...
    'XtickMode','auto','YtickMode','auto',...
    'Xlim',hndl.XLim,'Ylim',hndl.YLim,...
    'NextPlot',hndl.NextPlot,...
    'XGrid','off','YGrid','off',Props);

% Branching for axes parented to uifigure in Live Editor Task
if ~controllibutils.isLiveTaskFigure(fig)
    set(h.Axes2d,'UIContextMenu',h.UIContextMenu);
end

% Initialize properties
% RE: no listeners installed yet
h.Title = get(hndl.Title,'String');
h.XLabel = get(hndl.XLabel,'String');
h.XUnits = '';
h.YLabel = get(hndl.YLabel,'String');
h.YUnits = '';
h.TitleStyle = ctrluis.labelstyle(hndl.Title);
h.XLabelStyle = ctrluis.labelstyle(hndl.XLabel);
h.YLabelStyle = ctrluis.labelstyle(hndl.YLabel);
h.Position = Position; % RE: may be overwritten by SET below
h.LimitFcn = {@updatelims h};  % install default limit picker
h.LabelFcn = {@DefaultLabelFcn h};

% Add listeners
h.addlisteners;

% User-defined properties
% RE: Maintain h.Visible=off in order to bypass all layout/visibility computations
% (achieved by removing Visible settings from prop/value list and factoring them into
%  the VISIBILITY variable)
[Visibility,varargin] = utGetVisibleSettings(h,Visibility,varargin);
h.set('Grid',GridState',varargin{:});

% Set visibility (if Visibility=on, this initializes the position/visibility of the HG axes)
h.Visible = Visibility;

% Activate limit manager
addlimitmgr(h);
