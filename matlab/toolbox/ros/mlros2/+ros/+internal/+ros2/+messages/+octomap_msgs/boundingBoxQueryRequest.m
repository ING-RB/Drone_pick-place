function [data, info] = boundingBoxQueryRequest
%BoundingBoxQuery gives an empty data for octomap_msgs/BoundingBoxQueryRequest

% Copyright 2019-2021 The MathWorks, Inc.
data = struct();
data.MessageType = 'octomap_msgs/BoundingBoxQueryRequest';
[data.min, info.min] = ros.internal.ros2.messages.geometry_msgs.point;
info.min.MLdataType = 'struct';
[data.max, info.max] = ros.internal.ros2.messages.geometry_msgs.point;
info.max.MLdataType = 'struct';
info.MessageType = 'octomap_msgs/BoundingBoxQueryRequest';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,8);
info.MatPath{1} = 'min';
info.MatPath{2} = 'min.x';
info.MatPath{3} = 'min.y';
info.MatPath{4} = 'min.z';
info.MatPath{5} = 'max';
info.MatPath{6} = 'max.x';
info.MatPath{7} = 'max.y';
info.MatPath{8} = 'max.z';
