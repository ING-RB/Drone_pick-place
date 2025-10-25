function changeChartPosition(obj)
%

%   Copyright 2020 The MathWorks, Inc.

% Callback that runs whenever the chart's position has changed.

ar=obj.computeAspectRatio;
ip=obj.Axes.InnerPosition_I;
lims=[obj.Axes.XLim_I obj.Axes.YLim_I];
if obj.AspectRatio~=ar
    obj.AspectRatio=ar;
    obj.LayoutDirty=true;
else
    if ~isequal(ip,obj.InnerPositionCache) 
        obj.setMarkerSize;
    elseif ~isequal(lims,obj.LimitsCache)
        % The limits have changed due to a pan or zoom. Because zoom can 
        % change the DataAspectRatio, enforce an unchanged DAR by growing
        % one of the limits.
        
        oldDAR=diff(obj.LimitsCache(1:2))/diff(obj.LimitsCache(3:4));
        newDAR=diff(lims(1:2))/diff(lims(3:4));
        
        if oldDAR<newDAR
            % The newDAR is wider than the old, expand the Y
            newyspan=diff(lims(1:2))/oldDAR;
            amountToPad=newyspan-diff(lims(3:4));
            obj.Axes.YLim=[lims(3)-amountToPad/2 lims(4)+amountToPad/2];
        elseif oldDAR>newDAR 
            % The newDAR is taller than the old, expand the X
            newxspan=diff(lims(3:4))*oldDAR;
            amountToPad=newxspan-diff(lims(1:2));
            obj.Axes.XLim=[lims(1)-amountToPad/2 lims(2)+amountToPad/2];            
        end
        obj.setMarkerSize;
    end
end
end