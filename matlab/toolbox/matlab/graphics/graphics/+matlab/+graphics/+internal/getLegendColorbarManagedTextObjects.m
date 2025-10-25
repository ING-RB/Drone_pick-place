function out = getLegendColorbarManagedTextObjects(inputObjs)
% getLegendColorbarManagedTextObjects retrieves handles to Legend and
% Colorbar titles and labels. Used by FONTSIZE and FONTNAME. This file is 
% for internal use only and may change in a future release of MATLAB.

%   Copyright 2021 The MathWorks, Inc.
axesObjs = findobj(inputObjs,'-isa','matlab.graphics.axis.AbstractAxes');
axesLegCB = get(axesObjs,{'Legend','Colorbar','BubbleLegend'});
if iscell(axesLegCB)
    axesLegCB = [axesLegCB{:}];
end
inputObjs = unique([axesLegCB(:); inputObjs(:)]);
legendObjs = findall(inputObjs,'-isa','matlab.graphics.illustration.internal.AbstractChartIllustration');
colorbarObjs = findall(inputObjs,'-isa','matlab.graphics.illustration.ColorBar');

legendManaged = getLegendManagedObjects(legendObjs);
colorbarManaged = getColorbarManagedObjects(colorbarObjs);

out = unique([legendManaged,colorbarManaged]);
end

%%
function objs = getLegendManagedObjects(legendObjs)
objs = [];
if ~isempty(legendObjs)
    objs = get(legendObjs, 'Title_I');
    if iscell(objs)
        objs = [objs{:}];
    end
end
end

%%
function objs = getColorbarManagedObjects(colorbarObjs)
objs = [];
if ~isempty(colorbarObjs) 
    cbTitles = get(colorbarObjs, 'Title_I');
    if iscell(cbTitles)
        cbTitles = [cbTitles{:}];
    end

    cbLabels = get(colorbarObjs,'Label_I');
    if iscell(cbLabels)
        cbLabels = [cbLabels{:}];
    end

    objs = [cbTitles cbLabels];
end
end