function hh = scatter3(varargin)
%SCATTER3 3-D Scatter plot.
%   SCATTER3(X,Y,Z,S,C) displays colored circles at the locations
%   specified by the vectors X,Y,Z (which must all be the same size).  The
%   area of each marker is determined by the values in the vector S (in
%   points^2) and the colors of each marker are based on the values in C.  S
%   can be a scalar, in which case all the markers are drawn the same
%   size, or a vector the same length as X,Y, and Z.
%
%   When C is a vector the same length as X,Y, and Z, the values in C
%   are linearly mapped to the colors in the current colormap.
%   When C is a LENGTH(X)-by-3 matrix, the values in C specify the
%   colors of the markers as RGB values.  C can also be a color string.
%
%   SCATTER3(X,Y,Z) draws the markers with the default size and color.
%   SCATTER3(X,Y,Z,S) draws the markers with a single color.
%   SCATTER3(...,M) uses the marker M instead of 'o'.
%   SCATTER3(...,'filled') fills the markers.
%
%   SCATTER3(TBL,XVAR,YVAR,ZVAR) creates a scatter plot using the variables
%   XVAR, YVAR, and ZVAR from table TBL. Multiple scatter plots are created
%   if XVAR, YVAR, or ZVAR reference multiple variables. For example, this
%   command creates two scatter plots:
%   scatter3(tbl, 'var1', {'var2', 'var3'}, 'var4')
%
%   SCATTER3(TBL,XVAR,YVAR,ZVAR,'filled') specifies data in a table and
%   fills in the markers.
%
%   SCATTER3(AX,...) plots into AX instead of GCA.
%
%   H = SCATTER3(...) returns handles to scatter objects created.
%
%   Use PLOT3 for single color, single marker size 3-D scatter plots.
%
%   Example
%      [x,y,z] = sphere(16);
%      X = [x(:)*.5 x(:)*.75 x(:)];
%      Y = [y(:)*.5 y(:)*.75 y(:)];
%      Z = [z(:)*.5 z(:)*.75 z(:)];
%      S = repmat([1 .75 .5]*10,numel(x),1);
%      C = repmat([1 2 3],numel(x),1);
%      scatter3(X(:),Y(:),Z(:),S(:),C(:),'filled'), view(-60,60)
%
%   See also SCATTER, PLOT3.

%   Copyright 1984-2022 The MathWorks, Inc.

matlab.graphics.chart.internal.DDUXLogger(mfilename,varargin);
narginchk(3,inf)

try
    if istabular(varargin{1}) || istabular(varargin{2})
        [s, ancestorAxes] = tableScatter(varargin{:});
    else
        [s, ancestorAxes] = matrixScatter(varargin{:});
    end
catch ME
    throw(ME)
end

try %#ok<TRYNC>
    % If the ancestor axes doesn't support view or grid, silently noop
    if ~isempty(ancestorAxes)
        switch ancestorAxes.NextPlot
            case {'replaceall','replace'}
                view(ancestorAxes,3);
                grid(ancestorAxes,'on');
            case {'replacechildren'}
                view(ancestorAxes,3);
        end
    end

end

if nargout>0
    hh = s;
end

end


function [h, ancestorAxes] = tableScatter(varargin)
import matlab.graphics.chart.internal.inputparsingutils.peelFirstArgParent
import matlab.graphics.chart.internal.inputparsingutils.splitPositionalFromPV
import matlab.graphics.chart.internal.inputparsingutils.getParent
import matlab.graphics.chart.internal.inputparsingutils.prepareAxes

args = varargin;
[parent, args] = peelFirstArgParent(args);
[posargs, pvpairs] = splitPositionalFromPV(args, 4, true);

assert(istabular(posargs{1}), message('MATLAB:scatter3:InvalidTableArguments'));

% Handle filled flag:
if numel(posargs) == 5 
    if matlab.graphics.internal.isCharOrString(posargs{5}) && ...
            startsWith('filled', posargs{5}, 'IgnoreCase', true)
        pvpairs = [{'MarkerFaceColor', 'flat', 'MarkerEdgeColor', 'none'} pvpairs];
    else
        error(message('MATLAB:scatter3:InvalidTableArguments'));
    end
end

% validatePartialPropertyNames will throw if there are any invalid property
% names (i.e. a name that doesn't exist on Scatter or is ambiguous)
matlab.graphics.internal.validatePartialPropertyNames(...
    'matlab.graphics.chart.primitive.Scatter', pvpairs(1:2:end));

dataSource = matlab.graphics.data.DataSource(posargs{1});
dataMap = matlab.graphics.data.DataMap(dataSource);

dataMap = dataMap.addChannel('X', posargs{2});
dataMap = dataMap.addChannel('Y', posargs{3});
dataMap = dataMap.addChannel('Z', posargs{4});

% Validate the data by looking at the data itself, not just the subscripts
matlab.graphics.chart.primitive.Scatter.validateData(dataMap);

[parent, hasParent] = getParent(parent, pvpairs, 2);
[parent, ancestorAxes] = prepareAxes(parent, hasParent, false);

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
    
    h(i) = matlab.graphics.chart.primitive.Scatter( ...
        'SourceTable', dataSource.Table, ...
        'XVariable', sliceStruct.X, ...
        'YVariable', sliceStruct.Y, ...
        'ZVariable', sliceStruct.Z, ...
        'SizeData_I', 36, ...
        pvpairs{:}, 'Parent', parent);
    
    h(i).assignSeriesIndex();
end

if nObjects==0
    h = matlab.graphics.chart.primitive.Scatter.empty;
end

end


function [h, cax] = matrixScatter(varargin)
import matlab.graphics.chart.primitive.internal.findMatchingDimensions
import matlab.graphics.chart.internal.getRealData;

[~, cax, args] = parseplotapi(varargin{:},'-mfilename',mfilename);
[pvpairs,args,nargs,msg] = parseargs(args);
error(msg);

% Until proven otherwise, color will be auto.
cDataProp = 'CData_I';
% Until proven otherwise, size will be auto.
sDataProp = 'SizeData_I';

if nargs < 3
    error(message('MATLAB:narginchk:notEnoughInputs'));
elseif nargs > 7
    error(message('MATLAB:narginchk:tooManyInputs'));
end

allowNonNumeric = true;
dataargs = getRealData(args(1:nargs), allowNonNumeric);

x = dataargs{1};
y = dataargs{2};
z = dataargs{3};
if isempty(x) && isempty(y) && isempty(z)
    % For compatibility, handle case where both x, y, z have one zero
    % dimension.
    x = reshape(x, 0, 1);
    y = reshape(y, 0, 1);
    z = reshape(z, 0, 1);
end

% Match matrix input args for x,y,z,s
s = [];
if nargs <= 3 || isempty(dataargs{4}) || isscalar(dataargs{4})
    [msg, x, y, z] = findMatchingDimensions(x, y, z);
    if nargs>3 && isscalar(dataargs{4})
        s = dataargs{4};
    end
else
    [msg, x, y, z, s] = findMatchingDimensions(x, y, z, dataargs{4});
end
if ~isempty(msg)
    error(message('MATLAB:scatter:InvalidXYZSizeData'));
end

try
    sarg = getRealData({s});
catch
    error(message('MATLAB:scatter:SizeColorType'));
end


switch (nargs)
    case 3
        % Scatter3 uses DefaultLineMarkerSize^2 when no value for size is
        % specified.
        s = get(groot,'DefaultLineMarkerSize')^2;
    case 4
        % Validate size argument
        s = matlab.graphics.chart.internal.datachk(sarg{1});
        
        if ~isempty(s)
            sDataProp = 'SizeData';
        end
    case 5
        % Validate size argument
        s = matlab.graphics.chart.internal.datachk(sarg{1});

        if ~isempty(s)
            sDataProp = 'SizeData';
        end

        % Validate color argument
        c = dataargs{5};
        c = localColorCheck(x,c);

        if ~isempty(c)
            cDataProp = 'CData';
        end
    otherwise
        error(message('MATLAB:scatter3:invalidInput'));
end

if isempty(cax) || ishghandle(cax,'axes')
    cax = newplot(cax);
    parax = cax;
else
    parax = cax;
    cax = ancestor(cax,'matlab.graphics.axis.AbstractAxes','node');
end
if nargs < 5
    [~,c,~] = matlab.graphics.chart.internal.nextstyle(cax, true, true, true);
end

if isempty(s), s = 36; end

matlab.graphics.internal.configureAxes(cax,x,y,z);

nObjects = size(x,2);
h = gobjects(1,nObjects);
sn = s;
cn = c;

for n = 1:nObjects
    if isequal(size(c), [nObjects 3])
        % User has specified one RGB color for each object
        cn = c(n,:);
    end

    if size(s,2) > 1
        sn = s(:,n);
    end

    h(n) = matlab.graphics.chart.primitive.Scatter('Parent', parax, ...
        'XData', x(:,n), 'YData', y(:,n), 'ZData', z(:,n), ...
        sDataProp, sn, ...
        cDataProp, cn, ...
        pvpairs{:});
    h(n).assignSeriesIndex();
end


end


function [pvpairs,args,nargs,msg] = parseargs(args)
% separate pv-pairs from opening arguments
[args,pvpairs] = parseparams(args);
pvpairs = matlab.graphics.internal.convertStringToCharArgs(pvpairs);
n = 1;
extrapv = {};
% check for 'filled' or LINESPEC or ColorSpec
while length(pvpairs) >= 1 && n < 5 && matlab.graphics.internal.isCharOrString(pvpairs{1})
    arg = lower(pvpairs{1});
    if startsWith('filled',arg,'IgnoreCase',true)
        pvpairs(1) = [];
        extrapv = [{'MarkerFaceColor','flat','MarkerEdgeColor','none',} ...
            extrapv];
    else
        [l,c,m,tmsg]=colstyle(pvpairs{1});
        if isempty(tmsg)
            pvpairs(1) = [];
            if ~isempty(l)
                extrapv = [{'LineStyle',l},extrapv];
            end
            if ~isempty(c)
                extrapv = [{'CData',validatecolor(c)},extrapv];
            end
            if ~isempty(m)
                extrapv = [{'Marker',m},extrapv];
            end
        end
    end
    n = n+1;
end
pvpairs = [extrapv pvpairs];
msg = matlab.graphics.chart.internal.checkpvpairs(pvpairs);
nargs = length(args);

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
