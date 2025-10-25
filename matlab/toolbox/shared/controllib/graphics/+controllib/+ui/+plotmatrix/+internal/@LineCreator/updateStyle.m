function updateStyle(this)
%

%   Copyright 2015-2020 The MathWorks, Inc.

ngv = this.View.NumGroupingVariable;
ngv_nonTrellis = ngv;
wrongGrp = this.WrongGroup;
gvstyle = this.View.GroupingVariableStyle;
idx_showgv = this.ShowGroupingVariableIndex;
idx_noshowgv = setdiff(1:ngv,idx_showgv);
ng = this.NumGroup;
nanGrp = this.NanGroup;
gname = this.GroupName_I;
any_wrongBinFlag = any(this.WrongBinFlag);

% find trellis style location and check less then 3 non-trellis style
if isempty(gvstyle)
    locTrellis = [0 0];
else
    [tfTrellis,locTrellis] = ismember({'XAxis','YAxis'},gvstyle);
    if any(tfTrellis)
        locTrellis = locTrellis(locTrellis~=0);
        ngv_nonTrellis = ngv - sum(tfTrellis);
    end
end
if ngv_nonTrellis>3
    error(message('Controllib:plotmatrix:EmptyGroupingVariableStyle'));
end

% fill the empty styles
style = this.NonTrellisStyle;
if isempty(gvstyle) && ngv>0
    gvstyle = style(1:ngv_nonTrellis);
else
    emptyStyleIdx = cellfun(@isempty,gvstyle);
    numEmptyStyle = sum(emptyStyleIdx);
    if numEmptyStyle > 0
        unusedNonTrellisStyle = setdiff(style,gvstyle,'stable');
        gvstyle(emptyStyleIdx) = unusedNonTrellisStyle(1:numEmptyStyle);
    end
end
this.View.GroupingVariableStyle = gvstyle;

idx_NonTrellis = setdiff(idx_showgv,locTrellis);
gvstyle_nonTrellis = gvstyle(idx_NonTrellis);
ngl = this.NumGroupLevel;

clr = this.View.GroupColor;
n_grpclr = size(clr,1);
[tf_clr,loc_clr] = ismember('Color',this.View.GroupingVariableStyle);
if tf_clr
    if this.View.ChangedGroupIdx(loc_clr)       
        ngl_clr = ngl(loc_clr);
        if isempty(clr)
            clr  = lGetColorMap(ngl_clr);
        else
            %There must be at least as many colors as group levels
            if n_grpclr+nanGrp(loc_clr) < ngl_clr+numel(wrongGrp{loc_clr})
                error(message('Controllib:plotmatrix:WrongNumElement','GroupColor'));
            end
            if ~this.WrongBinFlag(loc_clr) && nanGrp(loc_clr)
                clr_undefined = setdiff(lGetColorMap(ngl_clr),clr,'rows');
                clr = [clr; clr_undefined(1,:)];
            end
        end
    end
    if ~any_wrongBinFlag
        if ismember('Color',this.View.GroupingVariableStyle(idx_noshowgv))
            color = lGetColorMap(1);
            color = repmat(color,ng,1);
        else
            [~,loc_shownclr] = ismember('Color',gvstyle_nonTrellis);
            gidx_clr = gname(:,loc_shownclr);
            color(1:ng,:) = clr(gidx_clr,:);
        end
    end
else
    if ~any_wrongBinFlag
        if isempty(clr)
            clr = lGetColorMap(1);
        elseif n_grpclr~=1
            error(message('Controllib:plotmatrix:WrongNumElement','GroupColor'));
        end
        color = repmat(clr,ng,1);
    end
end
this.View.GroupColor = clr;

mkr = this.View.GroupMarker;
n_grpmarker = size(mkr,2);
[tf_marker,loc_marker] = ismember('MarkerType',this.View.GroupingVariableStyle);
if tf_marker
    if this.View.ChangedGroupIdx(loc_marker)
        ngl_marker = ngl(loc_marker);
        mkr_default = this.Marker;
        if isempty(mkr)
            mkr = statslib.internal.cycleLineProperties(ngl_marker,mkr_default);
        else
            if n_grpmarker+nanGrp(loc_marker) ~= ngl_marker+numel(wrongGrp{loc_marker})
                error(message('Controllib:plotmatrix:WrongNumElement','GroupMarker'));
            end
            if ~this.WrongBinFlag(loc_marker) && nanGrp(loc_marker)
                if n_grpmarker > 13
                    mkr_undefined = mkr_default{1}; % cycle, 4 different lstyles in total
                else
                    mkr_undefined = setdiff(mkr_default,mkr);
                    mkr_undefined = mkr_undefined(1);
                end
                mkr = [mkr mkr_undefined];
            end
        end
    end
    if ~any_wrongBinFlag
        if ismember('MarkerType',this.View.GroupingVariableStyle(idx_noshowgv))
            marker = this.Marker(1);
            marker = repmat(marker,ng,1);
        else
            [~,loc_shownmkr] = ismember('MarkerType',gvstyle_nonTrellis);
            gidx_marker = gname(:,loc_shownmkr);
            marker(1:ng) = mkr(gidx_marker);
        end
    end
else
    if ~any_wrongBinFlag
        if isempty(mkr)
            mkr = this.Marker(1);
        elseif n_grpmarker~=1
            error(message('Controllib:plotmatrix:WrongNumElement','GroupMarker'));
        end
        marker = repmat(mkr,ng,1);
    end
end
this.View.GroupMarker = mkr;

msize = this.View.GroupMarkerSize;
defaultMarkerSize = 8;
n_grpmarkersize = size(msize,2);
[tf_markersize,loc_markersize] = ismember('MarkerSize',this.View.GroupingVariableStyle);
if tf_markersize
    if this.View.ChangedGroupIdx(loc_markersize)        
        ngl_markersize = ngl(loc_markersize);
        if isempty(msize)
            msize = 4:6/(ngl_markersize-1):10;
        else
            if n_grpmarkersize+nanGrp(loc_markersize) ~= ngl_markersize+numel(wrongGrp{loc_markersize})
                error(message('Controllib:plotmatrix:WrongNumElement','GroupMarkerSize'));
            end
            if ~this.WrongBinFlag(loc_markersize) && nanGrp(loc_markersize)
                msize_undefined = setdiff(4:6/(ngl_markersize-1):10,msize);
                msize = [msize; msize_undefined(1)];
            end
        end
    end
    if ~any_wrongBinFlag       
        if ismember('MarkerSize',this.View.GroupingVariableStyle(idx_noshowgv))
            markersize = defaultMarkerSize;
            markersize = repmat(markersize,ng,1);
        else
            [~,loc_shownmsize] = ismember('MarkerSize',gvstyle_nonTrellis);
            gidx_markersize = gname(:,loc_shownmsize);
            markersize(1:ng) = msize(gidx_markersize);
        end
    end
else
    if ~any_wrongBinFlag
        if isempty(msize)
            msize = defaultMarkerSize;
        elseif n_grpmarkersize~=1
            error(message('Controllib:plotmatrix:WrongNumElement','GroupMarkerSize'));
        end
        markersize = repmat(msize,ng,1);
    end
end
this.View.GroupMarkerSize = msize;

lstyle = this.View.GroupLineStyle;
n_grplinestyle = size(lstyle,2);
[tf_linestyle,loc_linestyle] = ismember('LineStyle',this.View.GroupingVariableStyle);
if tf_linestyle
    if this.View.ChangedGroupIdx(loc_linestyle)
        ngl_linestyle = ngl(loc_linestyle);
        lstyle_default = this.LineStyle;
        if isempty(lstyle)
            lstyle = statslib.internal.cycleLineProperties(ngl_linestyle,lstyle_default);
        else
            if n_grplinestyle+nanGrp(loc_linestyle) ~= ngl_linestyle+numel(wrongGrp{loc_linestyle})
                error(message('Controllib:plotmatrix:WrongNumElement','GroupLineStyle'));
            end
            if ~this.WrongBinFlag(loc_linestyle) && nanGrp(loc_linestyle)
                if n_grplinestyle > 4
                    lstyle_undefined = lstyle_default{1}; % cycle, 4 different lstyles in total
                else
                    lstyle_undefined = setdiff(lstyle_default,lstyle);
                    lstyle_undefined = lstyle_undefined(1);
                end
                lstyle = [lstyle lstyle_undefined];
            end
        end
    end
    if ~any_wrongBinFlag
        if ismember('LineStyle',this.View.GroupingVariableStyle(idx_noshowgv))
            linestyle = {'none'};
            linestyle = repmat(linestyle,ng,1);
        else
            [~,loc_shownlstyle] = ismember('LineStyle',gvstyle_nonTrellis);
            gidx_linestyle = gname(:,loc_shownlstyle);
            linestyle(1:ng) = lstyle(gidx_linestyle);
        end
    end
else
    if ~any_wrongBinFlag
        if isempty(lstyle)
            lstyle = {'none'};
        elseif n_grplinestyle~=1
            error(message('Controllib:plotmatrix:WrongNumElement','GroupLineStyle'));
        end
        linestyle = repmat(lstyle,ng,1);
    end
end
this.View.GroupLineStyle = lstyle;

if ~any(this.WrongBinFlag)
    gstyle = {color,marker,markersize,linestyle};
    this.Style = gstyle;
end

end

function cMap = lGetColorMap(n)
%Helper to get colors.
%
%Use default axes color order to determine colors, if more colors than in
%the default list are requested append hsv() entries.
%

dMap = get(0,'DefaultAxesColorOrder');
ndMap = size(dMap,1);
if n > ndMap
    %Asking for more colors than in default list, append hsv colors
    dMap = vertcat(dMap,hsv(n-ndMap));
end
cMap = dMap(1:n,:);
end
