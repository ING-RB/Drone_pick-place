function removeAxesFromGrid(p, ax)
% This function is undocumented and will change in a future release

%   Copyright 2010-2018 The MathWorks, Inc.

%   Remove ax from grid of subplots in p
    if ~isempty(p)
        grid = getappdata(p, 'SubplotGrid');
        if ~isempty(grid)
            n = grid == ax;
            if any(n(:))
                rmappdata(ax, 'SubplotPosition');
                if isappdata(ax, 'SubplotGridLocation')
                    rmappdata(ax, 'SubplotGridLocation');
                end
                if (isa(ax,'matlab.graphics.chart.internal.SubplotPositionableChart') || ...
                    isa(ax,'matlab.graphics.chart.internal.PositionableChartWithAxes'))    
                    ax.resetSubplotLayoutInfo();
                end
                matlab.graphics.internal.removeFromListeners(p, ax);
                grid(n) = matlab.graphics.GraphicsPlaceholder;
                list = grid(:);
                list(~ishghandle(list)) = [];
                if isempty(list)
                    rmappdata(p, 'SubplotGrid');
                    lookForNewGrid(p)
                else
                    setappdata(p, 'SubplotGrid', grid);
                end
            end
        end
        
%   Remove ax from spangrid subplots in p
        spanGrid = getappdata(p, 'SubplotSpanGrid');
        if ~isempty(spanGrid)
            n = spanGrid == ax;
            if any(n(:))
                rmappdata(ax, 'SubplotPosition');
                if isappdata(ax, 'SubplotGridLocation')
                    rmappdata(ax, 'SubplotGridLocation');
                end
                matlab.graphics.internal.removeFromListeners(p, ax);
                spanGrid(n) = matlab.graphics.GraphicsPlaceholder;
                list = spanGrid(:);
                list(~ishghandle(list)) = [];
                if isempty(list)
                    rmappdata(p, 'SubplotSpanGrid');
                else
                    setappdata(p, 'SubplotSpanGrid', spanGrid);
                end
            end
        end
        
        % If there are no more grid axes or span grid axes, then
        % remove the SubplotListenersManager from the parent 
        spanGrid(~ishghandle(spanGrid)) = [];
        grid(~ishghandle(grid)) = [];
        if isempty(spanGrid(:)) && isempty(grid(:))     
            if(isappdata(p, 'SubplotListenersManager'))
                lm = getappdata(p, 'SubplotListenersManager');
                if ~lm.hasManagedTitle() 
                    rmappdata(p, 'SubplotListenersManager');
                end
            end
        end
        
    end
end

function lookForNewGrid(p)
    sibs = p.Children;
    newgrid = [];
    for i = 1 : length(sibs)
        ax = sibs(i);
        if (isa(ax,'matlab.graphics.axis.AbstractAxes') ||...
                isa(ax,'matlab.graphics.chart.Chart')) && ~isappdata(ax,'NonDataObject')
            loc = getappdata(ax,'SubplotGridLocation');
            if length(loc) >= 3 && isscalar(loc{3})
                axgrid = [loc{1} loc{2}];
                if isempty(newgrid) || isequal(newgrid, axgrid)
                    subplot(loc{1},loc{2},loc{3},ax);
                    newgrid = axgrid;
                end
            end
        end
    end
end
