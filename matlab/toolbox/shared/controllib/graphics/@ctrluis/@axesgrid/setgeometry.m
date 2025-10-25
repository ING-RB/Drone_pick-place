function setgeometry(h,varargin)
%SETGEOMETRY  Sets grid geometry.

%   Author(s): P. Gahinet
%   Copyright 1986-2008 The MathWorks, Inc.

% Pass new geometry to @plotarray (no listeners!)
h.Axes.Geometry = h.Geometry(1);
if length(h.Geometry)==2 && ~ishghandle(h.Axes.Axes(1),'axes')
   % Specifying the geometry of both major and minor grids
   % Subgrid geometry
   set(h.Axes.Axes,'Geometry',h.Geometry(2))
end

% Update plot
if h.Axes.Visible
   refresh(h.Axes)
end
