function [data, info] = spawnObjectResponse
%SpawnObject gives an empty data for carla_msgs/SpawnObjectResponse

% Copyright 2019-2020 The MathWorks, Inc.
%#codegen
data = struct();
data.MessageType = 'carla_msgs/SpawnObjectResponse';
[data.Id, info.Id] = ros.internal.ros.messages.ros.default_type('int32',1);
[data.ErrorString, info.ErrorString] = ros.internal.ros.messages.ros.char('string',0);
info.MessageType = 'carla_msgs/SpawnObjectResponse';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,2);
info.MatPath{1} = 'id';
info.MatPath{2} = 'error_string';
