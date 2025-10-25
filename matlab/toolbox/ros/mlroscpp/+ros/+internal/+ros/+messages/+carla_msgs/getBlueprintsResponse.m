function [data, info] = getBlueprintsResponse
%GetBlueprints gives an empty data for carla_msgs/GetBlueprintsResponse

% Copyright 2019-2020 The MathWorks, Inc.
%#codegen
data = struct();
data.MessageType = 'carla_msgs/GetBlueprintsResponse';
[data.Blueprints, info.Blueprints] = ros.internal.ros.messages.ros.char('string',NaN);
info.MessageType = 'carla_msgs/GetBlueprintsResponse';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,1);
info.MatPath{1} = 'blueprints';
