function resetPeripheraPlot(hObj,tag,type)
%

%   Copyright 2015-2020 The MathWorks, Inc.

if hObj.ShowView
    if strcmpi(tag,'histogram')
        h = findobj(hObj.Parent,'Type','Histogram');
    else
        h = findobj(hObj.Parent,'Tag',tag);
    end
    if ismember(hObj.(type),{'Top','Bottom','Left','Right'})
        ag = hObj.Axes;
        ag.removePeripheralAxes(hObj.(type));
    end
    delete(h);
    hObj.HistUsingDefault = 0;
end
end
