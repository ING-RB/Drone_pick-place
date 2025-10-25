function h = axespair(hndl,varargin)
% Returns instance of @axespair class
%
%   H = AXESPAIR(AXHANDLE) creates an @axespair instance using the HG
%   axes handles in AXHANDLE.
%
%   H = AXESPAIR(FIGHANDLE) automatically creates the HG axes and parents
%   them to the figure with handle FIGHANDLE.

%   Author: P. Gahinet
%   Copyright 1986-2014 The MathWorks, Inc.

% Create @axespair instance
h = ctrluis.axespair;
h.Size = [2 1 1 1];

% Validate first input argument
if any(~ishghandle(hndl))
    ctrlMsgUtils.error('Controllib:plots:axespair1')
else
    hndl = handle(hndl);
end
if ishghandle(hndl,'figure')
    % Create axes
    Visibility = hndl.Visible;
    hndl = handle(axes('Parent',hndl,'Units','Normalized', ...
        'Visible','off','ContentsVisible','off'));
    % Disable Default Interactions
    disableDefaultInteractivity(hndl(1));
    % Position in Normalized units
    Position = hndl.Position;
elseif ishghandle(hndl,'axes')
    Visibility = hndl(1).Visible;
    % Disable Default Interactions
    disableDefaultInteractivity(hndl(1));
    % Position in Normalized units
    Position = hgconvertunits(ancestor(hndl(1),'figure'), ...
        hndl(1).Position, hndl(1).Units, 'normalized', hndl(1).Parent);
    % Hide axes, consistently with h.Visible=off initially
    set(hndl,'Visible','off','ContentsVisible','off')
else
    ctrlMsgUtils.error('Controllib:plots:axespair1')
end
GridState = hndl(1).XGrid;

% Create and initialize axes array
h.Axes = ctrluis.plotpair(hndl);
h.Axes4d = getaxes(h.Axes);  % 2x1 HG axes
h.Axes2d = h.Axes4d;
h.Parent = hndl(1).Parent;
h.AxesStyle = ctrluis.axesstyle(hndl(1));
h.UIContextMenu = uicontextmenu('Parent',ancestor(h.Parent,'figure'));

% Settings inherited from template axes
h.XLimMode = hndl(1).XLimMode;
h.XScale = hndl(1).XScale;
h.YLimMode = get(hndl,'YLimMode');  % string or 2x1 cell
h.YScale = get(hndl,'YScale');      % string or 2x1 cell
h.NextPlot = hndl(1).NextPlot;

% Turn DoubleBuffer=on to eliminate flashing with grids, labels,...
set(ancestor(h.Parent,'figure'),'DoubleBuffer','on')

Props = struct(h.AxesStyle);

% Configure axes
set(h.Axes2d,'Units','normalized','Box','on',...
    'XtickMode','auto','YtickMode','auto',...
    'Xlim',hndl(1).XLim,'NextPlot',hndl(1).NextPlot,...
    'UIContextMenu',h.UIContextMenu,...
    'XGrid','off','YGrid','off',Props);
if length(hndl)==1
    set(h.Axes2d,'Ylim',hndl.YLim)
else
    set(h.Axes2d,{'Ylim'},get(hndl,'Ylim'))
end

% Initialize properties
% RE: no listeners installed yet
h.Title = get(hndl(1).Title,'String');
h.XLabel = get(hndl(1).XLabel,'String');
h.XUnits = '';
h.YLabel = {get(h.Axes2d(1).YLabel,'String');get(h.Axes2d(2).YLabel,'String')};
h.YUnits = {'';''};
h.TitleStyle = ctrluis.labelstyle(hndl(1).Title);
h.XLabelStyle = ctrluis.labelstyle(hndl(1).XLabel);
h.YLabelStyle = ctrluis.labelstyle(hndl(1).YLabel);
h.Position = Position; % RE: may be overwritten by SET below
h.LimitFcn = {@updatelims h};  % install default limit picker
h.LabelFcn = {@DefaultLabelFcn h};

% Add listeners
h.addlisteners;

% Set properties
% RE: Maintain h.Visible=off in order to bypass all layout/visibility computations
% (achieved by removing Visible settings from prop/value list and factoring them into
%  the VISIBILITY variable)
[Visibility,varargin] = utGetVisibleSettings(h,Visibility,varargin);
h.set('Grid',GridState',varargin{:});

% Set visibility (initializes the position/visibility of the HG axes)
h.Visible = Visibility;

% Add bypass for TITLE, AXIS,...
addbypass(h);

% Activate limit manager
addlimitmgr(h);

