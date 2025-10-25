function hh=bubblechart(varargin)
%BUBBLECHART Bubble chart.
%   BUBBLECHART(x,y,sz) displays colored circular markers (bubbles) at the
%   locations specified by the vectors x and y. Specify the size of the
%   bubbles as the vector sz. The vectors x, y, and sz must be the same
%   size. The sz vector specifies the area of each bubble based on a
%   mapping in the current axes to marker size. Use the BUBBLELIM and
%   BUBBLESIZE functions to control this mapping.
%
%   BUBBLECHART(x,y,sz,c) sets the marker colors using c. When c is a
%   vector the same length as x and y, the values in c are linearly mapped
%   to the colors in the current colormap. When c is a length(x)-by-3
%   matrix, it directly specifies the colors of the markers as RGB triplet
%   values. c can also be a character vector containing a color name, such
%   as 'red'.
%
%   BUBBLECHART(tbl,xvar,yvar,szvar) creates a bubble chart with the
%   variables xvar, yvar, and szvar from table tbl. Multiple bubble charts
%   are created if xvar, yvar, or szvar reference multiple variables. For
%   example, this command creates two bubble charts:
%   bubblechart(tbl, 'var1', {'var2', 'var3'}, 'var4')
%
%   BUBBLECHART(tbl,xvar,yvar,szvar,colorvar) specifies the color of the
%   bubble charts with the table variable colorvar.
%
%   BUBBLECHART(...,Name,Value) sets bubble chart properties using one or
%   more name-value pair arguments. For example:
%   BUBBLECHART(x,y,sz,'MarkerEdgeColor','k') uses a black outline for the
%   markers.
%
%   BUBBLECHART(ax,...) specifies the target axes instead of the current
%   axes.
%
%   bc = BUBBLECHART(...) returns the BubbleChart object. Use bc to set
%   properties on the chart after creating it.
%
%   Example:
%      x = rand(1,50);
%      y = rand(1,50);
%      sz = rand(1,50);
%      bubblechart(x,y,sz)
%
%   See also BUBBLELIM, BUBBLESIZE, BUBBLELEGEND, BUBBLECHART3,
%   POLARBUBBLECHART, SCATTER

%   Copyright 2020-2022 The MathWorks, Inc.

import matlab.graphics.chart.internal.inputparsingutils.peelFirstArgParent
import matlab.graphics.chart.internal.inputparsingutils.splitPositionalFromPV
import matlab.graphics.chart.internal.inputparsingutils.getParent
import matlab.graphics.chart.internal.inputparsingutils.prepareAxes
import matlab.graphics.chart.primitive.internal.findMatchingDimensions

matlab.graphics.chart.internal.DDUXLogger(mfilename,varargin);
narginchk(3,inf);

args = varargin;
[parent, args] = peelFirstArgParent(args);

istable = istabular(args{1});
[posargs, pvpairs] = splitPositionalFromPV(args, 3 + istable, true);

hasColor = numel(posargs) == 4 + istable;

if istable
    dataSource = matlab.graphics.data.DataSource(posargs{1});
    dataMap = matlab.graphics.data.DataMap(dataSource);
    dataMap = dataMap.addChannel('X', posargs{2});
    dataMap = dataMap.addChannel('Y', posargs{3});
    dataMap = dataMap.addChannel('Size', posargs{4});
    if hasColor
        dataMap = dataMap.addChannel('Color', posargs{5});
    end

    matlab.graphics.chart.primitive.BubbleChart.validateData(dataMap);
else
    [msg, posargs{1}, posargs{2}, posargs{3}] = findMatchingDimensions(posargs{1}, posargs{2}, posargs{3});

    if ~isempty(msg)
        error(message('MATLAB:scatter:InvalidXYSizeData','X','Y'));
    end

    nPoints = height(posargs{1});
    nObjects = width(posargs{1});
    if hasColor
        posargs{4} = validatecdata(posargs{4}, nPoints, nObjects);
        hasColor = hasColor && ~isempty(posargs{4});
    end
    posargs(1:2) = matlab.graphics.chart.internal.getRealData(posargs(1:2), true);
    posargs(3:end) = matlab.graphics.chart.internal.getRealData(posargs(3:end), false);
end


[parent, hasParent] = getParent(parent, pvpairs, 2);
propNames = pvpairs(1:2:end);

% In the case of explicit non-Cartesian axes parents (e.g. polar/geo axes),
% skip validation for 'renamed' property names.
if ~isempty(propNames) && hasParent && ...
        isa(parent, 'matlab.graphics.axis.AbstractAxes') && ...
        ~isa(parent, 'matlab.graphics.axis.Axes')

    propNames = matlab.graphics.chart.primitive.internal.abstractscatter.removeRenamedPropertyNames(...
        propNames, parent.DimensionNames);
end

matlab.graphics.internal.validatePartialPropertyNames(...
    'matlab.graphics.chart.primitive.BubbleChart', propNames);
[parent, ancestorAxes] = prepareAxes(parent, hasParent, false);

if istable
    nObjects = dataMap.NumObjects;
    h = gobjects(1, nObjects);
    for i = 1:nObjects
        sliceStruct = dataMap.slice(i);

        if ~isempty(ancestorAxes)
            x = dataSource.getData(sliceStruct.X);
            y = dataSource.getData(sliceStruct.Y);
            matlab.graphics.internal.configureAxes(ancestorAxes, x{1}, y{1});
        end

        pvcolor={};
        if hasColor
            pvcolor = {'ColorVariable' sliceStruct.Color};
        end

        h(i) = matlab.graphics.chart.primitive.BubbleChart( ...
            'Parent', parent, ...
            'SourceTable', dataSource.Table, ...
            'XVariable', sliceStruct.X, 'YVariable', sliceStruct.Y, ...
            'SizeVariable', sliceStruct.Size, ...
            pvcolor{:}, pvpairs{:});

        h(i).assignSeriesIndex();
    end
else
    cdatapair = {};
    if hasColor 
        cdatapair = {'CData' posargs{4}};
    end
    h = gobjects(1, nObjects);
    if ~isempty(ancestorAxes)
        matlab.graphics.internal.configureAxes(ancestorAxes, posargs{1}, posargs{2});
    end

    for i = 1:nObjects
        if hasColor && isequal(size(posargs{4}), [nObjects 3])
            cdatapair = {'CData' posargs{4}(i,:)};
        end
    
        h(i) = matlab.graphics.chart.primitive.BubbleChart( ...
            'XData', posargs{1}(:,i), 'YData', posargs{2}(:,i), 'SizeData', posargs{3}(:,i), ...
            cdatapair{:}, pvpairs{:}, 'Parent', parent);
    
        h(i).assignSeriesIndex();
    end
end

if ~isempty(ancestorAxes) && ...
        ismember(ancestorAxes.NextPlot, ["replace" "replaceall"])
    try %#ok<TRYNC>
        % If the ancestor axes doesn't support box or view, silently noop
        ancestorAxes.Box = 'on';
        view(ancestorAxes,2);
    end
end

if isempty(h)
    h = matlab.graphics.chart.primitive.BubbleChart.empty(1,0);
end

if nargout>0
    hh = h;
end

end


function c=validatecdata(c, npoints, nobjects)
try
    if ischar(c) || isstring(c)
        % colorspec or hex color
        c = validatecolor(c, 'one');
        ncolors = 1;
    elseif isnumeric(c) && ismatrix(c) && size(c,2)==3
        % RGB color
        c = validatecolor(c, 'multiple');
        ncolors = size(c, 1);
    elseif isvector(c)
        % Colormapped color
        ncolors = numel(c);
    else
        error(message('MATLAB:bubble:InvalidCData'))
    end

    isscalarrgb = isequal(size(c),[1 3]);
    if nobjects ~= 1
        assert((ncolors == nobjects && ~isvector(c)) || isscalarrgb, message('MATLAB:bubble:InvalidCDataSeries'));
    elseif npoints == 0
        assert(ncolors==0 || isscalarrgb, message('MATLAB:bubble:InvalidCData'));
    else
        assert(ncolors == npoints || isscalarrgb, message('MATLAB:bubble:InvalidCData'))
    end
catch me
    if isequal(me.identifier, 'MATLAB:bubble:InvalidCDataSeries')
        throwAsCaller(me);
    else
        throwAsCaller(MException(message('MATLAB:bubble:InvalidCData')));
    end
end

end


