function newax = swapaxes(ax, ctor, isInnerPositionable)
% This is an undocumented function and may be removed in a future release.

% Copyright 2015-2024 The MathWorks, Inc.

% Notify the editor that something in the figure is being cleared.
% But only do that for charts like heatmap or axes with children.
if ~isprop(ax,'Children') || ~isempty(ax.Children)
    fig = ancestor(ax,'figure');
    matlab.graphics.internal.clearNotify(fig, ax);
end

% Arguments:
%  ax: The axes to replace
%
%  ctor: The constructor function that will create the replacement for ax
%
%  isInnerPositionable: Will the ctor function create an object that has
%  settable InnerPosition?
if(nargin < 3)
    isInnerPositionable = true;
end

%wasChart: is "axes" being removed is a chart?
wasChart = isa(ax,'matlab.graphics.chart.Chart'); 
wasInnerPositionable = isprop(ax,'ActivePositionProperty');

%is the replacement "axes" a chart?
if ~isInnerPositionable % old-style charts are placed at the OuterPosition of ax
    active = 'outerposition';
else
    if wasInnerPositionable
        active = ax.ActivePositionProperty;
    else        
        %when replacing a chart, use outer position
        active = 'outerposition';
    end
end

if ~wasChart && wasInnerPositionable
    %move colorbar & legend to get full-size axes position
    if(isvalid(ax.Colorbar))
        cb = ax.Colorbar;
        cl = cb.Location;
        cb.Location = 'east';
        cleanupcb = onCleanup(@() restoreColorbar(cb,cl));
    end
    if(isvalid(ax.Legend))
        l = ax.Legend;
        ll = l.Location;
        l.Location = 'east';
        cleanupl = onCleanup(@() restoreLegend(l,ll));
    end
    if(isvalid(ax.BubbleLegend))
        l = ax.BubbleLegend;
        ll = l.Location;
        l.Location = 'east';
        cleanupl = onCleanup(@() restoreLegend(l,ll));
    end    
    
end

if(isprop(ax,'TightInset'))
    ax.TightInset; % needed to refresh the positions
end

units = ax.Units;
parent = ax.Parent;

if isa(parent,'matlab.graphics.layout.Layout') || isa(parent,'matlab.ui.container.internal.model.LayoutContainer')
    newax=ctor('Units',units,'Parent',parent);
    lo=ax.Layout;
    newax.Layout=lo;
    delete(ax);
    return
end

try
    outerPosition = ax.OuterPosition;
    posargs = {'Units',units,'OuterPosition',outerPosition};
catch
    % if querying ax.OuterPosition throws an error, use the default
    posargs = {};
end

% Store position before invoking ctor, as ctor may delete the current axes.
pos = [];
posval = [];
if ~strcmpi(active,'outerposition') 
    pos = 'position';
    posval = ax.Position;
end

% Store appdata before invoking ctor, as ctor may delete the current axes.
appData = struct(SubplotGridLocation=[],SubplotPosition=[],SubplotGrid=[]);
if isappdata(ax,'SubplotGridLocation')
    appData.SubplotGridLocation =  getappdata(ax,'SubplotGridLocation');
end
if isappdata(ax,'SubplotPosition')
    appData.SubplotPosition = getappdata(ax,'SubplotPosition');
end
if isappdata(parent,'SubplotGrid')
    appData.SubplotGrid = getappdata(parent, 'SubplotGrid');
    appData.SubplotInd = appData.SubplotGrid == ax;
end

% Invoke constructor. Note that constructor may have side-effects like triggering 
% another update. We cannot rely on the validity of ax after this point.
newax = ctor(posargs{:},'Parent',parent);

% note: we set position here even though we may reset it. (This is so that 
% charts that draw during construction don't draw over the whole figure before
% re-sizing. We can't predict whether the chart constructed by ctor will
% have an innerposition, so we defer setting innerposition until after
% construction. Also some charts don't yet support unparented creation, so 
% set parent here even though we may unparent later.
if ~isempty(pos) && ~isempty(posval) && isprop(newax,'InnerPosition')
    set(newax,pos,posval)
end

% replace appdata with original subplot position 
if ~isempty(appData.SubplotGridLocation)
    setappdata(newax,'SubplotGridLocation', appData.SubplotGridLocation);
end
if ~isempty(appData.SubplotPosition)
    setappdata(newax,'SubplotPosition', appData.SubplotPosition);
end

if ~isempty(appData.SubplotGrid)
    ind = appData.SubplotInd;
    ind = flipud(ind); % subplot grid is upside down
    ind = ind'; % subplot counts row-major not col-major like matrices
    if any(ind(:))
        [m,n] = size(appData.SubplotGrid);
        p = find(ind(:));
        % deleting the outgoing axes can make subplot re-discover
        % axes/charts to manage, including newax, so defer parenting
        % until subplot call.
        newax.Parent = [];
        delete(ax);
        subplot(m,n,p,newax,'Parent',parent);
        fig = ancestor(parent,'figure');
        if ~isempty(fig)
            set(fig,'CurrentAxes',newax);
        end
    elseif isgraphics(ax)
        delete(ax);
    end
end

% Delete ax last (rather than earlier where potentially invalidated) to support
% special toolbox plot behaviors that clean up after themselves.
if isgraphics(ax)
    delete(ax);
end

function restoreColorbar(cb,loc)
if(isvalid(cb))
    cb.Location = loc;
end



function restoreLegend(leg,loc)
if(isvalid(leg))
    leg.Location = loc;
end



