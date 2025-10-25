function [data, info] = carlaTrafficLightStatusList
%CarlaTrafficLightStatusList gives an empty data for carla_msgs/CarlaTrafficLightStatusList

% Copyright 2019-2020 The MathWorks, Inc.
%#codegen
data = struct();
data.MessageType = 'carla_msgs/CarlaTrafficLightStatusList';
[data.TrafficLights, info.TrafficLights] = ros.internal.ros.messages.carla_msgs.carlaTrafficLightStatus;
info.TrafficLights.MLdataType = 'struct';
info.TrafficLights.MaxLen = NaN;
info.TrafficLights.MinLen = 0;
data.TrafficLights = data.TrafficLights([],1);
info.MessageType = 'carla_msgs/CarlaTrafficLightStatusList';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,8);
info.MatPath{1} = 'traffic_lights';
info.MatPath{2} = 'traffic_lights.id';
info.MatPath{3} = 'traffic_lights.RED';
info.MatPath{4} = 'traffic_lights.YELLOW';
info.MatPath{5} = 'traffic_lights.GREEN';
info.MatPath{6} = 'traffic_lights.OFF';
info.MatPath{7} = 'traffic_lights.UNKNOWN';
info.MatPath{8} = 'traffic_lights.state';
