function hh = trisurf(tri,varargin)
%TRISURF Triangular surface plot
%   TRISURF(T,x,y,z) plots the 3-D triangular surface defined by the points 
%   in vectors x, y, and z, and a triangle connectivity matrix T. Specify T
%   as a 3-column matrix where each row contains the indices into the X, Y, 
%   and Z vertex vectors to define a single triangular face.
%
%   TRISURF(TO) plots the surface defined by a 3-D triangulation or 
%   delaunayTriangulation object.
%
%   TRISURF(...,c) also specifies the surface color for either of the 
%   previous syntaxes.
%
%   TRISURF(...,Name,Value) specifies one or more properties of the surface 
%   plot using name-value pairs. For example, 'FaceColor','y' sets the face 
%   color to yellow.
%   
%   h = TRISURF(...) returns a patch object used to create the surface plot. 
%   Use h to query and modify properties of the plot.
%
%   Examples:
%   [x,y] = meshgrid(1:15,1:15);
%   tri = delaunay(x,y);
%   z = peaks(15);
%   TRISURF(tri,x,y,z)
%
%   tr = triangulation(tri, x(:), y(:), z(:));
%   TRISURF(tr)
%
%   See also patch, trimesh, delaunay, triangulation, delaunayTriangulation.

%   Copyright 1984-2021 The MathWorks, Inc.


narginchk(1,inf);

ax = axescheck(varargin{:});
start = 1;

assert(numel(varargin)>=3 || isa(tri, 'TriRep') || isa(tri, 'triangulation'), ...
    message('MATLAB:triplot:BadArgCombination'));

if isa(tri, 'TriRep')
     if tri.size(1) == 0
        error(message('MATLAB:triplot:EmptyTri'));
     elseif tri.size(2) ~= 3
        error(message('MATLAB:triplot:NonTriangles'));
     elseif size(tri.X, 2) ~= 3
        error(message('MATLAB:triplot:NonSurfTri'));
     end
     x = tri.X(:,1);
     y = tri.X(:,2);
     z = tri.X(:,3);
     trids = tri(:,:);
     if (nargin == 1) || (mod(nargin-1,2) == 0)
       c = z;
     else
       c = varargin{1};
       start = 2;
     end
elseif isa(tri, 'triangulation')
     if tri.size(1) == 0
        error(message('MATLAB:triplot:EmptyTri'));
     elseif tri.size(2) ~= 3
        error(message('MATLAB:triplot:NonTriangles'));
     elseif size(tri.Points, 2) ~= 3
        error(message('MATLAB:triplot:NonSurfTri'));
     end
     x = tri.Points(:,1);
     y = tri.Points(:,2);
     z = tri.Points(:,3);
     trids = tri(:,:);
     if (nargin == 1) || (mod(nargin-1,2) == 0)
       c = z;
     else
       c = varargin{1};
       start = 2;
     end     
else
    x = varargin{1};
    y = varargin{2};
    z = varargin{3};
    trids = tri;
    if nargin>4 && rem(nargin-4,2)==1
      c = varargin{4};
      start = 5;
    else
      c = z;
      start = 4;
    end
end

ax = newplot(ax);

h = patch('faces',trids,'vertices',[x(:) y(:) z(:)],'facevertexcdata',c(:),...
    'facecolor',get(ax,'DefaultSurfaceFaceColor'), ...
    'edgecolor',get(ax,'DefaultSurfaceEdgeColor'),'parent',ax,...
    varargin{start:end});

switch ax.NextPlot
    case {'replaceall','replace'}
        view(ax,3);
        grid(ax,'on');
    case {'replacechildren'}
        view(ax,3);
end

if nargout==1, hh = h; end

