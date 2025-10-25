function [data, info] = gripperCommandResult
%GripperCommandResult gives an empty data for control_msgs/GripperCommandResult

% Copyright 2019-2021 The MathWorks, Inc.
data = struct();
data.MessageType = 'control_msgs/GripperCommandResult';
[data.position, info.position] = ros.internal.ros2.messages.ros2.default_type('double',1,0);
[data.effort, info.effort] = ros.internal.ros2.messages.ros2.default_type('double',1,0);
[data.stalled, info.stalled] = ros.internal.ros2.messages.ros2.default_type('logical',1,0);
[data.reached_goal, info.reached_goal] = ros.internal.ros2.messages.ros2.default_type('logical',1,0);
info.MessageType = 'control_msgs/GripperCommandResult';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,4);
info.MatPath{1} = 'position';
info.MatPath{2} = 'effort';
info.MatPath{3} = 'stalled';
info.MatPath{4} = 'reached_goal';
