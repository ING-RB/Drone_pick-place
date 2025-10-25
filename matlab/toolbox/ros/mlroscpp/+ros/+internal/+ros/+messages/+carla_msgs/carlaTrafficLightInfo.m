function [data, info] = carlaTrafficLightInfo
%CarlaTrafficLightInfo gives an empty data for carla_msgs/CarlaTrafficLightInfo

% Copyright 2019-2020 The MathWorks, Inc.
%#codegen
data = struct();
data.MessageType = 'carla_msgs/CarlaTrafficLightInfo';
[data.Id, info.Id] = ros.internal.ros.messages.ros.default_type('uint32',1);
[data.Transform, info.Transform] = ros.internal.ros.messages.geometry_msgs.pose;
info.Transform.MLdataType = 'struct';
[data.TriggerVolume, info.TriggerVolume] = ros.internal.ros.messages.carla_msgs.carlaBoundingBox;
info.TriggerVolume.MLdataType = 'struct';
info.MessageType = 'carla_msgs/CarlaTrafficLightInfo';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,20);
info.MatPath{1} = 'id';
info.MatPath{2} = 'transform';
info.MatPath{3} = 'transform.position';
info.MatPath{4} = 'transform.position.x';
info.MatPath{5} = 'transform.position.y';
info.MatPath{6} = 'transform.position.z';
info.MatPath{7} = 'transform.orientation';
info.MatPath{8} = 'transform.orientation.x';
info.MatPath{9} = 'transform.orientation.y';
info.MatPath{10} = 'transform.orientation.z';
info.MatPath{11} = 'transform.orientation.w';
info.MatPath{12} = 'trigger_volume';
info.MatPath{13} = 'trigger_volume.center';
info.MatPath{14} = 'trigger_volume.center.x';
info.MatPath{15} = 'trigger_volume.center.y';
info.MatPath{16} = 'trigger_volume.center.z';
info.MatPath{17} = 'trigger_volume.size';
info.MatPath{18} = 'trigger_volume.size.x';
info.MatPath{19} = 'trigger_volume.size.y';
info.MatPath{20} = 'trigger_volume.size.z';
