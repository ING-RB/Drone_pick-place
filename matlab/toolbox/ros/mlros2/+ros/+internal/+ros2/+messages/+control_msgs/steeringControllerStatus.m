function [data, info] = steeringControllerStatus
%SteeringControllerStatus gives an empty data for control_msgs/SteeringControllerStatus

% Copyright 2019-2021 The MathWorks, Inc.
data = struct();
data.MessageType = 'control_msgs/SteeringControllerStatus';
[data.header, info.header] = ros.internal.ros2.messages.std_msgs.header;
info.header.MLdataType = 'struct';
[data.traction_wheels_position, info.traction_wheels_position] = ros.internal.ros2.messages.ros2.default_type('double',NaN,0);
[data.traction_wheels_velocity, info.traction_wheels_velocity] = ros.internal.ros2.messages.ros2.default_type('double',NaN,0);
[data.steer_positions, info.steer_positions] = ros.internal.ros2.messages.ros2.default_type('double',NaN,0);
[data.linear_velocity_command, info.linear_velocity_command] = ros.internal.ros2.messages.ros2.default_type('double',NaN,0);
[data.steering_angle_command, info.steering_angle_command] = ros.internal.ros2.messages.ros2.default_type('double',NaN,0);
info.MessageType = 'control_msgs/SteeringControllerStatus';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,10);
info.MatPath{1} = 'header';
info.MatPath{2} = 'header.stamp';
info.MatPath{3} = 'header.stamp.sec';
info.MatPath{4} = 'header.stamp.nanosec';
info.MatPath{5} = 'header.frame_id';
info.MatPath{6} = 'traction_wheels_position';
info.MatPath{7} = 'traction_wheels_velocity';
info.MatPath{8} = 'steer_positions';
info.MatPath{9} = 'linear_velocity_command';
info.MatPath{10} = 'steering_angle_command';
