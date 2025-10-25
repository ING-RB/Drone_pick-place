function hh = scatter(varargin)
% SCATTER Scatter plot.
%    SCATTER(X,Y) creates a scatter plot with markers at the locations
%    specified by X and Y. One scatter object is created when X and Y are
%    vectors. Multiple scatter plots are created if X or Y are matrices.
%
%    SCATTER(X,Y,SZ) specifies the area of each marker in points squared.
%    To plot all markers with the same size, specify SZ as a scalar. To
%    plot each marker with a different size, specify SZ as a vector or
%    matrix. If SZ is an empty vector, the default size is used.
%
%    SCATTER(X,Y,SZ,C) specifies the marker colors. To plot all markers
%    with the same color, specify C as a color name or an RGB triplet. To
%    specify different colors for each scatter plot, specify C as an 
%    m-by-3 matrix of RGB triplets with one color per scatter object. To
%    specify different colors for each scatter point when a single scatter
%    plot is created, specify C as an m-by-1 vector with one value per
%    scatter point or an m-by-3 matrix of RGB triplets with one color per
%    scatter point.
%
%    SCATTER(...,'filled') fills the markers with color. Some markers, such
%    as '+' and '*' do not support filled color.
%
%    SCATTER(...,M) specifies the marker type.
%
%    SCATTER(TBL,XVAR,YVAR) creates a scatter plot with the variables XVAR
%    and YVAR from table TBL. Multiple scatter plots are created if XVAR or
%    YVAR reference multiple variables. For example, this command creates
%    two scatter plots: 
%    scatter(tbl, {'var1', 'var2'}, {'var3', 'var4'})
%
%    SCATTER(TBL,XVAR,YVAR,'filled') specifies data in a table and fills in
%    the markers.
%
%    SCATTER(...,Name, Value) modifies the scatter chart using one or more
%    name-value arguments. For example, 'LineWidth',2 sets the marker
%    outline width to 2 points.
%
%    SCATTER(AX,...) plots into the axes specified by AX instead of the
%    current axes.
%
%    H = SCATTER(...) returns one or more Scatter objects.
%
%    Example
%        load seamount
%        scatter(x,y,5,z)
%
%    See also SCATTER3, SWARMCHART, POLARSCATTER, BUBBLECHART.

%   Copyright 1984-2023 The MathWorks, Inc.

import matlab.graphics.chart.internal.inputparsingutils.peelFirstArgParent

matlab.graphics.chart.internal.DDUXLogger(mfilename,varargin);
narginchk(2,inf)

istable = istabular(varargin{1}) || istabular(varargin{2});
supportDoubleAxesHandle = ~istable;
[parent, args] = peelFirstArgParent(varargin, supportDoubleAxesHandle);

try
    if istable
        h = tableScatter(parent, args);
    else
        h = matrixScatter(parent, args);
    end
catch ME
    throw(ME)
end

if nargout>0
    hh = h;
end

end

function h = tableScatter(parent, args)
import matlab.graphics.chart.internal.inputparsingutils.splitPositionalFromPV
import matlab.graphics.chart.internal.inputparsingutils.getParent
import matlab.graphics.chart.internal.inputparsingutils.prepareAxes

[posargs, pvpairs] = splitPositionalFromPV(args, 3, true);

assert(istabular(posargs{1}), message('MATLAB:scatter:InvalidTableArguments', 'scatter', 'X', 'Y'));

% Handle filled flag:
if numel(posargs) == 4
    if matlab.graphics.internal.isCharOrString(posargs{4}) && ...
            startsWith('filled', posargs{4}, 'IgnoreCase', true)
        pvpairs = [{'MarkerFaceColor', 'flat', 'MarkerEdgeColor', 'none'} pvpairs];
    else
        error(message('MATLAB:scatter:InvalidTableArguments', 'scatter', 'X', 'Y'));
    end
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

% validatePartialPropertyNames will throw if there are any invalid property
% names (i.e. a name that doesn't exist on Scatter or is ambiguous)
matlab.graphics.internal.validatePartialPropertyNames(...
    'matlab.graphics.chart.primitive.Scatter', propNames);

dataSource = matlab.graphics.data.DataSource(posargs{1});
dataMap = matlab.graphics.data.DataMap(dataSource);

dataMap = dataMap.addChannel('X', posargs{2});
dataMap = dataMap.addChannel('Y', posargs{3});

% Validate the data by looking at the data itself, not just the subscripts
matlab.graphics.chart.primitive.Scatter.validateData(dataMap);

[parent, ancestorAxes] = prepareAxes(parent, hasParent, true);

nObjects = dataMap.NumObjects;
h = gobjects(1, nObjects);
for i = 1:nObjects
    sliceStruct = dataMap.slice(i);

    if isscalar(ancestorAxes)
        x = dataSource.getData(sliceStruct.X);
        y = dataSource.getData(sliceStruct.Y);
        matlab.graphics.internal.configureAxes(ancestorAxes, x{1}, y{1});
    end

    h(i) = matlab.graphics.chart.primitive.Scatter( ...
        'Parent', parent, ...
        'SourceTable', dataSource.Table, ...
        'XVariable', sliceStruct.X, 'YVariable', sliceStruct.Y, ...
        'SizeData_I', 36, ...
        pvpairs{:});

    h(i).assignSeriesIndex();
end

if nObjects==0
    h = matlab.graphics.chart.primitive.Scatter.empty(1,0);
end

end

function h = matrixScatter(parent, args)
import matlab.graphics.chart.internal.inputparsingutils.getParent
import matlab.graphics.chart.internal.inputparsingutils.prepareAxes
import matlab.graphics.chart.primitive.internal.findMatchingDimensions
import matlab.graphics.chart.internal.getRealData

[pvpairs,args,nargs,msg] = parseargs(args);
error(msg);
if nargs < 2
    error(message('MATLAB:narginchk:notEnoughInputs'));
elseif nargs > 4
    error(message('MATLAB:narginchk:tooManyInputs'));
end

allowNonNumeric = true;
dataargs = getRealData(args(1:nargs), allowNonNumeric);

% We need an axes color for marker edges when unspecified, or specified as flat.
mecArg = find(strcmpi(pvpairs(1:end-1),'MarkerEdgeColor'));
mecNeededFromAxes = isempty(mecArg) || strcmpi({'flat'},pvpairs(mecArg(end)+1));

% We need an axes color for faces if specified as flat
mfcArg = find(strcmpi(pvpairs(1:end-1),'MarkerFaceColor'));
mfcNeededFromAxes = ~isempty(mfcArg) && any(strcmpi({'flat'},pvpairs(mfcArg(end)+1)));

colorNeededFromAxes =  (mfcNeededFromAxes || mecNeededFromAxes) && ~any(strcmpi(pvpairs,'CData'));

% Until proven otherwise, color will be auto.
cDataProp = 'CData_I';

% Empty size or color means to use the default value.
s = [];
c = [];
switch (nargs)
    case 2
        [x,y] = deal(dataargs{:});

        [x,y] = localCheckXYForZeroDim(x,y);

        % Validate x and y data.
        [msg,x,y] = findMatchingDimensions(x,y);

        if ~isempty(msg)
            error(message('MATLAB:scatter:InvalidXYData','X','Y'));
        end
    case 3
        [x,y,s] = deal(dataargs{:});

        % Validate x, y, and s data.
        [x,y,s] = localXYSCheck(x,y,s);

    case 4
        [x,y,s,c] = deal(dataargs{:});

        % Validate x, y, and s data.
        [x,y,s] = localXYSCheck(x,y,s);

        % Validate the color data against x-data.
        c = localColorCheck(x,c);

        % CData mode will be manual only if a non-empty color is specified
        if ~isempty(c)
            cDataProp = 'CData';
        end
end

[parent, hasParent] = getParent(parent, pvpairs, 2);
[parent, ancestorAxes] = prepareAxes(parent, hasParent, true);

if isempty(s)
    s = 36;
    sDataProp = 'SizeData_I'; % auto size data
else
    sDataProp = 'SizeData'; % manual size data
end

if isscalar(ancestorAxes)
    matlab.graphics.internal.configureAxes(ancestorAxes,x,y);
end

nObjects = size(x,2);
h = gobjects(1,nObjects);
sn = s;
cn = c;
colorPair = cell(1,0);
for n = 1:nObjects
    if isempty(c)
        % Get auto color from colororder.
        if isscalar(ancestorAxes)
            [~,cn,~] = matlab.graphics.chart.internal.nextstyle(ancestorAxes,colorNeededFromAxes,false,true);
            colorPair = {cDataProp, cn};
        end
    elseif isequal(size(c), [nObjects 3])
        % User has specified one RGB color for each object
        cn = c(n,:);
        colorPair = {cDataProp, cn};
    else
        colorPair = {cDataProp, cn};
    end

    if size(s,2) > 1
        sn = s(:,n);
    end

    h(n) = matlab.graphics.chart.primitive.Scatter('Parent', parent, ...
        'XData', x(:,n), 'YData', y(:,n),...
        sDataProp, sn, colorPair{:}, ...
        pvpairs{:});
    h(n).assignSeriesIndex();
end

end

function [pvpairs,args,nargs,msg] = parseargs(args)
msg = '';
% separate pv-pairs from opening arguments
[args,pvpairs] = parseparams(args);
pvpairs = matlab.graphics.internal.convertStringToCharArgs(pvpairs);
n = 1;
extrapv = {};
% check for 'filled' or LINESPEC or ColorSpec
while length(pvpairs) >= 1 && n < 4 && matlab.graphics.internal.isCharOrString(pvpairs{1})
    arg = lower(pvpairs{1});
    if startsWith('filled',arg,'IgnoreCase',true)
        pvpairs(1) = [];
        extrapv = [{'MarkerFaceColor'},{'flat'},...
            {'MarkerEdgeColor'},{'none'},extrapv]; %#ok<AGROW>
        % Too many conditions to check for effective preallocation.
    else
        [l,c,m,tmsg]=colstyle(pvpairs{1});
        if isempty(tmsg)
            pvpairs(1) = [];
            if ~isempty(l)
                extrapv = [{'LineStyle'},{l},extrapv]; %#ok<AGROW>
                % Too many conditions to check for effective preallocation.
            end
            if ~isempty(c)
                extrapv = [{'CData'},{validatecolor(c)},extrapv]; %#ok<AGROW>
                % Too many conditions to check for effective preallocation.
            end
            if ~isempty(m)
                extrapv = [{'Marker'},{m},extrapv]; %#ok<AGROW>
                % Too many conditions to check for effective preallocation.
            end
        end
    end
    n = n+1;
end
pvpairs = [extrapv pvpairs];
if isempty(args)
    msg.message = getString(message('MATLAB:scatter:NoDataInputs'));
    msg.identifier = 'MATLAB:scatter:NoDataInputs';
else
    msg = matlab.graphics.chart.internal.checkpvpairs(pvpairs);

    % Check if user has tried to pass multiple color names and/or marker
    % specifications, e.g. {'r','g*','b'}. If so, error.
    finalArg = args{end};
    if iscellstr(finalArg) %#ok<ISCLSTR>
        colorSpecMatches = false(size(finalArg));
        markerSpecMatches = false(size(finalArg));
        for n = 1:numel(finalArg)
            [~,c,m,~] = colstyle(finalArg{n});
            if ~isempty(c)
                colorSpecMatches(n) = true;
            end
            if ~isempty(m)
                markerSpecMatches(n) = true;
            end
        end
        if all(markerSpecMatches | colorSpecMatches) && any(markerSpecMatches)
            % If all are valid marker and/or color specs, and at least one is a
            % valid marker spec, throw the marker error.
            msg.message = getString(message('MATLAB:scatter:MultipleMarkerSpecs'));
            msg.identifier = 'MATLAB:scatter:MultipleMarkerSpecs';
        elseif all(colorSpecMatches)
            % If all are valid color specs, throw the color error.
            msg.message = getString(message('MATLAB:scatter:MultipleColorSpecs'));
            msg.identifier = 'MATLAB:scatter:MultipleColorSpecs';
        end
    end
end

nargs = length(args);

end

function [x,y] = localCheckXYForZeroDim(x,y)

if isempty(x) && isempty(y)
    % For compatibility, handle case where both x & y have one zero
    % dimension. In these cases, one scatter object will be created, with
    % 0x1 XData & YData.
    x = reshape(x, 0, 1);
    y = reshape(y, 0, 1);
end
end

function [x,y,s] = localXYSCheck(x,y,s)

import matlab.graphics.chart.primitive.internal.findMatchingDimensions
import matlab.graphics.chart.internal.getRealData

try
    sarg = getRealData({s});
catch
    throwAsCaller(MException(message('MATLAB:scatter:SizeColorType')));
end
s = matlab.graphics.chart.internal.datachk(sarg{1});

[x,y] = localCheckXYForZeroDim(x,y);

if isempty(s) || isscalar(s)
    [msg,x,y,firstBad] = findMatchingDimensions(x,y);
else
    [msg,x,y,s,firstBad] = findMatchingDimensions(x,y,s);
end
if ~isempty(msg)
    if firstBad < 3
        throwAsCaller(MException(message('MATLAB:scatter:InvalidXYData','X','Y')));
    else
        throwAsCaller(MException(message('MATLAB:scatter:InvalidXYSizeData','X','Y')));
    end
end

end

function c = localColorCheck(x,c)
% If color was a character vector, it was processed by parseargs. This code
% only needs to deal with numeric color.

import matlab.graphics.chart.internal.getRealData

try
    carg = getRealData({c});
catch
    throwAsCaller(MException(message('MATLAB:scatter:SizeColorType')));
end
c = matlab.graphics.chart.internal.datachk(carg{1});

% Verify CData is correct size
nPoints = height(x);
nObjects = width(x);
if nObjects ~= 1
    % In the cases where 0 or >1 objects are created, CData must be an RGB
    % matrix with one color per object or a single RGB. If not, error.
    if ~isequal(size(c), [nObjects 3]) && ~isequal(size(c), [1 3])
        throwAsCaller(MException(message('MATLAB:scatter:InvalidCData')));
    end
elseif nPoints == 0
    % In the case where a single scatter object is created with empty
    % X/YData, CData must be:
    % (1) 1x3 RGB (single color for all points)
    % (2) Any empty matrix
    % If neither is true, error.
    if ~isequal(size(c),[1 3]) && ~isempty(c)
        throwAsCaller(MException(message('MATLAB:scatter:InvalidCData')));
    end
else
    % In the case where a single scatter object is created, CData must
    % conform to one of the following cases:
    % (1) 1x3 RGB (single color for all points)
    % (2) Mx3 RGB  (separate color for each point)
    % (3) Mx1 or 1xM vector (one value for each point, colormapped)
    % If none of theses is true, error.
    if ~isequal(size(c),[1 3]) && ~isequal(size(c),[nPoints 3]) && ...
            ~(isvector(c) && numel(c) == nPoints)
        throwAsCaller(MException(message('MATLAB:scatter:InvalidCData')));
    end
end

end
