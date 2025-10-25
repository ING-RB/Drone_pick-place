function [data, info] = getBlueprintsRequest
%GetBlueprints gives an empty data for carla_msgs/GetBlueprintsRequest

% Copyright 2019-2020 The MathWorks, Inc.
%#codegen
data = struct();
data.MessageType = 'carla_msgs/GetBlueprintsRequest';
[data.Filter, info.Filter] = ros.internal.ros.messages.ros.char('string',0);
info.MessageType = 'carla_msgs/GetBlueprintsRequest';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,1);
info.MatPath{1} = 'filter';
