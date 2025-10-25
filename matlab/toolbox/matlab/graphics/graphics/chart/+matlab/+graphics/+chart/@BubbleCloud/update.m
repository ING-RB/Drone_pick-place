function update(obj)
%

%   Copyright 2020-2024 The MathWorks, Inc.

% Update method for BubbleCloud, checks various dirty flags and dispatches
% to more specific methods

if ~isempty(obj.GroupData_I) && numel(obj.GroupData_I) ~= numel(obj.SizeData_I)
    warningstatus = warning('OFF', 'BACKTRACE');
    warning(message('MATLAB:graphics:bubblecloud:PropertySizeMismatch','GroupData','SizeData'))
    warning(warningstatus);
    return
end
if ~isempty(obj.LabelData_I) && (numel(obj.LabelData_I) ~= numel(obj.SizeData_I))
    warningstatus = warning('OFF', 'BACKTRACE');
    warning(message('MATLAB:graphics:bubblecloud:PropertySizeMismatch','LabelData','SizeData'))
    warning(warningstatus);
    return
end

figureAncestor = [];

if obj.ColorOrderMode == "auto"
    co = get(obj,'DefaultAxesColorOrder');
    coMode = get(obj,'DefaultAxesColorOrderMode');
    if coMode == "auto"
        tc = ancestor(obj,'matlab.graphics.mixin.ThemeContainer');
        if isa(tc, 'matlab.ui.Figure')
            figureAncestor = tc;
        end
        if ~isempty(tc) && ~isempty(tc.Theme)
            co = matlab.graphics.internal.themes.getAttributeValue(tc.Theme,'DiscreteColorList');
        end
    end    
    % ColorOrder_I is AbortSet, but will flip the ColorsDirty flag if the 
    % colors are different.
    obj.ColorOrder_I = co;
    obj.ColorOrderMode = coMode;
end

if isempty(figureAncestor)
    figureAncestor = ancestor(obj,'figure');
end
obj.FigureAncestorForPlotEditListener = figureAncestor;

if obj.LegendVisible
    obj.Legend.Visible='on';
    obj.Legend.Location='northeastoutside';
else
    obj.Legend.Visible='off';
    obj.Legend.Location='none';
end
obj.Legend.Title.String=obj.LegendTitle;

if obj.RadiiDirty
    obj.computeRadii;

    obj.LayoutDirty=true;
    obj.ColorsDirty=true;
    obj.RadiiDirty=false;
end

if obj.LayoutDirty
    % Update x,y positions in obj.XYR
    obj.layoutBubbles;

    % Mark Clean
    obj.LayoutDirty=false;

    obj.setMarkerVertices;

    % When colors are dirty, set them before setting MarkerSize,
    % so that the legend's impact on plotbox is included when
    % MarkerSize is set
    if obj.ColorsDirty
        obj.setMarkerColor;
        obj.ColorsDirty=false;
    end

    % Query InnerPosition to force autocalc update. Important
    % to do this before setAxesLimits and setMarkerSize.
    obj.Axes.InnerPosition;
    obj.setAxesLimits;
    obj.setMarkerSize;
end
if obj.LabelsDirty
    obj.setTextStringsAndVertices;
    obj.LabelsDirty=false;
end
if obj.ColorsDirty
    obj.setMarkerColor;
    obj.ColorsDirty=false;
end
end

% LocalWords:  bubblecloud northeastoutside XYR plotbox autocalc
