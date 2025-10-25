function str = getDescriptionForCartesianAxes(ax)
% Given an axes object, this function returns a string that describes the
% axes and its visible objects. The axes must be a Cartesian axes. 

%   Copyright 2021-2023 The MathWorks, Inc.

arguments
    ax (1, 1) {mustBeA(ax, 'matlab.graphics.axis.Axes')}
end

visibleObjects = findobj(ax.Children,'flat','Visible','on','-property','Type');

if ~isempty(visibleObjects)
    visibleObjectTypes = join(unique(string(get(visibleObjects,{'Type'})),'stable'),', ');
end

axesTitle = matlab.graphics.internal.screenreader.getSimplifiedStringFromText(ax.Title);

if strlength(axesTitle) == 0
    if isempty(visibleObjects)
        str = getString(message('MATLAB:graphics:figurescreenreader:UntitledSingleAxesDescriptionEmpty',ax.Type));
    else
        str = getString(message('MATLAB:graphics:figurescreenreader:UntitledSingleAxesDescriptionNonEmpty',...
            ax.Type, numel(visibleObjects), visibleObjectTypes));
        
    end
else
    if isempty(visibleObjects)
        str = getString(message('MATLAB:graphics:figurescreenreader:TitledSingleAxesDescriptionEmpty',ax.Type,axesTitle));
    else
        str = getString(message('MATLAB:graphics:figurescreenreader:TitledSingleAxesDescriptionNonEmpty',...
            ax.Type, axesTitle,numel(visibleObjects), visibleObjectTypes));
    end
end

end

