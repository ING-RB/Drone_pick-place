function [data, info] = getConfigResponse
%GetConfig gives an empty data for ouster_ros/GetConfigResponse

% Copyright 2019-2020 The MathWorks, Inc.
data = struct();
data.MessageType = 'ouster_ros/GetConfigResponse';
[data.Config, info.Config] = ros.internal.ros.messages.ros.char('string',0);
info.MessageType = 'ouster_ros/GetConfigResponse';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,1);
info.MatPath{1} = 'config';
