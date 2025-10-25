function [data, info] = egoVehicleControlMaxima
%EgoVehicleControlMaxima gives an empty data for carla_ackermann_msgs/EgoVehicleControlMaxima

% Copyright 2019-2020 The MathWorks, Inc.
%#codegen
data = struct();
data.MessageType = 'carla_ackermann_msgs/EgoVehicleControlMaxima';
[data.MaxSteeringAngle, info.MaxSteeringAngle] = ros.internal.ros.messages.ros.default_type('single',1);
[data.MaxSpeed, info.MaxSpeed] = ros.internal.ros.messages.ros.default_type('single',1);
[data.MaxAccel, info.MaxAccel] = ros.internal.ros.messages.ros.default_type('single',1);
[data.MaxDecel, info.MaxDecel] = ros.internal.ros.messages.ros.default_type('single',1);
[data.MinAccel, info.MinAccel] = ros.internal.ros.messages.ros.default_type('single',1);
[data.MaxPedal, info.MaxPedal] = ros.internal.ros.messages.ros.default_type('single',1);
info.MessageType = 'carla_ackermann_msgs/EgoVehicleControlMaxima';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,6);
info.MatPath{1} = 'max_steering_angle';
info.MatPath{2} = 'max_speed';
info.MatPath{3} = 'max_accel';
info.MatPath{4} = 'max_decel';
info.MatPath{5} = 'min_accel';
info.MatPath{6} = 'max_pedal';
