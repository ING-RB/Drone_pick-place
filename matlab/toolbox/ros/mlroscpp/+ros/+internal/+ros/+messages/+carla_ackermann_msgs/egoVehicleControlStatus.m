function [data, info] = egoVehicleControlStatus
%EgoVehicleControlStatus gives an empty data for carla_ackermann_msgs/EgoVehicleControlStatus

% Copyright 2019-2020 The MathWorks, Inc.
%#codegen
data = struct();
data.MessageType = 'carla_ackermann_msgs/EgoVehicleControlStatus';
[data.Status, info.Status] = ros.internal.ros.messages.ros.char('string',0);
[data.SpeedControlActivationCount, info.SpeedControlActivationCount] = ros.internal.ros.messages.ros.default_type('uint8',1);
[data.SpeedControlAccelDelta, info.SpeedControlAccelDelta] = ros.internal.ros.messages.ros.default_type('single',1);
[data.SpeedControlAccelTarget, info.SpeedControlAccelTarget] = ros.internal.ros.messages.ros.default_type('single',1);
[data.AccelControlPedalDelta, info.AccelControlPedalDelta] = ros.internal.ros.messages.ros.default_type('single',1);
[data.AccelControlPedalTarget, info.AccelControlPedalTarget] = ros.internal.ros.messages.ros.default_type('single',1);
[data.BrakeUpperBorder, info.BrakeUpperBorder] = ros.internal.ros.messages.ros.default_type('single',1);
[data.ThrottleLowerBorder, info.ThrottleLowerBorder] = ros.internal.ros.messages.ros.default_type('single',1);
info.MessageType = 'carla_ackermann_msgs/EgoVehicleControlStatus';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,8);
info.MatPath{1} = 'status';
info.MatPath{2} = 'speed_control_activation_count';
info.MatPath{3} = 'speed_control_accel_delta';
info.MatPath{4} = 'speed_control_accel_target';
info.MatPath{5} = 'accel_control_pedal_delta';
info.MatPath{6} = 'accel_control_pedal_target';
info.MatPath{7} = 'brake_upper_border';
info.MatPath{8} = 'throttle_lower_border';
