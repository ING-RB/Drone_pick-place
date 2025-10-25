function out = getAxesManagedTextObjects(inputObjs)
% getAxesManagedTextObjects retrieves handles to Axes children and named
% children that have font properties. This includes rulers, labels and 
% titles. Used by FONTSIZE and FONTNAME. This file is for internal use only 
% and may change in a future release of MATLAB.

%   Copyright 2021 The MathWorks, Inc.

axesObjs = findobj(inputObjs,'-isa','matlab.graphics.axis.AbstractAxes');
axesManaged = getAxesManagedObjects(axesObjs);

% For any rulers not managed by the provided axes, find their respective 
% managed objects.
rulerObjs = findobj(inputObjs,'-isa','matlab.graphics.axis.decorator.AxisRulerBase');
rulerObjs = rulerObjs(~ismember(rulerObjs, axesManaged));
rulerManaged = getRulerManagedObjects(rulerObjs);

out = unique([axesManaged,rulerManaged]);
end
%%
function objs = getAxesManagedObjects(axesObjs)
objs = [];
if ~isempty(axesObjs)
   
    % Get Rulers via the NodeChildren of the DecorationContainer.
    % This strategy allows us to get rulers regardless of axes type.
    dc = get(axesObjs,'DecorationContainer');
    if iscell(dc)
        dc = [dc{:}];
    end
    nodeChildren = get(dc,'NodeChildren');
    if iscell(nodeChildren)
        % Note that vertcat is required in this case because the cell array
        % is composed of cells containing column vectors of objects.
        nodeChildren = vertcat(nodeChildren{:});
    end
    rulers = findall(nodeChildren,'-isa','matlab.graphics.axis.decorator.AxisRulerBase');

    % special check for yyaxis
    cartesianAxes = findobj(axesObjs,'-isa','matlab.graphics.axis.Axes');
    yrulers = get(cartesianAxes,'YAxis');
    if iscell(yrulers)
        yrulers = vertcat(yrulers{:});
    end
    rulers = unique([rulers', yrulers']);

    rulerLabels = getRulerManagedObjects(rulers);

    % Get title & subtitle
    titles = get(axesObjs,{'Title_IS','Subtitle_IS'});
    if iscell(titles)
        titles = [titles{:}];
    end

    objs = [objs rulers rulerLabels titles];
end
end

%%
function objs = getRulerManagedObjects(rulers)
objs = [];
if ~isempty(rulers)
    objs = get(rulers,{'Label_IS','SecondaryLabel_IS'});
    if iscell(objs)
        objs = [objs{:}];
    end
end
end