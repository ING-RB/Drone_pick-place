function [data, info] = singleJointPositionGoal
%SingleJointPositionGoal gives an empty data for control_msgs/SingleJointPositionGoal

% Copyright 2019-2021 The MathWorks, Inc.
data = struct();
data.MessageType = 'control_msgs/SingleJointPositionGoal';
[data.position, info.position] = ros.internal.ros2.messages.ros2.default_type('double',1,0);
[data.min_duration, info.min_duration] = ros.internal.ros2.messages.builtin_interfaces.duration;
info.min_duration.MLdataType = 'struct';
[data.max_velocity, info.max_velocity] = ros.internal.ros2.messages.ros2.default_type('double',1,0);
info.MessageType = 'control_msgs/SingleJointPositionGoal';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,5);
info.MatPath{1} = 'position';
info.MatPath{2} = 'min_duration';
info.MatPath{3} = 'min_duration.sec';
info.MatPath{4} = 'min_duration.nanosec';
info.MatPath{5} = 'max_velocity';
