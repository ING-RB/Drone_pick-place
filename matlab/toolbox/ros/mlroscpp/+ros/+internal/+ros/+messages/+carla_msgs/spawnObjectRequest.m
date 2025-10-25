function [data, info] = spawnObjectRequest
%SpawnObject gives an empty data for carla_msgs/SpawnObjectRequest

% Copyright 2019-2020 The MathWorks, Inc.
%#codegen
data = struct();
data.MessageType = 'carla_msgs/SpawnObjectRequest';
[data.Type, info.Type] = ros.internal.ros.messages.ros.char('string',0);
[data.Id, info.Id] = ros.internal.ros.messages.ros.char('string',0);
[data.Attributes, info.Attributes] = ros.internal.ros.messages.diagnostic_msgs.keyValue;
info.Attributes.MLdataType = 'struct';
info.Attributes.MaxLen = NaN;
info.Attributes.MinLen = 0;
data.Attributes = data.Attributes([],1);
[data.Transform, info.Transform] = ros.internal.ros.messages.geometry_msgs.pose;
info.Transform.MLdataType = 'struct';
[data.AttachTo, info.AttachTo] = ros.internal.ros.messages.ros.default_type('uint32',1);
[data.RandomPose, info.RandomPose] = ros.internal.ros.messages.ros.default_type('logical',1);
info.MessageType = 'carla_msgs/SpawnObjectRequest';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,17);
info.MatPath{1} = 'type';
info.MatPath{2} = 'id';
info.MatPath{3} = 'attributes';
info.MatPath{4} = 'attributes.key';
info.MatPath{5} = 'attributes.value';
info.MatPath{6} = 'transform';
info.MatPath{7} = 'transform.position';
info.MatPath{8} = 'transform.position.x';
info.MatPath{9} = 'transform.position.y';
info.MatPath{10} = 'transform.position.z';
info.MatPath{11} = 'transform.orientation';
info.MatPath{12} = 'transform.orientation.x';
info.MatPath{13} = 'transform.orientation.y';
info.MatPath{14} = 'transform.orientation.z';
info.MatPath{15} = 'transform.orientation.w';
info.MatPath{16} = 'attach_to';
info.MatPath{17} = 'random_pose';
