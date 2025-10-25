function createPeripheralPlot(hObj)
% boxplot/histogram/ksplot

%   Copyright 2015-2020 The MathWorks, Inc.

% removePeripheralAxes first
if hObj.ShowView
    boxPlot = hObj.BoxPlot;
    hist = hObj.Histogram;
    ksplot = hObj.KernelDensityPlot;
    
    if hObj.XvsX && strcmpi(hist,'None') && hObj.HistUsingDefault &&...
            sum(strcmpi({boxPlot,hist,ksplot},'Diagonal'))==0
        hist = 'Diagonal';
        hObj.Histogram_I = hist;
    end
    
    grpIdx = hObj.Model.GroupIndex;
    clr = hObj.Model.Style{1};
    if ~strcmpi(boxPlot,'None')
        if any(strcmpi(boxPlot,{'Left','Right'}))
            orientation = 'vertical';
        else
            orientation = 'horizontal';
        end
        func = @(ax,x)boxplot(ax,x,grpIdx,'orientation',orientation,'color',clr);
        localPeripheralPlot(hObj,func,boxPlot);
        
        if strcmpi(boxPlot,'Diagonal')
            % remove overlapped tick
            hboxplot = findobj(hObj.Parent,'Tag','boxplot');
            for i = 1:length(hboxplot)
                hboxplot(i).Parent.XTick = [];
                hboxplot(i).Parent.YTick = [];
            end
        end
    end
    if ~strcmpi(hist,'None')
        if all(grpIdx==1)
            dispstyle = 'bar';
        else
            dispstyle = 'stair';
        end
        if any(strcmpi(hist,{'Left','Right'}))
            orientation = 'horizontal';
        else
            orientation = 'vertical';
        end
        func = @(ax,x)statslib.internal.plotGroupedHist(x,grpIdx,...
            'AxisHandle',ax,'Color',clr,'DisplayStyle',dispstyle,...
            'Orientation',orientation,'Norm','probability');
        localPeripheralPlot(hObj,func,hist);
    end
    if ~strcmpi(ksplot,'None')
        if any(strcmpi(ksplot,{'Left','Right'}))
            orientation = 'horizontal';
        else
            orientation = 'vertical';
        end
        func = @(ax,x)internal.stats.plotGroupedKSDensity(x,grpIdx,...
            'AxisHandle',ax,'Color',clr,'Orientation',orientation,...
            'AxisOn',true,'Norm',true);
        localPeripheralPlot(hObj,func,ksplot);
    end
end
end

function localPeripheralPlot(hObj,plotfun,position)
x = hObj.Model.X;
y = hObj.Model.Y;
nr = hObj.Model.NumRows;
nc = hObj.Model.NumColumns;
ag = hObj.Axes;
if strcmpi(position,'Diagonal')
    ag.DiagonalAxesSharing = 'XOnly';
    axes = ag.getAxes;
    for i = 1:nr
        diagnalAxes(i) = axes(i,i);
    end
    localplot(nr,diagnalAxes,plotfun,x);
elseif strcmpi(position,'Bottom')
    ag.addPeripheralAxes('Bottom');
    peripheralAxes = ag.getPeripheralAxes('Bottom');
    localplot(nc,peripheralAxes,plotfun,x);
elseif strcmpi(position,'Top')
    ag.addPeripheralAxes('Top');
    peripheralAxes = ag.getPeripheralAxes('Top');
    localplot(nc,peripheralAxes,plotfun,x);
elseif strcmpi(position,'Left')
    ag.addPeripheralAxes('Left');
    peripheralAxes = ag.getPeripheralAxes('Left');
    localplot(nr,peripheralAxes,plotfun,y);
elseif strcmpi(position,'Right')
    ag.addPeripheralAxes('Right');
    peripheralAxes = ag.getPeripheralAxes('Right');
    localplot(nr,peripheralAxes,plotfun,y);
end
end

function localplot(n,axes,plotfun,x)
for i = 1:n
    set(axes(i).Parent,'CurrentAxes',axes(i));
    set(axes(i).Parent,'NextPlot','add');
    set(axes(i),'NextPlot','add');
    xi = x(:,i);
    if iscell(xi)
        xi = xi{:}; % trellisplot
    end
    plotfun(axes(i),xi);
end
end
