function [data, info] = egoVehicleControlTarget
%EgoVehicleControlTarget gives an empty data for carla_ackermann_msgs/EgoVehicleControlTarget

% Copyright 2019-2020 The MathWorks, Inc.
%#codegen
data = struct();
data.MessageType = 'carla_ackermann_msgs/EgoVehicleControlTarget';
[data.SteeringAngle, info.SteeringAngle] = ros.internal.ros.messages.ros.default_type('single',1);
[data.Speed, info.Speed] = ros.internal.ros.messages.ros.default_type('single',1);
[data.SpeedAbs, info.SpeedAbs] = ros.internal.ros.messages.ros.default_type('single',1);
[data.Accel, info.Accel] = ros.internal.ros.messages.ros.default_type('single',1);
[data.Jerk, info.Jerk] = ros.internal.ros.messages.ros.default_type('single',1);
info.MessageType = 'carla_ackermann_msgs/EgoVehicleControlTarget';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,5);
info.MatPath{1} = 'steering_angle';
info.MatPath{2} = 'speed';
info.MatPath{3} = 'speed_abs';
info.MatPath{4} = 'accel';
info.MatPath{5} = 'jerk';
