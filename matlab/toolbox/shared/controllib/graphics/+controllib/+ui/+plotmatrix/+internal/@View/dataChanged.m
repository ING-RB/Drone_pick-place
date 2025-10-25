function dataChanged(hObj)
%

%   Copyright 2015-2020 The MathWorks, Inc.

lenListeners = length(hObj.Listeners);
for i = 1:lenListeners
    hObj.Listeners{i}.Enabled = false;
end
oldGroupBins = hObj.GroupBins;
oldLabels = hObj.GroupLabels;
oldShowgrp = hObj.ShowGroups;
oldGroupingVariableStyle= hObj.GroupingVariableStyle;
oldGroupColor = hObj.GroupColor;
oldGroupMarker = hObj.GroupMarker;
oldGroupMarkerSize = hObj.GroupMarkerSize;
oldGroupLineStyle = hObj.GroupLineStyle;

hObj.GroupBins_I = cell(1,hObj.NumGroupingVariable);
hObj.GroupLabels_I = cell(1,hObj.NumGroupingVariable);
hObj.ShowGroups_I = cell(1,hObj.NumGroupingVariable);
for i = 1:hObj.NumGroupingVariable
    if ismember('Color',hObj.GroupingVariableStyle(i))
        hObj.GroupColor_I = [];
    end
    if ismember('MarkerType',hObj.GroupingVariableStyle(i))
        hObj.GroupMarker_I = {};
    end
    if ismember('MarkerSize',hObj.GroupingVariableStyle(i))
        hObj.GroupMarkerSize_I = [];
    end
    if ismember('LineStyle',hObj.GroupingVariableStyle(i))
        hObj.GroupLineStyle_I = {};
    end
end
hObj.IsInitialized = false;
if hObj.UsingDefaultGVLabel == true
    hObj.GroupingVariableLabels_I = hObj.GroupingVariable;
end
if hObj.ShowView
    interp = hObj.Axes.Interpreter;
end
sz = hObj.NumGroupingVariable;
hObj.GroupLabels = cell(1,sz);
hObj.ShowGroups = cell(1,sz);

hObj.Model = controllib.ui.plotmatrix.internal.LineCreator(hObj);
hObj.GroupBins = hObj.Model.GroupBins;

% unchanged grouping variable
loc = hObj.ChangedGroupingVariableIndex ~= sort(hObj.GroupingVariableIndex);
if any(loc)
    hObj.ChangedGroupIdx = ~loc;
end

if any(loc)
    hObj.GroupLabels(loc) = oldLabels(loc);
    hObj.ShowGroups(loc) = oldShowgrp(loc);
    hObj.GroupBins(loc) = oldGroupBins(loc);
end

%% Update group style

% First set the group styles to empty
hObj.resetGroupStyle(loc);

StyleChanged = false(4,1);

% For each grouping variable, if the bin definition exists, use the style
% previously specified by user. Else, use the style given by Line Creator.
for i = 1:length(loc)
    binIdxI = i;
    if iscell(hObj.GroupBins{binIdxI}) % categorical grouping variable
        unchangedGroupIndex = ismember(hObj.GroupBins{binIdxI},oldGroupBins{binIdxI});
        changedLength = sum(~unchangedGroupIndex);
        oldIndex = ismember(oldGroupBins{binIdxI},hObj.GroupBins{binIdxI});
    else % continuous grouping variable
        unchangedGroupIndex = ismember(hObj.GroupBins{binIdxI},oldGroupBins{binIdxI},'rows');
        changedLength = sum(~unchangedGroupIndex);
        oldIndex = ismember(oldGroupBins{binIdxI},hObj.GroupBins{binIdxI},'rows');
    end
    hObj.GroupLabels{binIdxI}(unchangedGroupIndex) = oldLabels{binIdxI}(oldIndex);
    hObj.ShowGroups{binIdxI}(unchangedGroupIndex) = oldShowgrp{binIdxI}(oldIndex);
    style = oldGroupingVariableStyle{i};
    if strcmpi(style,'Color')
        if ~isempty(hObj.GroupColor) 
            changedColor = setdiff(hObj.GroupColor,oldGroupColor(oldIndex,:),'rows');
            hObj.GroupColor(unchangedGroupIndex,:) = oldGroupColor(oldIndex,:);
            hObj.GroupColor(~unchangedGroupIndex,:) = changedColor(1:changedLength,:);
            StyleChanged(1) = true;
        end
    elseif strcmpi(style,'MarkerType')
        changedMaker = setdiff(hObj.GroupMarker,oldGroupMarker(oldIndex));
        hObj.GroupMarker(unchangedGroupIndex) = oldGroupMarker(oldIndex); 
        hObj.GroupMarker(~unchangedGroupIndex) = changedMaker(1:changedLength);
        StyleChanged(2) = true;
    elseif strcmpi(style,'MarkerSize')
        changedSize = setdiff(hObj.GroupMarkerSize,oldGroupMarkerSize(oldIndex));
        hObj.GroupMarkerSize(unchangedGroupIndex) = oldGroupMarkerSize(oldIndex);
        hObj.GroupMarkerSize(~unchangedGroupIndex) = changedSize(1:changedLength);
        StyleChanged(3) = true;
    elseif strcmpi(style,'LineStyle')
        changedLineStyle = setdiff(hObj.GroupLineStyle,oldGroupLineStyle(oldIndex));   
        hObj.GroupLineStyle(unchangedGroupIndex) = oldGroupLineStyle(oldIndex);
        hObj.GroupLineStyle(~unchangedGroupIndex) = changedLineStyle(1:changedLength);
        StyleChanged(4) = true;
    end
end

% If a style was not used in GroupingVariableStyle, keep the old
% definition.
if ~StyleChanged(1)
    hObj.GroupColor = oldGroupColor;
end
if ~StyleChanged(2)
    hObj.GroupMarker = oldGroupMarker;
end
if ~StyleChanged(3)
    hObj.GroupMarkerSize = oldGroupMarkerSize;
end
if ~StyleChanged(4)
    hObj.GroupLineStyle = oldGroupLineStyle;
end

% Update style checks to make sure that the GroupingVariableStyle and
% GroupStyle are of the right size, and update the Line creator's style
% property.
hObj.Model.updateStyle;

hObj.IsInitialized = true;
if hObj.ShowView
    hObj.createPlot;
    hObj.updateScatterPlot;
    hObj.updatePlot;
    hObj.Axes.Interpreter = interp;
end

for i = 1:lenListeners
    hObj.Listeners{i}.Enabled = true;
end

end
