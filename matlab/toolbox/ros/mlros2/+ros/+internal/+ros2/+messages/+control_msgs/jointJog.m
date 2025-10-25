function [data, info] = jointJog
%JointJog gives an empty data for control_msgs/JointJog

% Copyright 2019-2021 The MathWorks, Inc.
data = struct();
data.MessageType = 'control_msgs/JointJog';
[data.header, info.header] = ros.internal.ros2.messages.std_msgs.header;
info.header.MLdataType = 'struct';
[data.joint_names, info.joint_names] = ros.internal.ros2.messages.ros2.char('string',NaN,NaN,0);
[data.displacements, info.displacements] = ros.internal.ros2.messages.ros2.default_type('double',NaN,0);
[data.velocities, info.velocities] = ros.internal.ros2.messages.ros2.default_type('double',NaN,0);
[data.duration, info.duration] = ros.internal.ros2.messages.ros2.default_type('double',1,0);
info.MessageType = 'control_msgs/JointJog';
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
info.MatPath{6} = 'joint_names';
info.MatPath{7} = 'displacements';
info.MatPath{8} = 'velocities';
info.MatPath{9} = 'duration';
