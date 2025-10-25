function [bw,maxValue,hXLines] = plotGroupedKSDensity(ax,x,grpID,gname,clr,lw,ls,ww,orientation)
%PLOTGROUPEDKSDENSITY   Plot Kernel density estimates per group

%   Copyright 2018-2025 The MathWorks, Inc.
%   Based upon stats.internal.plotGroupedKSDensity

% Calculate the XData (xrange)
[x,grpID,grp,xrange] = matlab.graphics.chart.ScatterHistogramChart.computeDensityRange...
    (x,grpID);

% Clear the axes
cla(ax);

% Obtain the function evaluations at query points along with the bin widths
% for each group
n = length(grp(~ismissing(grp)));
bw = zeros(n,1);
hXLines = gobjects(n,1);
% Store the maximum pdf value and use it in doUpdate to set the histogram
% axes limits
maxValue = zeros(n,1);
if strcmpi(orientation,'horizontal')
    baseProp = 'XData';
    valueProp = 'YData'; 
    baseLim = 'XLim';
else
    baseProp = 'YData';
    valueProp = 'XData'; 
    baseLim = 'YLim'; 
end

for idx = 1:n
    % Get the data corresponding to the present group
    xg = x(grpID == grp(idx));
    
    [px,bw] = matlab.graphics.chart.ScatterHistogramChart.computeKernelPDF...
        (xg,xrange,ww,bw,idx);
    
    % Now draw the kernel density line of each group
    hXLines(idx) = matlab.graphics.chart.primitive.Line('Parent',ax,...
        baseProp,xrange,valueProp,px);
    if ~isempty(px)
        maxValue(idx) = max(px);
    end
end
maxValue = max(maxValue);

set(hXLines,'Tag','groupedksplot');
% Set the line properties accordingly
for idx = 1:n
    set(hXLines(idx),'Color',clr(idx,:),'LineWidth',lw(idx));
    if ~isempty(ls)
        set(hXLines(idx),'LineStyle',ls(idx));
    end
    if ~isempty(gname)
        setappdata(hXLines(idx),'groupname',gname(idx));
    end
    setappdata(hXLines(idx),'bandwidth',bw(idx));
    
    % Add behavior object to lines, to customize datatip text
    bh = hggetbehavior(hXLines(idx),'DataCursor');
    bh.UpdateFcn = @(target,evt)groupedksdenDatatipCallback(target,evt,orientation);
    bh.Enable = 0;
end

% Set the x-axis to tight
minx = min(x); 
maxx = max(x);
if ~(isempty(minx)) && (minx ~= maxx) && ~(isnan(minx)&&isnan(maxx))
    ax.(baseLim) = [minx,maxx];
end
end

function datatipTxt = groupedksdenDatatipCallback(target,evt,orientation)
if orientation == "horizontal"
    y = evt.Position(2);
else
    y = evt.Position(1);
end
bw = getappdata(target,'bandwidth');
target = get(evt,'Target');
groupname = getappdata(target,'groupname');

[texLabelFormat, texValueFormat] = ...
    matlab.graphics.chart.ScatterHistogramChart.getTexLabelAndValueFormat(target);

% Get strings from message catalogue
valueStr = getString(message('MATLAB:Chart:DatatipValue'));
groupStr = getString(message('MATLAB:Chart:DatatipGroup'));
bandwidthStr = getString(message('MATLAB:Chart:DatatipBandwidth'));

datatipTxt = [strcat(texLabelFormat,valueStr," ",texValueFormat,num2str(y,4));...
              strcat(texLabelFormat,bandwidthStr," ",texValueFormat,num2str(bw,4))];
if ~isempty(groupname)
    datatipTxt = [datatipTxt;strcat(texLabelFormat,groupStr," ",texValueFormat,groupname)];
end
datatipTxt = char(datatipTxt);
end