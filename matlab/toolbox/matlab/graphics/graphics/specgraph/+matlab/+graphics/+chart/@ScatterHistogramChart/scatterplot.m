function hh = scatterplot(ax,x,y,g,gn,clr,sym,siz,xnam,ynam,...
    grpname,filled,alpha,sh)
%SCATTERPLOT   Scatter plot with grouping variable

%   Copyright 2018-2024 The MathWorks, Inc.
%   Based upon stats.internal.iscatter

if ~isempty(g)
    ng = max(g);
else
    gn = [];
    ng = 1;
end

% Call the plotting routine
cla(ax);
hh = plotscatter(ax,x,y,g,clr,sym,siz,filled,alpha);

% Iterate over each group and store data for datatips
for idx=1:ng
    % Add behavior object to markers, to customize datatip text
    bh = hggetbehavior(hh(idx),'DataCursor');
    bh.UpdateFcn = {@gscatterDatatipCallback,xnam,ynam,grpname,sh};
    bh.Enable = 0;
    
    setappdata(hh(idx),'group',idx);
    if ~isempty(gn)
        setappdata(hh(idx),'groupname',gn(idx));
    end
    if ~isempty(g)
        gind = find(g==idx);
        setappdata(hh(idx),'gind',gind);
    end
    addlistener(hh(idx),'Hit',@(e,d) sh.showContextMenu(d));
end

% Store information for gname
set(ax, 'UserData', {'gscatter' x y g});

function datatipTxt = gscatterDatatipCallback(~,evt,xnam,ynam,grpname,sh)

target = get(evt,'Target');
ind = get(evt,'DataIndex');
pos = get(evt,'Position');

group = getappdata(target,'group');
groupname = getappdata(target,'groupname');
gind = getappdata(target,'gind');

if isempty(xnam)
    xnam = 'X';
end
if isempty(ynam)
    ynam = 'Y';
end

% xnam and ynam are nx1 cellstr if the table contained "newlines". The
% newline was converted to separate cellstr by assigning to XLabel. Add
% newline again so that the xnam appears across multiple lines.
if iscellstr(xnam)
    xnam = join(xnam,newline);
    xnam = xnam{:};
end
if iscellstr(ynam)
    ynam = join(ynam,newline);
    ynam = ynam{:};
end

if isempty (gind)
    % One group
    % Leave group name alone, it may be empty
    % Line index number is the same as the original row
    obsind = ind;
else
    % Multiple groups
    % If group name not given, assign it its number
    if isempty(groupname)
        groupname = num2str(group);
    end
    % Map line index to the original row
    obsind = gind(ind);
end

[texLabelFormat, texValueFormat] = ...
    matlab.graphics.chart.ScatterHistogramChart.getTexLabelAndValueFormat(target);
datatipTxt = '';
if sh.UsingTableForData
    dtVarnames = sh.getDataTipVariables();
    srcTable = sh.SourceTable;
    for i = 1:numel(dtVarnames)
        % We use first dimension names of the table instead of always using
        % hard-coded 'Row' string. The first dimension name of the table is
        % usually 'Row' unless user customizes it. This was done to avoid
        % conflicting table column name 'Row' which user can possbily do
        % when customizing the first dimension name of the table.
        if strcmp(srcTable.Properties.DimensionNames{1},dtVarnames{i}) && ...
                isa(srcTable,'table') && isempty(srcTable.Properties.RowNames)
            % If the RowNames is empty, we show table row number by
            % default in the data tip
            valueToDisplay = obsind;
        else
            valueToDisplay = srcTable.(dtVarnames{i})(obsind,:);
        end
        
        formattedValue = matlab.graphics.datatip.internal.formatDataTipValue(valueToDisplay,'auto');
        datatipTxt{end+1} = ...
            [texLabelFormat, dtVarnames{i},' ',texValueFormat, formattedValue]; %#ok<AGROW>
    end
else
    if iscategorical(target.XData)
        x = char(target.XData(ind));
    else
        x = num2str(pos(1),4);
    end
    
    if iscategorical(target.YData)
        y = char(target.YData(ind));
    else
        y = num2str(pos(2),4);
    end
    
    % Get strings from message catalogue
    rowStr = getString(message('MATLAB:Chart:DatatipRow'));
    groupStr = getString(message('MATLAB:Chart:DatatipGroup'));
    
    datatipTxt = {...
        [texLabelFormat,xnam,' ',texValueFormat,x]...
        [texLabelFormat,ynam,' ',texValueFormat,y]...
        [texLabelFormat,rowStr,' ',texValueFormat,num2str(obsind)]
        };
    
    if ~isempty(groupname)
        if isempty(grpname)
            grpname = groupStr;
        end
        datatipTxt{end+1} = [texLabelFormat,num2str(grpname),' ',texValueFormat,num2str(groupname)];
    end
end

function h = plotscatter(ax,x,y,g,c,m,msize,filled,alpha)
%PLOTSCATTER   Scatter plot grouped by index vector.

ni = max(g); % number of groups
if isempty(ni)
    g = ones(size(x,1),1);
    ni = 1;
end

isMarkerFilled = strcmp(filled,'on');

% Set the XAxis/YAxis to the appropriate ruler
matlab.graphics.internal.configureAxes(ax,x,y);

% Now draw the plot
h = gobjects(ni,1);
for idx=1:ni
    % Find indices for each group
    ii = (g == idx);
    
    % Make a scatter plot
    h(idx) = matlab.graphics.chart.primitive.Scatter('Parent',ax, ...
        'XData',x(ii),'YData',y(ii),'SizeData',msize(idx),'CData',c(idx,:), ...
        'Marker',m(idx),'MarkerEdgeAlpha',alpha(idx),'MarkerFaceAlpha',alpha(idx));
    
    % Add a face color if requested
    if isMarkerFilled
        h(idx).MarkerFaceColor = 'flat';
    end
end
