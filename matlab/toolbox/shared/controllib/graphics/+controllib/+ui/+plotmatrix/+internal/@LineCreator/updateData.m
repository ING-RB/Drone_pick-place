function updateData(this)
%

%   Copyright 2015-2020 The MathWorks, Inc.

any_wrongBinFlag = any(this.WrongBinFlag);
tbl = this.View.Data;
% nanGrp = this.NanGroup;
% tbl(nanGrp,:) = [];
xvar = this.View.XVariable;
yvar = this.View.YVariable;
XvsX = this.View.XvsX;
ng = this.NumGroup_I;
grpIdx = this.GroupIndex_Show;

gvstyle = this.View.GroupingVariableStyle;
idx_showgv = this.ShowGroupingVariableIndex;
if ~isempty(gvstyle)
    gvstyle = gvstyle(idx_showgv);
    [tf_trellis, loc_trellis] = ismember({'XAxis','YAxis'},gvstyle);
end
if ~isempty(gvstyle) && any(tf_trellis)
    this.Trellis = true;
else
    this.Trellis = false;
    if size(ng,2)>1
        if isvector(grpIdx)
            gname = grpIdx;
            grpIdx = 1;
            ng = 1;
        else
            [grpIdx,~,gname,~,ng] = statslib.internal.mgrp2idx(grpIdx);
        end
    else
        gname = unique(grpIdx);
    end
end

% X vs X
if isempty(xvar) || isempty(yvar) || isequal(xvar,yvar) || ~isempty(XvsX)&&(XvsX==1)
    if this.Trellis
        error(message('Controllib:plotmatrix:InvalidTrellis'));
    end
    if ~isempty(xvar)
        tbl = tbl(:,xvar);
    elseif ~isempty(yvar)
        tbl = tbl(:,yvar);
    else
        gvar = this.View.GroupingVariable;
        tbl(:,gvar)=[];
    end
    this.View.XVariable = tbl.Properties.VariableNames;
    this.View.YVariable = tbl.Properties.VariableNames;
    this.View.XvsX = true;
    datetimeTbl = varfun(@isdatetime,tbl,'OutputFormat','uniform');
    this.XDatetimeIndex = find(datetimeTbl==1);
    this.YDatetimeIndex = this.XDatetimeIndex;
    if any(datetimeTbl)
        tbl = datetime2num(tbl,datetimeTbl);
    end
    numericTbl = varfun(@isnumeric,tbl,'OutputFormat','uniform');
    if ~all(numericTbl)
        error(message('Controllib:plotmatrix:InvalidData'));
    end
    if any_wrongBinFlag % check error and return
        return;
    end
    x = tbl{:,:};
    this.X = x;
    this.Y = x;
    nr = size(x,2);
    %     if nr == 1 % histogram in this case? end
    nc = nr;
    ngT = 1;
    nTrellisAxes = 1;
else % X Vs Y
    this.View.XvsX = false;
    if any_wrongBinFlag
        return;
    end
    n = size(tbl,1);
    x = tbl(:,xvar);
    y = tbl(:,yvar);
    datetimeX = varfun(@isdatetime,x,'OutputFormat','uniform');
    datetimeY = varfun(@isdatetime,y,'OutputFormat','uniform');
    this.XDatetimeIndex = find(datetimeX==1);
    this.YDatetimeIndex = find(datetimeY==1);
    if any(datetimeX)
        x = datetime2num(x,datetimeX);
    end
    if any(datetimeY)
        y = datetime2num(y,datetimeY);
    end
    x = x{:,:};
    y = y{:,:};
    nx = size(x,2);
    ny = size(y,2);
    if this.Trellis
        %         if nx>1 || ny>1
        %             error('XAxis and YAxis are only supported when XVariable and YVariable are scalars');
        %         end
        ngl = this.NumGroupLevel;
        ngl = ngl(idx_showgv);
        
        xaxisIdx = loc_trellis(1);
        yaxisIdx = loc_trellis(2);
        this.XAxisIndex = xaxisIdx;
        this.YAxisIndex = yaxisIdx;
        trellisIdx = [];
        
        if yaxisIdx~=0
            ngy = ngl(yaxisIdx);
            this.NumYAxisLevel = ngy;
            nr = ny*ngy;
            trellisIdx = [trellisIdx yaxisIdx];
            yTgrp = grpIdx(:,yaxisIdx);
            yy = cell(1,nr);
            for i = 1:ny
                yi = y(:,i);
                for j = 1:ngy
                    yy{(i-1)*ngy+j} = yi(yTgrp == j);
                end
            end
            this.Y = yy;
            this.X = x;
        else
            nr = ny;
        end
        if xaxisIdx~=0
            ngx = ngl(xaxisIdx);
            this.NumXAxisLevel = ngx;
            nc = nx*ngx;
            trellisIdx = [trellisIdx xaxisIdx];
            xTgrp = grpIdx(:,xaxisIdx);
            xx = cell(1,nc);
            for i = 1:nx
                xi = x(:,i);
                for j = 1:ngx
                    xx{(i-1)*ngx+j} = xi(xTgrp == j);
                end
            end
            this.X = xx;
            if isempty(this.Y)
                this.Y = y;
            end
        else
            nc = nx;
        end
        nontrellisIdx = setdiff(1:numel(ngl),trellisIdx);
        nonTrellisGroup = grpIdx(:,nontrellisIdx);
        trellisGroup = grpIdx(:,trellisIdx);
        if numel(nonTrellisGroup)>=1
            [grpIdx,~,gname,~,ng] = statslib.internal.mgrp2idx(nonTrellisGroup);
        else
            grpIdx = ones(n,1);
            gname = 1;
            ng = 1;
        end
        if size(trellisGroup,2)>=1
            [grpIdxT,~,gnameT,~,ngT] = statslib.internal.mgrp2idx(trellisGroup);
        end
        nTrellisAxes = prod(ngl(trellisIdx));
    else
        this.X = x;
        this.Y = y;
        nr = ny;
        nc = nx;
        grpIdxT = ones(n,1);
        ngT = 1;
        nTrellisAxes = 1;
    end
end

% AxesLocation
if ngT<nTrellisAxes  % some group combinations do not exist, only for trellis plot
    gidx0 = cellfun(@str2num,gnameT);
    gidx = zeros(size(gidx0,1)*ng,2);
    for i = 1:ng
        gidx(i:ng:end,:) = gidx0;
    end
    if nx>1 || ny>1
        ridx = gidx(:,1);
        cidx = gidx(:,2);
        nr0 = max(ridx);
        nc0 = max(cidx);
        ngidx = size(gidx,1);
        location = zeros(ngidx*nx*ny,2);
        k = 1;
        for i = 1:ny
            for j = 1:nx
                location((k-1)*ngidx+1:k*ngidx,:) = [ridx+nr0*(i-1),cidx+nc0*(j-1)];
                k = k + 1;
            end
        end
    else
        location = gidx;
    end
else
    [row,col] = meshgrid(1:nr,1:nc);
    if this.View.XvsX
        idx = find(row==col);
        row(idx) = [];
        col(idx) = [];
    end
    locationId = [row(:),col(:)];
    location = zeros(size(locationId,1)*ng,2);
    for i = 1:ng
        location(i:ng:end,:) = locationId;
    end
end

% XData and YData
if this.View.XvsX
    nl = size(location,1);
    xdata = cell(1,nl);
    ydata = cell(1,nl);
    gdata = zeros(1,nl);
    for i = 1:nl
        xxdata = x(:,location(i,2));
        yydata = x(:,location(i,1));
        g = mod(i,ng);
        g(g==0) = ng;
        xdata{i} = xxdata(grpIdx == g);
        ydata{i} = yydata(grpIdx == g);
        gdata(i) = g;
    end
else
    xdata = cell(1,nx*ngT*ng);
    ydata = cell(1,ny*ngT*ng);
    for i = 1:nx    %number of variable
        xi = x(:,i);
        idxI = (i-1)*ngT*ng;
        for j = 1:ngT   %trellis group
            idxT = (j-1)*ng;
            for k = 1:ng    % nonTrellis group
                xdata{idxI+idxT+k} = xi(grpIdxT==j & grpIdx==k);
            end
        end
    end
    for i = 1:ny
        yi = y(:,i);
        idxI = (i-1)*ngT*ng;
        for j = 1:ngT
            idxT = (j-1)*ng;
            for k = 1:ng
                ydata{idxI+idxT+k} = yi(grpIdxT==j & grpIdx==k);
            end
        end
    end
    
    if nx>1 && ny>1
        xdata = repmat(xdata,1,ny);
        yydata = [];
        for i = 1:ny
            yy = repmat(ydata((i-1)*ng*ngT+1:i*ng*ngT),1,nx);
            yydata = [yydata yy];
        end
        ydata = yydata;
    elseif ny>nx
        xdata = repmat(xdata,1,ny/nx);
    elseif nx>ny
        ydata = repmat(ydata,1,nx/ny);    
    end
    
    gdata = repmat(1:ng,1,nr*nc); % group index for each line
end

this.XData = xdata;
this.YData = ydata;
this.GroupData = gdata;
this.NumRows = nr;
this.NumColumns = nc;
this.AxesLocation = location;
if iscell(gname)
    gname = cellfun(@str2num,gname);
end
this.GroupName_I = gname;
this.NumGroup = ng;
this.GroupIndex = grpIdx;
end

function x = datetime2num(x,datetimeX)
idx = (datetimeX == 1);
vname = x.Properties.VariableNames(idx);
for i = 1:size(vname,2)
    x.(vname{i})=datenum(x.(vname{i}));
end
end

