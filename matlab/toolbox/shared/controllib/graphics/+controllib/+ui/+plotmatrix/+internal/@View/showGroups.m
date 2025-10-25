function showGroups(hObj)
%

%   Copyright 2015-2020 The MathWorks, Inc.

if hObj.ShowView
    showgrp = hObj.ShowGroups;
    idx_showgv = hObj.Model.ShowGroupingVariableIndex;
    showgrp = showgrp(idx_showgv);
    gvstyle = hObj.GroupingVariableStyle;
    gvstyle = gvstyle(idx_showgv);
    ag = hObj.Axes;
    axes = ag.getAxes;
    
    hl = findobj(axes,'Tag','groupLine');
    set(hl,'Visible','on');
    
    [tf_clr, loc_clr] = ismember('Color',gvstyle);
    if tf_clr
        setVisibility(hObj,showgrp,loc_clr,'Color',axes);
    end
    
    [tf_mkr, loc_mkr] = ismember('MarkerType',gvstyle);
    if tf_mkr
        setVisibility(hObj,showgrp,loc_mkr,'Marker',axes);
    end
    
    [tf_ms, loc_ms] = ismember('MarkerSize',gvstyle);
    if tf_ms
        setVisibility(hObj,showgrp,loc_ms,'MarkerSize',axes);
    end
    
    [tf_lstyle, loc_lstyle] = ismember('LineStyle',gvstyle);
    if tf_lstyle
        setVisibility(hObj,showgrp,loc_lstyle,'LineStyle',axes);
    end
    
    [tf_axis, loc_axis] = ismember({'XAxis','YAxis'},gvstyle);
    if any(tf_axis)
        if loc_axis(1)
            locx = find(~showgrp{loc_axis(1)});
        else
            locx = [];
        end
        if loc_axis(2)
            locy = find(~showgrp{loc_axis(2)});
        else
            locy = [];
        end
        nxg = hObj.Model.NumXAxisLevel;
        nyg = hObj.Model.NumYAxisLevel;
        ag = hObj.Axes;
        ag.AxesVisibility(:,:) = {'on'};
        for i = 1:numel(locx)
            ag.AxesVisibility(:,locx(i):nxg:end) = {'off'};
        end
        for i = 1:numel(locy)
            ag.AxesVisibility(locy(i):nyg:end,:) = {'off'};
        end
    end
    %hist/boxplot/ksplot
end
end

function setVisibility(hObj,showgrp,loc,style,axes)
loc_off = find(~showgrp{loc});
for i = 1:numel(loc_off)
    if strcmpi(style,'Color')
        value = hObj.GroupColor(loc_off(i),:);
    elseif strcmpi(style,'Marker')
        value = hObj.GroupMarker{loc_off(i)};
    elseif strcmpi(style,'MarkerSize')
        value = hObj.GroupMarkerSize(loc_off(i));
    else
        value = hObj.GroupLineStyle{loc_off(i)};
    end
    hl = findobj(axes,'Tag','groupLine',style,value);
    set(hl,'Visible','off');
end
end
