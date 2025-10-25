function index = doGetNearestPoint(obj, position)
%doGetNearestPoint Find the nearest violinplot index
%
%  doGetNearestPoint(obj, pixel) returns the data index closest to the
%  given point on screen.

%  Copyright 2024 The MathWorks, Inc.

% Obtain a list of vertices from all graphics primitives
verts = obj.DataTipsVertexData;

% Find the closest vertex and return its index
pickUtils = matlab.graphics.chart.interaction.dataannotatable.picking.AnnotatablePicker.getInstance();
index = pickUtils.nearestPoint(obj, position, true, verts(:,1:2));
index = verts(index,3);  % This seems unnecessary... BE
