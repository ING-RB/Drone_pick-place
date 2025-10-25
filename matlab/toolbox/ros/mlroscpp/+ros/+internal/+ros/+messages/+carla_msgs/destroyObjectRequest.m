function [data, info] = destroyObjectRequest
%DestroyObject gives an empty data for carla_msgs/DestroyObjectRequest

% Copyright 2019-2020 The MathWorks, Inc.
%#codegen
data = struct();
data.MessageType = 'carla_msgs/DestroyObjectRequest';
[data.Id, info.Id] = ros.internal.ros.messages.ros.default_type('int32',1);
info.MessageType = 'carla_msgs/DestroyObjectRequest';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,1);
info.MatPath{1} = 'id';
