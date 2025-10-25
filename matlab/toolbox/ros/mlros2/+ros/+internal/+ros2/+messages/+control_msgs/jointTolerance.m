function [data, info] = jointTolerance
%JointTolerance gives an empty data for control_msgs/JointTolerance

% Copyright 2019-2021 The MathWorks, Inc.
data = struct();
data.MessageType = 'control_msgs/JointTolerance';
[data.name, info.name] = ros.internal.ros2.messages.ros2.char('string',1,NaN,0);
[data.position, info.position] = ros.internal.ros2.messages.ros2.default_type('double',1,0);
[data.velocity, info.velocity] = ros.internal.ros2.messages.ros2.default_type('double',1,0);
[data.acceleration, info.acceleration] = ros.internal.ros2.messages.ros2.default_type('double',1,0);
info.MessageType = 'control_msgs/JointTolerance';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,4);
info.MatPath{1} = 'name';
info.MatPath{2} = 'position';
info.MatPath{3} = 'velocity';
info.MatPath{4} = 'acceleration';
