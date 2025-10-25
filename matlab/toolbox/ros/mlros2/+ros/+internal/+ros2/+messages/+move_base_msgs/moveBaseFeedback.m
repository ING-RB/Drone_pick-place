function [data, info] = moveBaseFeedback
%MoveBaseFeedback gives an empty data for move_base_msgs/MoveBaseFeedback

% Copyright 2019-2021 The MathWorks, Inc.
data = struct();
data.MessageType = 'move_base_msgs/MoveBaseFeedback';
[data.base_position, info.base_position] = ros.internal.ros2.messages.geometry_msgs.poseStamped;
info.base_position.MLdataType = 'struct';
info.MessageType = 'move_base_msgs/MoveBaseFeedback';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,16);
info.MatPath{1} = 'base_position';
info.MatPath{2} = 'base_position.header';
info.MatPath{3} = 'base_position.header.stamp';
info.MatPath{4} = 'base_position.header.stamp.sec';
info.MatPath{5} = 'base_position.header.stamp.nanosec';
info.MatPath{6} = 'base_position.header.frame_id';
info.MatPath{7} = 'base_position.pose';
info.MatPath{8} = 'base_position.pose.position';
info.MatPath{9} = 'base_position.pose.position.x';
info.MatPath{10} = 'base_position.pose.position.y';
info.MatPath{11} = 'base_position.pose.position.z';
info.MatPath{12} = 'base_position.pose.orientation';
info.MatPath{13} = 'base_position.pose.orientation.x';
info.MatPath{14} = 'base_position.pose.orientation.y';
info.MatPath{15} = 'base_position.pose.orientation.z';
info.MatPath{16} = 'base_position.pose.orientation.w';
