function [data, info] = jointComponentTolerance
%JointComponentTolerance gives an empty data for control_msgs/JointComponentTolerance

% Copyright 2019-2021 The MathWorks, Inc.
data = struct();
data.MessageType = 'control_msgs/JointComponentTolerance';
[data.X_AXIS, info.X_AXIS] = ros.internal.ros2.messages.ros2.default_type('uint16',1,0, 1, [NaN]);
[data.Y_AXIS, info.Y_AXIS] = ros.internal.ros2.messages.ros2.default_type('uint16',1,0, 2, [NaN]);
[data.Z_AXIS, info.Z_AXIS] = ros.internal.ros2.messages.ros2.default_type('uint16',1,0, 3, [NaN]);
[data.TRANSLATION, info.TRANSLATION] = ros.internal.ros2.messages.ros2.default_type('uint16',1,0, 4, [NaN]);
[data.ROTATION, info.ROTATION] = ros.internal.ros2.messages.ros2.default_type('uint16',1,0, 5, [NaN]);
[data.joint_name, info.joint_name] = ros.internal.ros2.messages.ros2.char('string',1,NaN,0);
[data.component, info.component] = ros.internal.ros2.messages.ros2.default_type('uint16',1,0);
[data.position, info.position] = ros.internal.ros2.messages.ros2.default_type('double',1,0);
[data.velocity, info.velocity] = ros.internal.ros2.messages.ros2.default_type('double',1,0);
[data.acceleration, info.acceleration] = ros.internal.ros2.messages.ros2.default_type('double',1,0);
info.MessageType = 'control_msgs/JointComponentTolerance';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,10);
info.MatPath{1} = 'X_AXIS';
info.MatPath{2} = 'Y_AXIS';
info.MatPath{3} = 'Z_AXIS';
info.MatPath{4} = 'TRANSLATION';
info.MatPath{5} = 'ROTATION';
info.MatPath{6} = 'joint_name';
info.MatPath{7} = 'component';
info.MatPath{8} = 'position';
info.MatPath{9} = 'velocity';
info.MatPath{10} = 'acceleration';
