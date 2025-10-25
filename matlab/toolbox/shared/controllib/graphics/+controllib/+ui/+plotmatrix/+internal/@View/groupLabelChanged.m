function groupLabelChanged(hObj) 
% callback function

%   Copyright 2015-2020 The MathWorks, Inc.

if any(ismember(hObj.GroupingVariableStyle,{'XAxis','YAxis'}))
    hObj.updatePlot;
end
% update legend
end
