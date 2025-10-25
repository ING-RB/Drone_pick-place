function ax = prepareCoordinateSystem(classname, parent, constructor)
% This is an undocumented function and may be removed in a future release.

%   Copyright 2015-2023 The MathWorks, Inc.

%   Prepare an axes or chart for use in a convenience function for chart
%   construction (e.g., heatmap), or for placing a data object in an axes
%   (e.g., polarscatter).
%
%   Inputs
%   ------
%   classname: Class name of chart/axes to be created
%     ('polar' accepted as shorthand for PolarAxes)
%
%   parent: Either parent container for axes/chart,
%     or existing axes/chart within the parent container
%
%   constructor (optional for polar axes): Function handle to
%     chart/axes constructor function, prepending varargin to
%     any user-supplied arguments
%
%   Output
%   ------
%   ax: Axes or chart object, ready for use.
%
%   See also newplot

    narginchk(1,3);

    if (nargin < 2) || isempty(parent) || ~isgraphics(parent)
        parent = setupParent();
    end

    if nargin < 3 && strcmp(classname, 'polar')
        constructor = @polaraxes;
        classname = 'matlab.graphics.axis.PolarAxes';
    end

    creatingChart = any(ismember(superclasses(classname),'matlab.graphics.chart.Chart'));
    if ~creatingChart && isa(parent, 'matlab.graphics.mixin.CurrentAxes')
        % The supplied parent is a valid Current Axes (an axes or chart).
        % When used via polarplot and related function, current axes may be
        % the user-supplied parent.
        currentAxes = parent;
    else
        % Find an existing axes or chart within the specified parent that
        % will be reused or replaced.
        currentAxes = matlab.graphics.chart.internal.getAxesInParent(parent, false);
    end

    if isempty(currentAxes)
        % No current axes or no existing axes in parent container
        ax = constructor('Parent',parent);
    elseif isa(currentAxes, classname) && ~creatingChart && currentAxes.isHoldSupported()
        % Outgoing current axes is same type as the new object and it
        % supports hold, so no replacement needed.
        ax = currentAxes;
    elseif isa(currentAxes, 'matlab.graphics.mixin.CurrentAxes') && currentAxes.isHoldEnabled()
        % Outgoing object has hold enabled.
        if strcmp(classname,'matlab.graphics.axis.PolarAxes')
            error(message('MATLAB:newplot:HoldOnMixingPolar', currentAxes.Type));
        else
            cname = strsplit(classname,'.');
            error(message('MATLAB:newplot:HoldOnMixingAxesGeneric',cname{end}, currentAxes.Type));
        end
    else
        % Outgoing "axes" is an AbstractAxes with hold off, or is a chart.
        ax = matlab.graphics.internal.swapaxes(currentAxes, constructor);
    end
end

function parent = setupParent()

    import matlab.graphics.chart.internal.inputparsingutils.observeFigureNextPlot

    fig = observeFigureNextPlot(gcf);
    ca = fig.CurrentAxes;
    if ~isempty(ca)
        parent = ca.Parent;
    else
        parent = fig;
    end
end
