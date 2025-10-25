function tip = pointtip(POINT, varargin)
%POINTTIP  Creates a data tip locked to a given point.
%
%   h = POINTTIP(POINT,'PropertyName1',value1,'PropertyName2,'value2,...) 
%   will attach a data tip to the point POINT (single-point HG line).

%   Author(s): John Glass
%   Copyright 1986-2014 The MathWorks, Inc.

% Create linetip
try
    dcm = datacursormode(ancestor(POINT,'Figure'));
    tip = dcm.createDatatip(POINT);   
    tip.ParentLayer = 'overlay';
    % Enable Interactions for webfigures and uifigures
    canvas = ancestor(tip,'matlab.graphics.primitive.canvas.HTMLCanvas','node');
    if ~isempty(canvas)
        tip.enableInteractionsOnDatatips(canvas);
    end
    fig = ancestor(tip,'figure');
    figPoint = get(fig,'CurrentPoint');
    figPoint = hgconvertunits(fig,[figPoint 0 0],get(fig,'Units'),'pixels',fig);
    figPoint = figPoint(1:2);
    tip.Cursor.handleUIEvent('mouse',figPoint);
catch
    ctrlMsgUtils.error('Controllib:general:UnexpectedError',...
        'The first input argument of the "pointtip" command must be a handle of class "line".')
end
% Set Properties
set(tip,'Visible','on',varargin{:});

if ~max(strcmpi(varargin,'X')) | isempty(varargin)
    curr = get(get(POINT,'Parent'),'CurrentPoint');
    oldpos = tip.Position;
    tip.Position = [curr(1,1),oldpos(2),oldpos(3)];    
end

if ~max(strcmpi(varargin,'Y')) | isempty(varargin)
    curr = get(get(POINT,'Parent'),'CurrentPoint');
    oldpos = tip.Position;
    tip.Position = [oldpos(1),curr(1,2),oldpos(3)];
end

%% Build uicontextmenu handle for marker text
ax = get(POINT,'Parent');
tip.UIContextMenu = uicontextmenu('Parent',ancestor(ax,'figure'));
set(tip.UIContextMenu,'Serializable','off');
%% Add the default menu items
ltitipmenus(tip,'alignment','fontsize','delete');
