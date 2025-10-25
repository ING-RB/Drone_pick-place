function [data, info] = polygonInstance
%PolygonInstance gives an empty data for geometry_msgs/PolygonInstance

% Copyright 2019-2021 The MathWorks, Inc.
data = struct();
data.MessageType = 'geometry_msgs/PolygonInstance';
[data.polygon, info.polygon] = ros.internal.ros2.messages.geometry_msgs.polygon;
info.polygon.MLdataType = 'struct';
[data.id, info.id] = ros.internal.ros2.messages.ros2.default_type('int64',1,0);
info.MessageType = 'geometry_msgs/PolygonInstance';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,6);
info.MatPath{1} = 'polygon';
info.MatPath{2} = 'polygon.points';
info.MatPath{3} = 'polygon.points.x';
info.MatPath{4} = 'polygon.points.y';
info.MatPath{5} = 'polygon.points.z';
info.MatPath{6} = 'id';
