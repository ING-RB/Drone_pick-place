function [data, info] = uVCoordinate
%UVCoordinate gives an empty data for visualization_msgs/UVCoordinate

% Copyright 2019-2021 The MathWorks, Inc.
data = struct();
data.MessageType = 'visualization_msgs/UVCoordinate';
[data.u, info.u] = ros.internal.ros2.messages.ros2.default_type('single',1,0);
[data.v, info.v] = ros.internal.ros2.messages.ros2.default_type('single',1,0);
info.MessageType = 'visualization_msgs/UVCoordinate';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,2);
info.MatPath{1} = 'u';
info.MatPath{2} = 'v';
