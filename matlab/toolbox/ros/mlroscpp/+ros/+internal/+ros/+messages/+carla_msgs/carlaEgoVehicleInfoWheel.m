function [data, info] = carlaEgoVehicleInfoWheel
%CarlaEgoVehicleInfoWheel gives an empty data for carla_msgs/CarlaEgoVehicleInfoWheel

% Copyright 2019-2020 The MathWorks, Inc.
%#codegen
data = struct();
data.MessageType = 'carla_msgs/CarlaEgoVehicleInfoWheel';
[data.TireFriction, info.TireFriction] = ros.internal.ros.messages.ros.default_type('single',1);
[data.DampingRate, info.DampingRate] = ros.internal.ros.messages.ros.default_type('single',1);
[data.MaxSteerAngle, info.MaxSteerAngle] = ros.internal.ros.messages.ros.default_type('single',1);
[data.Radius, info.Radius] = ros.internal.ros.messages.ros.default_type('single',1);
[data.MaxBrakeTorque, info.MaxBrakeTorque] = ros.internal.ros.messages.ros.default_type('single',1);
[data.MaxHandbrakeTorque, info.MaxHandbrakeTorque] = ros.internal.ros.messages.ros.default_type('single',1);
[data.Position, info.Position] = ros.internal.ros.messages.geometry_msgs.vector3;
info.Position.MLdataType = 'struct';
info.MessageType = 'carla_msgs/CarlaEgoVehicleInfoWheel';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,10);
info.MatPath{1} = 'tire_friction';
info.MatPath{2} = 'damping_rate';
info.MatPath{3} = 'max_steer_angle';
info.MatPath{4} = 'radius';
info.MatPath{5} = 'max_brake_torque';
info.MatPath{6} = 'max_handbrake_torque';
info.MatPath{7} = 'position';
info.MatPath{8} = 'position.x';
info.MatPath{9} = 'position.y';
info.MatPath{10} = 'position.z';
