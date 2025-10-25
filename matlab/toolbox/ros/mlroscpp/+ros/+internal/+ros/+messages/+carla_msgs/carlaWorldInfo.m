function [data, info] = carlaWorldInfo
%CarlaWorldInfo gives an empty data for carla_msgs/CarlaWorldInfo

% Copyright 2019-2020 The MathWorks, Inc.
%#codegen
data = struct();
data.MessageType = 'carla_msgs/CarlaWorldInfo';
[data.MapName, info.MapName] = ros.internal.ros.messages.ros.char('string',0);
[data.Opendrive, info.Opendrive] = ros.internal.ros.messages.ros.char('string',0);
info.MessageType = 'carla_msgs/CarlaWorldInfo';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,2);
info.MatPath{1} = 'map_name';
info.MatPath{2} = 'opendrive';
