function checkPosition(hObj,position,plottype)
%

%   Copyright 2015-2020 The MathWorks, Inc.

if ~((hObj.IsInitialized && hObj.XvsX) ||...
        isempty(hObj.XVariable) || isempty(hObj.YVariable) || isequal(hObj.XVariable,hObj.YVariable)) &&...
        strcmpi(position,'Diagonal')
    error(message('Controllib:plotmatrix:XvsYDiagonalPlots',plottype));
end
if ~hObj.IsInitialized
    if sum(strcmpi({position,hObj.BoxPlot,hObj.Histogram,hObj.KernelDensityPlot},'Diagonal'))>1
        error(message('Controllib:plotmatrix:InvalidPosition','along the diagonal'));
    end
    if sum(strcmpi({position,hObj.BoxPlot,hObj.Histogram,hObj.KernelDensityPlot},'Right'))>1
        error(message('Controllib:plotmatrix:InvalidPosition','on the right'));
    end
    if sum(strcmpi({position,hObj.BoxPlot,hObj.Histogram,hObj.KernelDensityPlot},'Left'))>1
        error(message('Controllib:plotmatrix:InvalidPosition','on the left'));
    end
    if sum(strcmpi({position,hObj.BoxPlot,hObj.Histogram,hObj.KernelDensityPlot},'Bottom'))>1
        error(message('Controllib:plotmatrix:InvalidPosition','at the bottom'));
    end
    if sum(strcmpi({position,hObj.BoxPlot,hObj.Histogram,hObj.KernelDensityPlot},'Top'))>1
        error(message('Controllib:plotmatrix:InvalidPosition','on the Top'));
    end
end
