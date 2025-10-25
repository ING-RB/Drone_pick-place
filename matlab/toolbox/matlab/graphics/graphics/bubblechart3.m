function hh=bubblechart3(varargin)
%BUBBLECHART3 3-D Bubble chart.
%   BUBBLECHART3(x,y,z,sz) displays circular markers (bubbles) at the
%   locations specified by the vectors x, y, and z in a three-dimensional
%   plot box. Specify the size of the bubbles as the vector sz. The vectors
%   x, y, z, and sz must be the same size. The sz vector specifies the area
%   of each bubble based on a mapping in the current axes to marker size.
%   Use the BUBBLELIM and BUBBLESIZE functions to control this mapping.
%
%   BUBBLECHART3(x,y,z,sz,c) sets the marker colors using c. When c is a
%   vector the same length as x, y, and z, the values in c are linearly
%   mapped to the colors in the current colormap. When c is a length(x)-by-3
%   matrix, it specifies the colors of the markers as RGB triplet values.
%   c can also be a character vector containing a color name, such as 'red'.
%
%   BUBBLECHART3(tbl,xvar,yvar,zvar,szvar) creates a bubble chart with the
%   variables xvar, yvar, zvar, and szvar from table tbl. Multiple bubble
%   charts are created if xvar, yvar, zvar, or szvar reference multiple
%   variables. For example, this command creates two bubble charts:
%   bubblechart3(tbl,'var1',{'var2', 'var3'},'var4','var5')
%
%   BUBBLECHART3(tbl,xvar,yvar,zvar,szvar,colorvar) specifies the color of
%   the bubble charts with the table variable colorvar.
%
%   BUBBLECHART3(...,Name,Value) sets bubble chart properties using one or
%   more name-value pair arguments. For example:
%   BUBBLECHART3(x,y,z,sz,c,'MarkerEdgeColor','k') uses a black outline for
%   the markers.
%
%   BUBBLECHART3(ax,...) specifies the target axes instead of the current
%   axes.
%
%   bc = BUBBLECHART3(...) returns the BubbleChart object. Use b to set
%   properties on the chart after creating it.
%
%   Example:
%      x = rand(1,50);
%      y = rand(1,50);
%      z = rand(1,50);
%      sz = rand(1,50);
%      bubblechart3(x,y,z,sz)
%
%   See also BUBBLELIM, BUBBLESIZE, BUBBLELEGEND, BUBBLECHART,
%   POLARBUBBLECHART, SCATTER3, VIEW

%   Copyright 2020-2022 The MathWorks, Inc.

import matlab.graphics.chart.internal.inputparsingutils.peelFirstArgParent
import matlab.graphics.chart.internal.inputparsingutils.splitPositionalFromPV
import matlab.graphics.chart.internal.inputparsingutils.getParent
import matlab.graphics.chart.internal.inputparsingutils.prepareAxes
import matlab.graphics.chart.primitive.internal.findMatchingDimensions

matlab.graphics.chart.internal.DDUXLogger(mfilename,varargin);
narginchk(4,inf);

args = varargin;
[parent, args] = peelFirstArgParent(args);

istable = istabular(args{1});
[posargs, pvpairs] = splitPositionalFromPV(args, 4 + istable, true);

hasColor = numel(posargs) == 5 + istable;

if istable
    dataSource = matlab.graphics.data.DataSource(posargs{1});
    dataMap = matlab.graphics.data.DataMap(dataSource);
    dataMap = dataMap.addChannel('X', posargs{2});
    dataMap = dataMap.addChannel('Y', posargs{3});
    dataMap = dataMap.addChannel('Z', posargs{4});
    dataMap = dataMap.addChannel('Size', posargs{5});
    if hasColor
        dataMap = dataMap.addChannel('Color', posargs{6});
    end

    matlab.graphics.chart.primitive.BubbleChart.validateData(dataMap);
else
    [msg, posargs{1}, posargs{2}, posargs{3}, posargs{4}] = findMatchingDimensions(posargs{1}, posargs{2}, posargs{3}, posargs{4});
    if ~isempty(msg)
        error(message('MATLAB:scatter:InvalidXYZSizeData'));
    end

    nPoints = height(posargs{1});
    nObjects = width(posargs{1});
    
    if hasColor
        posargs{5} = validatecdata(posargs{5}, nPoints, nObjects);
        hasColor = hasColor && ~isempty(posargs{5});
    end
    posargs(1:3) = matlab.graphics.chart.internal.getRealData(posargs(1:3), true);
    posargs(4:end) = matlab.graphics.chart.internal.getRealData(posargs(4:end), false);
end

matlab.graphics.internal.validatePartialPropertyNames(...
    'matlab.graphics.chart.primitive.BubbleChart', pvpairs(1:2:end));
[parent, hasParent] = getParent(parent, pvpairs, 2);
[parent, ancestorAxes] = prepareAxes(parent, hasParent, false);

if istable
    nObjects = dataMap.NumObjects;
    h = gobjects(1, nObjects);
    for i = 1:nObjects
        sliceStruct = dataMap.slice(i);

        if ~isempty(ancestorAxes)
            x = dataSource.getData(sliceStruct.X);
            y = dataSource.getData(sliceStruct.Y);
            z = dataSource.getData(sliceStruct.Z);
            matlab.graphics.internal.configureAxes(ancestorAxes, x{1}, y{1}, z{1});
        end

        pvcolor={};
        if hasColor
            pvcolor = {'ColorVariable' sliceStruct.Color};
        end

        h(i) = matlab.graphics.chart.primitive.BubbleChart( ...
            'SourceTable', dataSource.Table, ...
            'XVariable', sliceStruct.X, 'YVariable', sliceStruct.Y, ...
            'ZVariable', sliceStruct.Z, 'SizeVariable', sliceStruct.Size, ...
            pvcolor{:}, pvpairs{:}, 'Parent', parent);

        h(i).assignSeriesIndex();
    end
else
    cdatapair = {};
    if hasColor 
        cdatapair = {'CData' posargs{5}};
    end
    
    h = gobjects(1, nObjects);
    if ~isempty(ancestorAxes)
        matlab.graphics.internal.configureAxes(ancestorAxes, posargs{1}, posargs{2}, posargs{3});
    end
    for i = 1:nObjects
        if hasColor && isequal(size(posargs{5}), [nObjects 3])
            cdatapair = {'CData' posargs{5}(i,:)};
        end
    
        h(i) = matlab.graphics.chart.primitive.BubbleChart( ...
            'XData', posargs{1}(:,i), 'YData', posargs{2}(:,i), 'ZData', posargs{3}(:,i), ...
            'SizeData', posargs{4}(:,i), cdatapair{:}, pvpairs{:}, 'Parent', parent);
    
        h(i).assignSeriesIndex();
    end
end

try %#ok<TRYNC>
    % If the ancestor axes doesn't support box, view or grid, silently noop
    if ~isempty(ancestorAxes)
        if ismember(ancestorAxes.NextPlot, ["replace" "replaceall"])
            box(ancestorAxes, 'on');
            grid(ancestorAxes, 'on')
            view(ancestorAxes,3);
        end
    elseif strcmp(ancestorAxes.NextPlot,'replacechildren')
        view(ancestorAxes,3);
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