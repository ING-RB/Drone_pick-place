function [data, info] = singleJointPositionFeedback
%SingleJointPositionFeedback gives an empty data for control_msgs/SingleJointPositionFeedback

% Copyright 2019-2021 The MathWorks, Inc.
data = struct();
data.MessageType = 'control_msgs/SingleJointPositionFeedback';
[data.header, info.header] = ros.internal.ros2.messages.std_msgs.header;
info.header.MLdataType = 'struct';
[data.position, info.position] = ros.internal.ros2.messages.ros2.default_type('double',1,0);
[data.velocity, info.velocity] = ros.internal.ros2.messages.ros2.default_type('double',1,0);
[data.error, info.error] = ros.internal.ros2.messages.ros2.default_type('double',1,0);
info.MessageType = 'control_msgs/SingleJointPositionFeedback';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,8);
info.MatPath{1} = 'header';
info.MatPath{2} = 'header.stamp';
info.MatPath{3} = 'header.stamp.sec';
info.MatPath{4} = 'header.stamp.nanosec';
info.MatPath{5} = 'header.frame_id';
info.MatPath{6} = 'position';
info.MatPath{7} = 'velocity';
info.MatPath{8} = 'error';
