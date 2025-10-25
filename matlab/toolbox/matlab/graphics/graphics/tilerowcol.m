function [row, col] = tilerowcol(varargin)
%TILEROWCOL  Get tile row and column numbers in tiled chart layout
%   [row,col] = TILEROWCOL(t,tilenum) returns the row and column locations
%   for the sepcified tile numbers in the tiled chart layout t. Specify
%   tilenum as a scalar tile number or an array of tile numbers.  
%
%   [row,col] = TILEROWCOL(obj) returns the row and column numbers to the
%   specified objects in a tiled chart layout.  For example, you can find
%   the row and column location of an axes.  
%
%   TILEROWCOL is not supported when the tiled chart layout arrangement is 
%   set to flow.
%
%   Example:
%       T = tiledlayout(2,2);
%       ax = nexttile(T,4);
%       [R, C] = tilerowcol(ax)
%       [R, C] = tilerowcol(T, 2)
%
%   See also TILENUM, TILEDLAYOUT, NEXTTILE

%   Copyright 2022 The MathWorks, Inc.


narginchk(1,2)
if nargin==1
    % Syntax tilerowcol(obj)
    try
        [layout, tileidx] = paramsfromobject(varargin{1});
    catch me
        % rethrow argument validation exceptions from helper functions
        throw(me)
    end
else
    % Syntax tilerowcol(TCL, n)
    try
        [layout, tileidx] = validateparams(varargin{1},varargin{2});
    catch me
        % rethrow argument validation exceptions from helper functions
        throw(me)
    end
end

if isempty(tileidx)
    % An empty obj array will result in empty outputs of equal size.
    row = tileidx;
    col = tileidx;
    return
end

gridsize = layout.GridSize;
if isequal(layout.TileIndexing,'rowmajor')
    col = mod(tileidx - 1, gridsize(2)) + 1;
    row = fix((tileidx - 1) / gridsize(2)) + 1;
else
    col = fix((tileidx-1) / gridsize(1)) + 1;
    row = mod(tileidx-1, gridsize(1)) + 1;
end
outsideIdx = tileidx > prod(gridsize);
row(outsideIdx) = nan;
col(outsideIdx) = nan;
end

function [layout, tileidx] = paramsfromobject(obj)
arguments
    obj {mustBeA(obj,'matlab.graphics.Graphics')}
end

tileidx = nan(size(obj));
if isempty(obj)
    layout=[];
    return
end

assert(all(isvalid(obj),'all'),message('MATLAB:class:InvalidHandle'))
layout=obj(1).Parent;
assert(isa(layout,'matlab.graphics.layout.TiledChartLayout'),...
    message('MATLAB:tiledchartlayout:InvalidParent'))
assert(strcmp(layout.TileArrangement, 'fixed'), ...
    message('MATLAB:tiledchartlayout:FlowLayoutNotSupported'))
for i = 1:numel(obj)
    par = obj(i).Parent;
    assert(isprop(obj(i),'layout') && ...
        ~isempty(obj(i).Layout) && ...
        isa(obj(i).Layout, 'matlab.graphics.layout.TiledChartLayoutOptions'), ...
        message('MATLAB:tiledchartlayout:InvalidParent'))
    assert(par==layout,message('MATLAB:tiledchartlayout:MultipleLayouts'))

    if isnumeric(obj(i).Layout.Tile)
        % Named tile locations (e.g. 'north') retain NaN values
        tileidx(i)=obj(i).Layout.Tile;
    end
end
end

function [layout, tileidx] = validateparams(layout, tileidx)
arguments
    layout (1,1) matlab.graphics.layout.TiledChartLayout
    tileidx {mustBeNumeric mustBeInteger mustBePositive}
end
assert(isvalid(layout),message('MATLAB:class:InvalidHandle'))
assert(strcmp(layout.TileArrangement, 'fixed'), ...
    message('MATLAB:tiledchartlayout:FlowLayoutNotSupported'))
tileidx = double(tileidx); 
end
