function showGroupingVariableChanged(hObj)
% callback function

%   Copyright 2015-2020 The MathWorks, Inc.

    hObj.Listeners{3}.Enabled = 0;
    hObj.Listeners{4}.Enabled = 0;
    hObj.Listeners{5}.Enabled = 0;
    hObj.IsInitialized = false;
    hObj.Model.updateShowGroupingVariable;
    
    loc = hObj.Model.ShowGroupingVariableIndex;
%     src.resetGroupStyle(loc);

    [tf_clr,loc_clr] = ismember('Color',hObj.GroupingVariableStyle(loc));
    if ~tf_clr || size(hObj.GroupColor,1)~=size(hObj.GroupBins{loc(loc_clr)},2)
        hObj.GroupColor = [];
    end
    [tf_mkr,loc_mkr] = ismember('MarkerType',hObj.GroupingVariableStyle(loc));    
    if ~tf_mkr || size(hObj.GroupMarker,2)~=size(hObj.GroupBins{loc(loc_mkr)},2)
        hObj.GroupMarker = {};
    end
    [tf_mkrsize,loc_tf_mkrsize] = ismember('MarkerSize',hObj.GroupingVariableStyle(loc));
    if ~tf_mkrsize || size(hObj.GroupMarkerSize,2)~=size(hObj.GroupBins{loc(loc_tf_mkrsize)},2)
        hObj.GroupMarkerSize = [];
    end
    [tf_lstyle,loc_lstyle] = ismember('LineStyle',hObj.GroupingVariableStyle(loc));   
    if ~tf_lstyle || size(hObj.GroupLineStyle,2)~=size(hObj.GroupBins{loc(loc_lstyle)},2)
        hObj.GroupLineStyle = {};
    end
    hObj.Model.updateData;
    hObj.Model.updateStyle;
    hObj.IsInitialized = true;
    hObj.Listeners{3}.Enabled = 1;
    hObj.Listeners{4}.Enabled = 1;
    hObj.Listeners{5}.Enabled = 1;
    hObj.createPlot;
    hObj.updateScatterPlot;
    hObj.updatePlot;
end
