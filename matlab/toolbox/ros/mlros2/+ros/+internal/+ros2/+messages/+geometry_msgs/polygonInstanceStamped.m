function [data, info] = polygonInstanceStamped
%PolygonInstanceStamped gives an empty data for geometry_msgs/PolygonInstanceStamped

% Copyright 2019-2021 The MathWorks, Inc.
data = struct();
data.MessageType = 'geometry_msgs/PolygonInstanceStamped';
[data.header, info.header] = ros.internal.ros2.messages.std_msgs.header;
info.header.MLdataType = 'struct';
[data.polygon, info.polygon] = ros.internal.ros2.messages.geometry_msgs.polygonInstance;
info.polygon.MLdataType = 'struct';
info.MessageType = 'geometry_msgs/PolygonInstanceStamped';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,12);
info.MatPath{1} = 'header';
info.MatPath{2} = 'header.stamp';
info.MatPath{3} = 'header.stamp.sec';
info.MatPath{4} = 'header.stamp.nanosec';
info.MatPath{5} = 'header.frame_id';
info.MatPath{6} = 'polygon';
info.MatPath{7} = 'polygon.polygon';
info.MatPath{8} = 'polygon.polygon.points';
info.MatPath{9} = 'polygon.polygon.points.x';
info.MatPath{10} = 'polygon.polygon.points.y';
info.MatPath{11} = 'polygon.polygon.points.z';
info.MatPath{12} = 'polygon.id';
