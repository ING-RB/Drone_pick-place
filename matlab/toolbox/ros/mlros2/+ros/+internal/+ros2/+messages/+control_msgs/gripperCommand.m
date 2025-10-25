function [data, info] = gripperCommand
%GripperCommand gives an empty data for control_msgs/GripperCommand

% Copyright 2019-2021 The MathWorks, Inc.
data = struct();
data.MessageType = 'control_msgs/GripperCommand';
[data.position, info.position] = ros.internal.ros2.messages.ros2.default_type('double',1,0);
[data.max_effort, info.max_effort] = ros.internal.ros2.messages.ros2.default_type('double',1,0);
info.MessageType = 'control_msgs/GripperCommand';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,2);
info.MatPath{1} = 'position';
info.MatPath{2} = 'max_effort';
