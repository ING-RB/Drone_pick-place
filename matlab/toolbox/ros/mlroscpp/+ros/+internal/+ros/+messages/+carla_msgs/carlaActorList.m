function [data, info] = carlaActorList
%CarlaActorList gives an empty data for carla_msgs/CarlaActorList

% Copyright 2019-2020 The MathWorks, Inc.
%#codegen
data = struct();
data.MessageType = 'carla_msgs/CarlaActorList';
[data.Actors, info.Actors] = ros.internal.ros.messages.carla_msgs.carlaActorInfo;
info.Actors.MLdataType = 'struct';
info.Actors.MaxLen = NaN;
info.Actors.MinLen = 0;
data.Actors = data.Actors([],1);
info.MessageType = 'carla_msgs/CarlaActorList';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,5);
info.MatPath{1} = 'actors';
info.MatPath{2} = 'actors.id';
info.MatPath{3} = 'actors.parent_id';
info.MatPath{4} = 'actors.type';
info.MatPath{5} = 'actors.rolename';
