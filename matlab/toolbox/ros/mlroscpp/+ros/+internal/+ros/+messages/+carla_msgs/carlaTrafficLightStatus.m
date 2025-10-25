function [data, info] = carlaTrafficLightStatus
%CarlaTrafficLightStatus gives an empty data for carla_msgs/CarlaTrafficLightStatus

% Copyright 2019-2020 The MathWorks, Inc.
%#codegen
data = struct();
data.MessageType = 'carla_msgs/CarlaTrafficLightStatus';
[data.Id, info.Id] = ros.internal.ros.messages.ros.default_type('uint32',1);
[data.RED, info.RED] = ros.internal.ros.messages.ros.default_type('uint8',1, 0);
[data.YELLOW, info.YELLOW] = ros.internal.ros.messages.ros.default_type('uint8',1, 1);
[data.GREEN, info.GREEN] = ros.internal.ros.messages.ros.default_type('uint8',1, 2);
[data.OFF, info.OFF] = ros.internal.ros.messages.ros.default_type('uint8',1, 3);
[data.UNKNOWN, info.UNKNOWN] = ros.internal.ros.messages.ros.default_type('uint8',1, 4);
[data.State, info.State] = ros.internal.ros.messages.ros.default_type('uint8',1);
info.MessageType = 'carla_msgs/CarlaTrafficLightStatus';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,7);
info.MatPath{1} = 'id';
info.MatPath{2} = 'RED';
info.MatPath{3} = 'YELLOW';
info.MatPath{4} = 'GREEN';
info.MatPath{5} = 'OFF';
info.MatPath{6} = 'UNKNOWN';
info.MatPath{7} = 'state';
