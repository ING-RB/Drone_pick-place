function setgeometry(h,varargin)
%SETGEOMETRY  Sets grid geometry.

%   Copyright 1986-2004 The MathWorks, Inc.

% Pass new geometry to @plotpair (no listeners!)
h.Axes.Geometry = h.Geometry;

% Update plot
if h.Axes.Visible
   refresh(h.Axes)
end
