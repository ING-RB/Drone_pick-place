function tip = linetip(LINE, varargin)
%LINETIP  Line tip wrapper function
%
%   h = LINETIP(LINE,'PropertyName1',value1,'PropertyName2,'value2,...) 
%   will activate linetip with the following options:
%
%      LINE:       handle of line to be scanned.
%
%

%  Author(s): John Glass
%  Revised:
%  Copyright 1986-2014 The MathWorks, Inc.

% Check valid input argument, this change is not really related to datatips
if ~ishghandle(LINE,'line')
    ctrlMsgUtils.error('Controllib:general:UnexpectedError',...
        'The first input argument of the "linetip" command must be a handle of class "line".')
end

%% Create the datatip
dcm = datacursormode(ancestor(LINE,'Figure'));
tip = dcm.createDatatip(LINE);
tip.ParentLayer = 'overlay';
tip.PinnableStyle = matlab.graphics.shape.internal.util.PinnableStyle.AlwaysPinned;
% Enable Interactions for webfigures and uifigures
canvas = ancestor(tip,'matlab.graphics.primitive.canvas.HTMLCanvas','node');
if ~isempty(canvas)
     tip.enableInteractionsOnDatatips(canvas);
end
%% Turn on interpolation
tip.Cursor.Interpolate = 'on';

%% Set Properties
set(tip,'Visible','on',varargin{:});

%% Get the figure
fig = ancestor(tip,'figure');
figPoint = get(fig,'CurrentPoint');
figPoint = hgconvertunits(fig,[figPoint 0 0],get(fig,'Units'),'pixels',fig);
figPoint = figPoint(1:2);
tip.Cursor.handleUIEvent('mouse',figPoint);
drawnow('expose') % needed to force orientation to be correct
tip.OrientationMode='manual';
beginInteraction(tip)

%% Build uicontextmenu handle for marker text
ax = get(LINE,'Parent');
tip.UIContextMenu = uicontextmenu('Parent',ancestor(ax,'figure'));
set(tip.UIContextMenu,'Serializable','off');

%% Add the default menu items
ltitipmenus(tip,'alignment','fontsize','movable','delete','interpolation');
