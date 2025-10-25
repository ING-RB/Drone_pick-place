function [nBins,binW,maxValue,hXLines] = plotGroupedHist(ax,x,grpID,gname,nbins,clr,ls,lw,bw,varargin)  
%PLOTGROUPEDHIST   Plot histograms per group

%   Copyright 2018-2025 The MathWorks, Inc.
%   Based upon stats.internal.plotGroupedHist

if isempty(grpID)
    grpID = ones(size(x));
end

% Remove missing data
wasNaN = isnan(grpID);
x(wasNaN) = [];
if isempty(x)
    return;
end
grpID(wasNaN) = [];
grp = unique(grpID); % unique integer group labels
nGrp = numel(grp); % total number of groups

if isscalar(nbins)
   nbins = repmat(nbins,nGrp,1); 
end

% Clear the axes
cla(ax);
set(ax,'NextPlot','replaceChildren');

% Iterate over each group and create a separate histogram for each one
hXLines = gobjects(1,nGrp);
nBins = zeros(1,nGrp);
binW = zeros(1,nGrp);
% Store the maximum pdf value and use it in doUpdate to set the histogram
% axes YLim
maxValue = zeros(1,nGrp);
for idx = 1:nGrp
    % Get the data corresponding to the present group
    xg = x(grpID == grp(idx));
    
    % Different arguments need to be passed in for categorical data
    if iscategorical(x)
        % Must use convenience function for categorical data in order to 
        % get correct results
        hXLines(idx) = histogram(ax,xg,varargin{:});
        hold(ax,'on');
        ax.XTick = [];
        
        % Get the number of bins from the histograms
        nBins(idx) = hXLines(idx).NumDisplayBins;
    else
        % Pass NumBins and BinWidths depending on which (if either) have
        % been specified by the user.
        if isempty(bw) && isempty(nbins)
            hXLines(idx) = matlab.graphics.chart.primitive.Histogram...
               ('Parent',ax,'Data',xg,'LineStyle',ls(idx),...
               'LineWidth',lw(idx),varargin{:});
        elseif isempty(nbins) && ~isempty(bw)
           hXLines(idx) = matlab.graphics.chart.primitive.Histogram...
               ('Parent',ax,'Data',xg,'BinWidth',bw(idx),'LineStyle',ls(idx),...
               'LineWidth',lw(idx),varargin{:});
        elseif isempty(bw) && ~isempty(nbins)
            hXLines(idx) = matlab.graphics.chart.primitive.Histogram...
                ('Parent',ax,'Data',xg,'NumBins',nbins(idx),'LineStyle',ls(idx),...
               'LineWidth',lw(idx),varargin{:});
        else
            % This should never happen. Both nbins and bw would not be
            % known simultaneously in this function, since the setter for
            % NumBins will set BinWidths to empty and vice versa.
            % Otherwise pass both NumBins and BinWidths and let histogram
            % decide the optimum match between the two.
            hXLines(idx) = matlab.graphics.chart.primitive.Histogram...
                ('Parent',ax,'Data',xg,'NumBins',nbins(idx),'LineStyle',ls(idx),...
               'LineWidth',lw(idx),'BinWidth',bw(idx),varargin{:});
        end
        
        % Get the number of bins from the histograms
        nBins(idx) = hXLines(idx).NumBins;
        binW(idx) = hXLines(idx).BinWidth;
    end
    maxValue(idx) = max([hXLines(idx).Values,0]);
    
    % Add behavior object to lines, to customize datatip text
    bh = hggetbehavior(hXLines(idx),'DataCursor');
    bh.UpdateFcn = @groupedhistDatatipCallback;
    bh.Enable = 0;
    
    % Passing EdgeColor, FaceColor and DisplayStyle to histogram does not
    % always lead to what we want. Best to set color post creation of
    % histogram
    if strcmpi(hXLines(1).DisplayStyle,'stairs')
        hXLines(idx).EdgeColor = clr(idx,:);
    else
        hXLines(idx).FaceColor = clr(idx,:);
    end
    
    % Store the groupname if it has been specified
    if ~isempty(gname)
        setappdata(hXLines(idx),'groupname',gname(idx));
    end
end
% Return the maxValue of the pdf
maxValue = max(maxValue);

% Set the axes to tight if the data is numeric
isVerticalOrientation = strcmpi(hXLines(1).Orientation,'vertical');
if isVerticalOrientation
    baseAxis = 'XAxis'; 
    baseLim = 'XLim';
else
    baseAxis = 'YAxis';
    baseLim = 'YLim';
end
if isnumeric(x)
    matlab.graphics.internal.configureRuler(ax,baseAxis(1),double(strcmp(baseAxis,'YAxis')),x)
    minx = min(x); 
    maxx = max(x);
    if minx ~= maxx && ~(isnan(minx)&&isnan(maxx))
        ax.(baseLim) = [minx,maxx];
    end
    ax.(baseAxis).Visible = 'on';
    ax.(baseAxis).TickValues = [];
elseif iscategorical(x) % The data is categorical
    c = categories(x);
    if ~isempty(c) 
        ax.(baseLim) = [c(1),c(end)];
    end
end
end

% Internal function that computes the datatip text for histograms
function datatipTxt = groupedhistDatatipCallback(target,evt)
groupname = getappdata(target,'groupname');
if target.Orientation == "vertical"
    x = evt.Position(1);
    y = evt.Position(2);
else
    y = evt.Position(1);
    x = evt.Position(2);
end

[texLabelFormat, texValueFormat] = ...
    matlab.graphics.chart.ScatterHistogramChart.getTexLabelAndValueFormat(target);

% Get strings from message catalogue
countStr = getString(message('MATLAB:Chart:DatatipCount'));
valueStr = getString(message('MATLAB:Chart:DatatipValue'));
groupStr = getString(message('MATLAB:Chart:DatatipGroup'));
categoryStr = getString(message('MATLAB:Chart:DatatipCategory'));
binEdgesStr = getString(message('MATLAB:Chart:DatatipBinEdges'));

% For numeric data show the count, pdf value, and bin edges
if isnumeric(target.Data)
    be = get(target,'BinEdges');
    binAndLeftEdgeIdx = find(be < x, 1, 'last');
    xL = be(binAndLeftEdgeIdx);
    xR = be(find(x < be, 1, 'first'));
    bcVal = target.BinCounts(binAndLeftEdgeIdx);
    datatipTxt = [strcat(texLabelFormat,countStr," ",texValueFormat,int2str(bcVal));...
                  strcat(texLabelFormat,valueStr," ",texValueFormat,num2str(y,4));...
                  strcat(texLabelFormat,binEdgesStr,texValueFormat," [",num2str(xL)," ",num2str(xR),"]")];
else
    % If data is categorical show the name, count and pdf value
    datatipTxt = [strcat(texLabelFormat,categoryStr," ",texValueFormat,target.Categories(x));...
                  strcat(texLabelFormat,countStr," ",texValueFormat,int2str(target.BinCounts(x)));...
                  strcat(texLabelFormat,valueStr," ",texValueFormat,num2str(y,4))];
end
% Show group name if it exists
if ~isempty(groupname)
    datatipTxt = [datatipTxt;strcat(texLabelFormat,groupStr," ",texValueFormat,groupname)];
end
datatipTxt = char(datatipTxt);
end
