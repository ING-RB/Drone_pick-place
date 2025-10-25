function tileidx = tilenum(varargin)
%TILENUM  Get tile numbers in tiled chart layout
%   num = TILENUM(t,row,column) returns the tile numbers for the
%   specified rows and columns within the tiled chart layout t. Tiled
%   layout arrangement cannot be set to flow.
%
%   num = TILENUM(obj) returns the tile numbers for the specified 
%   objects in the layout. For example, you can use this syntax to get the  
%   tile number for a specified axes.  
%
%   Example:
%       T = tiledlayout(2,2);
%       ax = nexttile(T,4);
%       N = tilenum(ax)
%       N = tilenum(T, 1, 2)
%
%   See also TILEROWCOL, TILEDLAYOUT, NEXTTILE

%   Copyright 2022 The MathWorks, Inc.


narginchk(1,3)
if nargin==1
    % Syntax tilenum(obj)
    try
        tileidx = gettilenumfromobject(varargin{1});
        return
    catch me
        % rethrow argument validation exceptions from helper functions
        throw(me)
    end
elseif nargin==2
    error(message('MATLAB:tiledchartlayout:InvalidNumberOfInputs'))
else
    % Syntax tilenum(TCL, r, c)
    try
        [layout, row, col] = validateparams(varargin{1}, varargin{2}, varargin{3});
    catch me
        % rethrow argument validation exceptions from helper functions
        throw(me)
    end
end

gridsize = layout.GridSize;
if isequal(layout.TileIndexing,'rowmajor')
    tileidx = row * gridsize(2) - gridsize(2) + col;
else
    tileidx = col * gridsize(1) - gridsize(1) + row;
end
end

function tileidx = gettilenumfromobject(obj)
arguments
    obj {mustBeA(obj,'matlab.graphics.Graphics')}
end

tileidx = nan(size(obj));
if isempty(obj)
    return
end

assert(all(isvalid(obj),'all'),message('MATLAB:class:InvalidHandle'))
layout=obj(1).Parent;
assert(isa(layout,'matlab.graphics.layout.TiledChartLayout'),...
    message('MATLAB:tiledchartlayout:InvalidParent'))
for i = 1:numel(obj)
    par = obj(i).Parent;
    assert(isprop(obj(i),'layout') && ...
        ~isempty(obj(i).Layout) && ...
        isa(obj(i).Layout, 'matlab.graphics.layout.TiledChartLayoutOptions'), ...
        message('MATLAB:tiledchartlayout:InvalidParent'))
    assert(par==layout,message('MATLAB:tiledchartlayout:MultipleLayouts'))

    if isnumeric(obj(i).Layout.Tile)
        tileidx(i)=obj(i).Layout.Tile;
    else
        % Named tile locations (e.g. 'north')
        tileidx(i)=nan;
    end
end
end

function [layout, row, col] = validateparams(layout, row, col)
arguments
    layout (1,1) matlab.graphics.layout.TiledChartLayout
    row {mustBeNumeric, mustBeInteger, mustBePositive}
    col {mustBeNumeric, mustBeInteger, mustBePositive}
end
assert(isvalid(layout), message('MATLAB:class:InvalidHandle'))
assert(strcmp(layout.TileArrangement, 'fixed'), ...
    message('MATLAB:tiledchartlayout:FlowLayoutNotSupported'))
row = double(row); 
col = double(col); 
row(row>layout.GridSize(1)) = NaN;
col(col>layout.GridSize(2)) = NaN;
end
