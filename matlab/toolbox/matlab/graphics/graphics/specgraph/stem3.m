function hh = stem3(varargin)
%STEM3 Plot 3-D discrete sequence data
%   STEM3(Z) plots entries in Z as stems extending from the xy-plane and
%   terminating with circles at the entry values. The stem locations in the
%   xy-plane are automatically generated.
%
%   STEM3(X,Y,Z) plots entries in Z as stems extending from the xy-plane
%   where X and Y specify the stem locations in the xy-plane. The inputs X,
%   Y, and Z must be vectors or matrices of the same size.
%
%   STEM3(___,'filled') fills the circles. Use this option with any of the
%   input argument combinations in the previous syntaxes.
%
%   STEM3(___,LineSpec) specifies the line style, marker symbol, and color.
%
%   STEM3(tbl,xvar,yvar,zvar) plots the variables xvar, yvar, and zvar from
%   the table tbl. Specify one variable each for xvar, yvar, and zvar.
%
%   STEM3(___,Name,Value) modifies the stem chart using one or more
%   name-value pair arguments.
%
%   STEM3(ax,___) plots into the axes specified by ax instead of into the
%   current axes (gca). The option, ax, can precede any of the input
%   argument combinations in the previous syntaxes.
%
%   h = stem3(___) returns the Stem object h.
%
%   See also stem, quiver3.

%   Copyright 1984-2022 The MathWorks, Inc.

import matlab.graphics.chart.internal.inputparsingutils.peelFirstArgParent
import matlab.graphics.chart.internal.inputparsingutils.splitPositionalFromPV
import matlab.graphics.chart.internal.inputparsingutils.getParent
import matlab.graphics.chart.internal.inputparsingutils.prepareAxes
import matlab.graphics.chart.internal.inputparsingutils.convertFlagsToNameValuePairs
import matlab.graphics.chart.internal.nextstyle

matlab.graphics.chart.internal.DDUXLogger(mfilename,varargin);

% Check for tables as input.
istable = (nargin > 0 && istabular(varargin{1})) ...
    || (nargin > 1 && istabular(varargin{2}));

% Check for first argument parent.
supportDoubleAxesHandle = ~istable;
[parent, args] = peelFirstArgParent(varargin, supportDoubleAxesHandle);

if istable
    % stem3(tbl, xvar, yvar, zvar, ...)
    [posArgs, nvPairs] = splitPositionalFromPV(args, 4, false);
    assert(istabular(posArgs{1}), message('MATLAB:stem3:InvalidTableArguments'));

    dataSource = matlab.graphics.data.DataSource(posArgs{1});
    dataMap = matlab.graphics.data.DataMap(dataSource);

    % stem3 only supports creating a single object, so xvar, yvar, and zvar
    % must refer to a single variale in the table.
    dataMap = dataMap.addChannel('X', posArgs{2});
    assert(dataMap.NumObjects == 1, message('MATLAB:graphics:chart:NonScalarTableSubscript', 'xvar'));
    dataMap = dataMap.addChannel('Y', posArgs{3});
    assert(dataMap.NumObjects == 1, message('MATLAB:graphics:chart:NonScalarTableSubscript', 'yvar'));
    dataMap = dataMap.addChannel('Z', posArgs{4});
    assert(dataMap.NumObjects == 1, message('MATLAB:graphics:chart:NonScalarTableSubscript', 'zvar'));

    sliceStruct = dataMap.slice(1);
    dataArgs = {'SourceTable', dataSource, 'XVariable', sliceStruct.X, ...
        'YVariable', sliceStruct.Y, 'ZVariable', sliceStruct.Z};
    data = [dataSource.getData(sliceStruct.X), ...
        dataSource.getData(sliceStruct.Y), ...
        dataSource.getData(sliceStruct.Z)];
else
    % stem3(z, ...) or stem3(x, y, z, ...)
    assert(numel(args) >= 1, message('MATLAB:narginchk:notEnoughInputs'));
    [posArgs, nvPairs] = parseparams(args);
    assert(numel(posArgs) == 1 || numel(posArgs) == 3, message('MATLAB:stem3:InvalidDataInputs'))

    % Check the first two of the remaining arguments to see if they are a
    % line spec or the 'filled' flag. If the 'filled' flag is detected,
    % replace it with the name/value pair MarkerFaceColor='auto'.
    nvPairs = convertFlagsToNameValuePairs(nvPairs, ...
        Flags=struct('filled', {{'MarkerFaceColor','auto'}}));

    % Convert non-numeric data to double (if it is not datetime, duration,
    % or categorical), and get the real component of complex data.
    allowNonNumeric = true;
    posArgs = matlab.graphics.chart.internal.getRealData(posArgs,allowNonNumeric);

    % Create xdata,ydata if necessary
    [msg, x, y, z] = xyzchk(posArgs{:});
    if ~isempty(msg), error(msg); end

    data = {reshape(x,1,[]), reshape(y,1,[]), reshape(z,1,[])};
    dataArgs = {'XData', data{1}, 'YData', data{2}, 'ZData', data{3}};
end

% validatePartialPropertyNames will throw if there are any invalid property
% names (i.e. a name that doesn't exist on Scatter or is ambiguous)
propNames = matlab.graphics.internal.validatePartialPropertyNames(...
    'matlab.graphics.chart.primitive.Stem', nvPairs(1:2:end));

[parent, hasParent] = getParent(parent, nvPairs, 2);
[parent, ancestorAxes, nextplot] = prepareAxes(parent, hasParent);

% Configure the axes for datetime, duration, and/or categorical.
matlab.graphics.internal.configureAxes(ancestorAxes, data{:});

if isscalar(ancestorAxes)
    % Determine whether the user specified Color, LineStyle, or Marker in
    % name/value pairs (using scalar expansion).
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
        nvPairs = [styleNVPairs nvPairs];
    end
end

h = matlab.graphics.chart.primitive.Stem('Parent', parent, dataArgs{:}, nvPairs{:});
h.assignSeriesIndex();

switch nextplot
    case {'replaceall','replace'}
        view(ancestorAxes,3);
        grid(ancestorAxes,'on');
    case {'replacechildren'}
        view(ancestorAxes,3);
end

if nargout>0
    hh = h;
end

end
