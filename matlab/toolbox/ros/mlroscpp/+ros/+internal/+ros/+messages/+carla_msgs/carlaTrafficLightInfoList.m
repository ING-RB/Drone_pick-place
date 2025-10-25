function [data, info] = carlaTrafficLightInfoList
%CarlaTrafficLightInfoList gives an empty data for carla_msgs/CarlaTrafficLightInfoList

% Copyright 2019-2020 The MathWorks, Inc.
%#codegen
data = struct();
data.MessageType = 'carla_msgs/CarlaTrafficLightInfoList';
[data.TrafficLights, info.TrafficLights] = ros.internal.ros.messages.carla_msgs.carlaTrafficLightInfo;
info.TrafficLights.MLdataType = 'struct';
info.TrafficLights.MaxLen = NaN;
info.TrafficLights.MinLen = 0;
data.TrafficLights = data.TrafficLights([],1);
info.MessageType = 'carla_msgs/CarlaTrafficLightInfoList';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,21);
info.MatPath{1} = 'traffic_lights';
info.MatPath{2} = 'traffic_lights.id';
info.MatPath{3} = 'traffic_lights.transform';
info.MatPath{4} = 'traffic_lights.transform.position';
info.MatPath{5} = 'traffic_lights.transform.position.x';
info.MatPath{6} = 'traffic_lights.transform.position.y';
info.MatPath{7} = 'traffic_lights.transform.position.z';
info.MatPath{8} = 'traffic_lights.transform.orientation';
info.MatPath{9} = 'traffic_lights.transform.orientation.x';
info.MatPath{10} = 'traffic_lights.transform.orientation.y';
info.MatPath{11} = 'traffic_lights.transform.orientation.z';
info.MatPath{12} = 'traffic_lights.transform.orientation.w';
info.MatPath{13} = 'traffic_lights.trigger_volume';
info.MatPath{14} = 'traffic_lights.trigger_volume.center';
info.MatPath{15} = 'traffic_lights.trigger_volume.center.x';
info.MatPath{16} = 'traffic_lights.trigger_volume.center.y';
info.MatPath{17} = 'traffic_lights.trigger_volume.center.z';
info.MatPath{18} = 'traffic_lights.trigger_volume.size';
info.MatPath{19} = 'traffic_lights.trigger_volume.size.x';
info.MatPath{20} = 'traffic_lights.trigger_volume.size.y';
info.MatPath{21} = 'traffic_lights.trigger_volume.size.z';
