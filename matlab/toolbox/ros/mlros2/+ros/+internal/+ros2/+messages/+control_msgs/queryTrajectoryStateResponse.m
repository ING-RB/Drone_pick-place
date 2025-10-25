function [data, info] = queryTrajectoryStateResponse
%QueryTrajectoryState gives an empty data for control_msgs/QueryTrajectoryStateResponse

% Copyright 2019-2021 The MathWorks, Inc.
data = struct();
data.MessageType = 'control_msgs/QueryTrajectoryStateResponse';
[data.success, info.success] = ros.internal.ros2.messages.ros2.default_type('logical',1,0);
[data.message, info.message] = ros.internal.ros2.messages.ros2.char('string',1,NaN,0);
[data.name, info.name] = ros.internal.ros2.messages.ros2.char('string',NaN,NaN,0);
[data.position, info.position] = ros.internal.ros2.messages.ros2.default_type('double',NaN,0);
[data.velocity, info.velocity] = ros.internal.ros2.messages.ros2.default_type('double',NaN,0);
[data.acceleration, info.acceleration] = ros.internal.ros2.messages.ros2.default_type('double',NaN,0);
info.MessageType = 'control_msgs/QueryTrajectoryStateResponse';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,6);
info.MatPath{1} = 'success';
info.MatPath{2} = 'message';
info.MatPath{3} = 'name';
info.MatPath{4} = 'position';
info.MatPath{5} = 'velocity';
info.MatPath{6} = 'acceleration';
