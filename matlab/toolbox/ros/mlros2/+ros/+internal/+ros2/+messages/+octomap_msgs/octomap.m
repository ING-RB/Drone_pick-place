function [data, info] = octomap
%Octomap gives an empty data for octomap_msgs/Octomap

% Copyright 2019-2021 The MathWorks, Inc.
data = struct();
data.MessageType = 'octomap_msgs/Octomap';
[data.header, info.header] = ros.internal.ros2.messages.std_msgs.header;
info.header.MLdataType = 'struct';
[data.binary, info.binary] = ros.internal.ros2.messages.ros2.default_type('logical',1,0);
[data.id, info.id] = ros.internal.ros2.messages.ros2.char('string',1,NaN,0);
[data.resolution, info.resolution] = ros.internal.ros2.messages.ros2.default_type('double',1,0);
[data.data, info.data] = ros.internal.ros2.messages.ros2.default_type('int8',NaN,0);
info.MessageType = 'octomap_msgs/Octomap';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,9);
info.MatPath{1} = 'header';
info.MatPath{2} = 'header.stamp';
info.MatPath{3} = 'header.stamp.sec';
info.MatPath{4} = 'header.stamp.nanosec';
info.MatPath{5} = 'header.frame_id';
info.MatPath{6} = 'binary';
info.MatPath{7} = 'id';
info.MatPath{8} = 'resolution';
info.MatPath{9} = 'data';
