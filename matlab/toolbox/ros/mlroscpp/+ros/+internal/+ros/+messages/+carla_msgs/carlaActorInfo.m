function [data, info] = carlaActorInfo
%CarlaActorInfo gives an empty data for carla_msgs/CarlaActorInfo

% Copyright 2019-2020 The MathWorks, Inc.
%#codegen
data = struct();
data.MessageType = 'carla_msgs/CarlaActorInfo';
[data.Id, info.Id] = ros.internal.ros.messages.ros.default_type('uint32',1);
[data.ParentId, info.ParentId] = ros.internal.ros.messages.ros.default_type('uint32',1);
[data.Type, info.Type] = ros.internal.ros.messages.ros.char('string',0);
[data.Rolename, info.Rolename] = ros.internal.ros.messages.ros.char('string',0);
info.MessageType = 'carla_msgs/CarlaActorInfo';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,4);
info.MatPath{1} = 'id';
info.MatPath{2} = 'parent_id';
info.MatPath{3} = 'type';
info.MatPath{4} = 'rolename';
