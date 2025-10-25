function [data, info] = gripperCommandGoal
%GripperCommandGoal gives an empty data for control_msgs/GripperCommandGoal

% Copyright 2019-2021 The MathWorks, Inc.
data = struct();
data.MessageType = 'control_msgs/GripperCommandGoal';
[data.command, info.command] = ros.internal.ros2.messages.control_msgs.gripperCommand;
info.command.MLdataType = 'struct';
info.MessageType = 'control_msgs/GripperCommandGoal';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,3);
info.MatPath{1} = 'command';
info.MatPath{2} = 'command.position';
info.MatPath{3} = 'command.max_effort';
