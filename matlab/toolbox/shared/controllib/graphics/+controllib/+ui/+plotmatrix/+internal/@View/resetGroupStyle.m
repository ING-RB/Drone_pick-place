function resetGroupStyle(hObj,loc)
% used by callback functions

%   Copyright 2015-2020 The MathWorks, Inc.

if ~ismember('Color',hObj.GroupingVariableStyle(loc))
    hObj.GroupColor = [];
end
if ~ismember('MarkerType',hObj.GroupingVariableStyle(loc))
    hObj.GroupMarker = {};
end
if ~ismember('MarkerSize',hObj.GroupingVariableStyle(loc))
    hObj.GroupMarkerSize = [];
end
if ~ismember('LineStyle',hObj.GroupingVariableStyle(loc))
    hObj.GroupLineStyle = {};
end
end
