function axesMoved(~, evdata, parent)
% This function is undocumented and will change in a future release

%   Copyright 2010-2020 The MathWorks, Inc.

%   Callback when axes moves to remove it from subplot layout grid,
    if isa(evdata,'matlab.graphics.chart.internal.OuterPositionChangedEventData')
        ax=evdata.Source;
    else
    	ax = evdata.AffectedObject;
    end

	% If the legend or colorbar is causing the move, do not remove the axes
	% from the subplot grid. Do, however, update it's cached position:
	if (isappdata(ax, 'inLayout') && ~isempty(getappdata(ax, 'inLayout'))) || ...
			isappdata(ax, 'LegendColorbarReclaimSpace')
		setappdata(ax, 'SubplotPosition', get(ax, 'InnerPosition'));
	else
		matlab.graphics.internal.removeAxesFromGrid(parent, ax);
	end
end