function hh = stem(varargin)
%STEM Plot discrete sequence data
%   STEM(Y) plots the data sequence, Y, as stems that extend from a
%   baseline along the x-axis. The data values are indicated by circles
%   terminating each stem.
%
%   STEM(X,Y) plots the data sequence, Y, at values specified by X. The X
%   and Y inputs must be vectors or matrices of the same size.
%   Additionally, X can be a row or column vector and Y must be a matrix
%   with length(X) rows.
%
%   STEM(___,'filled') fills the circles. Use this option with any of the
%   input argument combinations in the previous syntaxes.
%
%   STEM(___,LineSpec) specifies the line style, marker symbol, and color.
%
%   STEM(tbl,xvar,yvar) plots the variables xvar and yvar from the table
%   tbl. To plot one data set, specify one variable for xvar and one
%   variable for yvar. To plot multiple data sets, specify multiple
%   variables for xvar, yvar, or both. If both arguments specify multiple
%   variables, they must specify the same number of variables.
%
%   STEM(tbl,yvar) plots the specified variable from the table against the
%   row indices of the table. If the table is a timetable, the specified
%   variable is plotted against the row times of the timetable.
%
%   STEM(___,Name,Value) modifies the stem chart using one or more
%   Name,Value pair arguments.
%
%   STEM(ax,___) plots into the axes specified by ax instead of into the
%   current axes (gca). The option, ax, can precede any of the input
%   argument combinations in the previous syntaxes.
%
%   h = STEM(___) returns a vector of Stem objects in h. Use h to modify
%   the stem chart after it is created.
%
%   See also plot, bar, stairs.

%   Copyright 1984-2022 The MathWorks, Inc.

import matlab.graphics.chart.internal.inputparsingutils.peelFirstArgParent
import matlab.graphics.chart.internal.inputparsingutils.splitPositionalFromPV
import matlab.graphics.chart.internal.inputparsingutils.getParent
import matlab.graphics.chart.internal.inputparsingutils.prepareAxes
import matlab.graphics.chart.internal.inputparsingutils.convertFlagsToNameValuePairs
import matlab.graphics.chart.internal.nextstyle

matlab.graphics.chart.internal.DDUXLogger(mfilename,varargin);

% Check for tables as input.
% stem(tbl, ...) or stem(ax, tbl, ...)
istable = (nargin > 0 && istabular(varargin{1})) ...
    || (nargin > 1 && istabular(varargin{2}));

% Check for first argument parent.
supportDoubleAxesHandle = ~istable;
[parent, args] = peelFirstArgParent(varargin, supportDoubleAxesHandle);

if istable
    % stem(tbl, yvar, ...) or stem(tbl, xvar, yvar, ...)
    [posArgs, nvPairs] = splitPositionalFromPV(args, 2, true);
    assert(istabular(posArgs{1}), message('MATLAB:stem:InvalidTableArguments'));
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
    % stem(y, ...) or stem(x, y, ...)
    assert(numel(args) >= 1, message('MATLAB:narginchk:notEnoughInputs'));
    [posArgs, nvPairs] = parseparams(args);
    assert(numel(posArgs)>=1, message('MATLAB:narginchk:notEnoughInputs'));
    assert(numel(posArgs)<=2, message('MATLAB:narginchk:tooManyInputs'));
    hasXData = numel(posArgs) == 2;

    % Check the first two of the remaining arguments to see if they are a
    % line spec or the 'filled' flag. If the 'filled' flag is detected,
    % replace it with the name/value pair MarkerFaceColor='auto'.
    nvPairs = convertFlagsToNameValuePairs(nvPairs, ...
        Flags=struct('filled', {{'MarkerFaceColor','auto'}}));

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
% names (i.e. a name that doesn't exist on Stem or is ambiguous)
propNames = matlab.graphics.internal.validatePartialPropertyNames(...
    'matlab.graphics.chart.primitive.Stem', nvPairs(1:2:end));

[parent, hasParent] = getParent(parent, nvPairs, 2);
[parent, ancestorAxes, nextplot] = prepareAxes(parent, hasParent, true);

% Call configureAxes with all the data (for matrix data). This will make
% sure the rulers are configured even if the data is empty.
if ~istable && isscalar(ancestorAxes)
    matlab.graphics.internal.configureAxes(ancestorAxes, x, y);
end

h = matlab.graphics.chart.primitive.Stem.empty(1,0);
for k = 1:nObjects
    objectNVPairs = [objectSpecificNVPairs{k,:} nvPairs];

    styleNVPairs = {};
    if isscalar(ancestorAxes)
        % Determine whether the user specified Color, LineStyle, or Marker
        % in name/value pairs (using scalar expansion).
        autoColorLineStyleMarker = ~any(propNames == ["Color"; "LineStyle"; "Marker"], 2);

        if any(autoColorLineStyleMarker)
            autoColor = autoColorLineStyleMarker(1);
            autoStyle = autoColorLineStyleMarker(2);
            [l,c,m] = nextstyle(ancestorAxes, autoColor, autoStyle, true);
    
            % Only include the marker if it is not empty or none.
            autoColorLineStyleMarker(3) = autoColorLineStyleMarker(3) && ~isempty(m) && ~strcmpi(m,'none');
    
            % Generate name/value pairs for Color, LineStyle, and Marker when
            % they are not specified by the user.
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

    h(k) = matlab.graphics.chart.primitive.Stem( ...
        'Parent', parent, yargs{:}, xargs{:}, ...
        styleNVPairs{:}, objectNVPairs{:});

    h(k).assignSeriesIndex();
end

if isscalar(ancestorAxes) && any(strcmp(nextplot,{'replaceall','replace'}))
    ancestorAxes.Box = 'on';
    if(isprop(ancestorAxes,'XAxis'))
        ancestorAxes.XAxis.AxesLayer = 'top';
    end
end

if nargout>0
    hh = h;
end

end
