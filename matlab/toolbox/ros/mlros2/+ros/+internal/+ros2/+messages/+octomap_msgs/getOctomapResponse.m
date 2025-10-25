function [data, info] = getOctomapResponse
%GetOctomap gives an empty data for octomap_msgs/GetOctomapResponse

% Copyright 2019-2021 The MathWorks, Inc.
data = struct();
data.MessageType = 'octomap_msgs/GetOctomapResponse';
[data.map, info.map] = ros.internal.ros2.messages.octomap_msgs.octomap;
info.map.MLdataType = 'struct';
info.MessageType = 'octomap_msgs/GetOctomapResponse';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,10);
info.MatPath{1} = 'map';
info.MatPath{2} = 'map.header';
info.MatPath{3} = 'map.header.stamp';
info.MatPath{4} = 'map.header.stamp.sec';
info.MatPath{5} = 'map.header.stamp.nanosec';
info.MatPath{6} = 'map.header.frame_id';
info.MatPath{7} = 'map.binary';
info.MatPath{8} = 'map.id';
info.MatPath{9} = 'map.resolution';
info.MatPath{10} = 'map.data';
