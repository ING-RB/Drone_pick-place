function [data, info] = carlaEgoVehicleControl
%CarlaEgoVehicleControl gives an empty data for carla_msgs/CarlaEgoVehicleControl

% Copyright 2019-2020 The MathWorks, Inc.
%#codegen
data = struct();
data.MessageType = 'carla_msgs/CarlaEgoVehicleControl';
[data.Header, info.Header] = ros.internal.ros.messages.std_msgs.header;
info.Header.MLdataType = 'struct';
[data.Throttle, info.Throttle] = ros.internal.ros.messages.ros.default_type('single',1);
[data.Steer, info.Steer] = ros.internal.ros.messages.ros.default_type('single',1);
[data.Brake, info.Brake] = ros.internal.ros.messages.ros.default_type('single',1);
[data.HandBrake, info.HandBrake] = ros.internal.ros.messages.ros.default_type('logical',1);
[data.Reverse, info.Reverse] = ros.internal.ros.messages.ros.default_type('logical',1);
[data.Gear, info.Gear] = ros.internal.ros.messages.ros.default_type('int32',1);
[data.ManualGearShift, info.ManualGearShift] = ros.internal.ros.messages.ros.default_type('logical',1);
info.MessageType = 'carla_msgs/CarlaEgoVehicleControl';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,13);
info.MatPath{1} = 'header';
info.MatPath{2} = 'header.seq';
info.MatPath{3} = 'header.stamp';
info.MatPath{4} = 'header.stamp.sec';
info.MatPath{5} = 'header.stamp.nsec';
info.MatPath{6} = 'header.frame_id';
info.MatPath{7} = 'throttle';
info.MatPath{8} = 'steer';
info.MatPath{9} = 'brake';
info.MatPath{10} = 'hand_brake';
info.MatPath{11} = 'reverse';
info.MatPath{12} = 'gear';
info.MatPath{13} = 'manual_gear_shift';
