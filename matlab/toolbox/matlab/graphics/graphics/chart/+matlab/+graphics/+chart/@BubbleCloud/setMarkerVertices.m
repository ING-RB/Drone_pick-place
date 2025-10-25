function setMarkerVertices(obj)
%

%   Copyright 2020 The MathWorks, Inc.

% Transform locations of bubbles to Marker VertexData

iter = matlab.graphics.axis.dataspace.XYZPointsIterator;
iter.XData_I = obj.XYR(1,:);
iter.YData_I = obj.XYR(2,:);
vd = TransformPoints(obj.Axes.DataSpace,[],iter);
obj.Marker.VertexData=vd;
end
