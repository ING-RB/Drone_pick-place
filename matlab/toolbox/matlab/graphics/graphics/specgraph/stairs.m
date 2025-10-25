function [xo,yo] = stairs(varargin)
%STAIRS Stairstep graph
%   STAIRS(Y) draws a stairstep graph of the elements in Y.
%
%   STAIRS(X,Y) plots the elements in Y at the locations specified by X.
%   The inputs X and Y must be vectors or matrices of the same size.
%   Additionally, X can be a row or column vector and Y must be a matrix
%   with length(X) rows.
%
%   STAIRS(___,LineSpec) specifies a line style, marker symbol, and color.
%   For example, ':*r' specifies a dotted red line with asterisk markers.
%   Use this option with any of the input argument combinations in the
%   previous syntaxes.
%
%   STAIRS(tbl,xvar,yvar) plots the variables xvar and yvar from the table
%   tbl. To plot one data set, specify one variable for xvar and one
%   variable for yvar. To plot multiple data sets, specify multiple
%   variables for xvar, yvar, or both. If both arguments specify multiple
%   variables, they must specify the same number of variables.
%
%   STAIRS(tbl,yvar) plots the specified variable from the table against
%   the row indices of the table. If the table is a timetable, the
%   specified variable is plotted against the row times of the timetable.
%
%   STAIRS(___,Name,Value) modifies the stairstep chart using one or more
%   name-value pair arguments. For example, 'Marker','o','MarkerSize',8
%   specifies 8 point circle markers.
%
%   STAIRS(ax,___) plots into the axes specified by ax instead of into the
%   current axes (gca). The option, ax, can precede any of the input
%   argument combinations in the previous syntaxes.
%
%   h = STAIRS(___) returns one or more Stair objects. Use h to make
%   changes to properties of a specific Stair object after it is created.
%
%   [xb,yb] = STAIRS(___) does not create a plot, but returns matrices xb
%   and yb of the same size, such that plot(xb,yb) plots the stairstep
%   graph.
%
%   See also bar, histogram, stem.

%   L. Shure, 12-22-88.
%   Revised A.Grace and C.Thompson 8-22-90.
%   Copyright 1984-2022 The MathWorks, Inc.

import matlab.graphics.chart.internal.inputparsingutils.peelFirstArgParent
import matlab.graphics.chart.internal.inputparsingutils.splitPositionalFromPV
import matlab.graphics.chart.internal.inputparsingutils.getParent
import matlab.graphics.chart.internal.inputparsingutils.prepareAxes
import matlab.graphics.chart.internal.inputparsingutils.convertFlagsToNameValuePairs
import matlab.graphics.chart.internal.nextstyle

matlab.graphics.chart.internal.DDUXLogger(mfilename,varargin);

% Check for tables as input.
% stairs(tbl, ...) or stairs(ax, tbl, ...)
istable = (nargin > 0 && istabular(varargin{1})) ...
    || (nargin > 1 && istabular(varargin{2}));

% Check for first argument parent.
supportDoubleAxesHandle = ~istable;
[parent, args] = peelFirstArgParent(varargin, supportDoubleAxesHandle);

% Check for backward compatible version.
% [xo, yo] = stairs(...)
if (nargout == 2)
    assert(~istable, message('MATLAB:graphics:stairs:TooManyOutputsTable'));
    [xo,yo] = Lstairsv6(args{:});
    return;
end

if istable
    % stairs(tbl, yvar, ...) or stairs(tbl, xvar, yvar, ...)
    [posArgs, nvPairs] = splitPositionalFromPV(args, 2, true);
    assert(istabular(posArgs{1}), message('MATLAB:graphics:stairs:InvalidTableArguments'));
    hasXData = numel(posArgs) == 3;

    dataSource = matlab.graphics.data.DataSource(posArgs{1});
    dataMap = matlab.graphics.data.DataMap(dataSource);

    if hasXData
        dataMap = dataMap.addChannel('X', posArgs{2});
        dataMap = dataMap.addChannel('Y', posArgs{3});
    else
        dataMap = dataMap.addChannel('Y', posArgs{2});
    end
    nObjects = dataMap.NumObjects;
    objectSpecificNVPairs = cell(nObjects,0);
else
    % stairs(y, ...) or stairs(x, y, ...)
    assert(numel(args) >= 1, message('MATLAB:narginchk:notEnoughInputs'));
    [posArgs, nvPairs] = parseparams(args);
    assert(numel(posArgs)>=1, message('MATLAB:narginchk:notEnoughInputs'));
    assert(numel(posArgs)<=2, message('MATLAB:narginchk:tooManyInputs'));
    hasXData = numel(posArgs) == 2;

    % Check first of the remaining arguments to see if it is a line spec.
    nvPairs = convertFlagsToNameValuePairs(nvPairs, FillWithNone=true);

    % Check for an even number of name/value pairs.
    error(matlab.graphics.chart.internal.checkpvpairs(nvPairs));

    % Convert non-numeric data to double (if it is not datetime, duration,
    % or categorical), and get the real component of complex data.
    allowNonNumeric = true;
    posArgs = matlab.graphics.chart.internal.getRealData(posArgs,allowNonNumeric);

    % Reshape/repmat x and y so they are both equal size matrices with one
    % column per object to create.
    [msg, x, y] = xychk(posArgs{:},'plot');
    if ~isempty(msg)
        error(msg);
    end
    if isvector(x)
        x = x(:);
    end
    if isvector(y)
        y = y(:);
    end

    % Handle vectorized data sources and display names
    nObjects = size(y,2);
    objectSpecificNVPairs = cell(nObjects,0);
    if ~isempty(nvPairs) && (nObjects > 1)
        [objectSpecificNVPairs, nvPairs] = vectorizepvpairs(...
            nvPairs, nObjects, {'XDataSource','YDataSource','DisplayName'});
    end
end

% validatePartialPropertyNames normalize property names (fill-in incomplete
% names and fix case) and will throw if there are any invalid property
% names (i.e. a name that doesn't exist on Stair or is ambiguous)
propNames = matlab.graphics.internal.validatePartialPropertyNames(...
    'matlab.graphics.chart.primitive.Stair', nvPairs(1:2:end));

[parent, hasParent] = getParent(parent, nvPairs, 2);
[parent, ancestorAxes, nextplot] = prepareAxes(parent, hasParent, true);

% Call configureAxes with all the data (for matrix data). This will make
% sure the rulers are configured even if the data is empty.
if ~istable && isscalar(ancestorAxes)
    matlab.graphics.internal.configureAxes(ancestorAxes, x, y);
end

h = matlab.graphics.chart.primitive.Stair.empty(0,1);
for k = 1:nObjects
    objectNVPairs = [objectSpecificNVPairs{k,:} nvPairs];

    styleNVPairs = {};
    if isscalar(ancestorAxes)
        % Determine whether the user specified Color, LineStyle, or Marker
        % in name/value pairs (using scalar expansion).
        autoColorLineStyleMarker = ~any(propNames == ["Color"; "LineStyle"; "Marker"], 2);
        autoColor = autoColorLineStyleMarker(1);
        autoStyle = autoColorLineStyleMarker(2);

        % Generate name/value pairs for Color, LineStyle, and Marker when
        % they are not specified by the user.
        if any(autoColorLineStyleMarker)
            [l,c,m] = nextstyle(ancestorAxes, autoColor, autoStyle, true);
            styleNVPairs = {'Color_I', 'LineStyle_I', 'Marker_I'; c, l, m};
            styleNVPairs = reshape(styleNVPairs(:, autoColorLineStyleMarker), 1, []);
        end
    end

    % Prepare x-data and y-data arguments.
    xargs = cell(1,0);
    if istable
        sliceStruct = dataMap.slice(k);

        x = cell(1);
        if hasXData
            xargs = {'XVariable', sliceStruct.X};
            x = dataSource.getData(sliceStruct.X);
        else
            % If x-data is not specified, use the row times if available.
            firstDimension = dataSource.getData(0);
            if ~iscell(firstDimension{1})
                xargs = {'XVariable', char(dataSource.getVarNames(0))};
                x = dataSource.getData(xargs{2});
            end
        end

        yargs = {'SourceTable', dataSource, 'YVariable', sliceStruct.Y};
        y = dataSource.getData(sliceStruct.Y);

        % Call configureAxes with each data set.
        if isscalar(ancestorAxes)
            matlab.graphics.internal.configureAxes(ancestorAxes, x{1}, y{1});
        end
    else
        if hasXData
            xargs = {'XData', x(:,k)};
        end
        yargs = {'YData', y(:,k)};
    end

    h(k,1) = matlab.graphics.chart.primitive.Stair( ...
        'Parent', parent, yargs{:}, xargs{:}, ...
        styleNVPairs{:}, objectNVPairs{:});

    h(k).assignSeriesIndex();
end

if isscalar(ancestorAxes) && any(strcmp(nextplot,{'replaceall','replace'}))
    ancestorAxes.Box = 'on';
end

if nargout>0
    xo = h;
end

end

function [xo,yo] = Lstairsv6(varargin)

args = varargin;
nargs = length(args);
if nargs < 1
    error(message('MATLAB:narginchk:notEnoughInputs'));
elseif nargs > 3
    error(message('MATLAB:narginchk:tooManyInputs'));
end

if matlab.graphics.internal.isCharOrString(args{nargs})
    % stairs(y,linspec) or stairs(x,y,linspec)
    % The linespec is never used, just ignore it.
    nargs = nargs - 1;
end

[msg,x,y] = xychk(args{1:nargs},'plot');
if ~isempty(msg), error(msg); end

if min(size(x))==1, x = x(:); end
if min(size(y))==1, y = y(:); end

[n,nc] = size(y);
ndx = [1:n;1:n];
y2 = y(ndx(1:2*n-1),:);
if size(x,2)==1
    x2 = x(ndx(2:2*n),ones(1,nc));
else
    x2 = x(ndx(2:2*n),:);
end

xo = x2;
yo = y2;

end
