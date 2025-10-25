function [data, info] = carlaWalkerControl
%CarlaWalkerControl gives an empty data for carla_msgs/CarlaWalkerControl

% Copyright 2019-2020 The MathWorks, Inc.
%#codegen
data = struct();
data.MessageType = 'carla_msgs/CarlaWalkerControl';
[data.Direction, info.Direction] = ros.internal.ros.messages.geometry_msgs.vector3;
info.Direction.MLdataType = 'struct';
[data.Speed, info.Speed] = ros.internal.ros.messages.ros.default_type('single',1);
[data.Jump, info.Jump] = ros.internal.ros.messages.ros.default_type('logical',1);
info.MessageType = 'carla_msgs/CarlaWalkerControl';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,6);
info.MatPath{1} = 'direction';
info.MatPath{2} = 'direction.x';
info.MatPath{3} = 'direction.y';
info.MatPath{4} = 'direction.z';
info.MatPath{5} = 'speed';
info.MatPath{6} = 'jump';
