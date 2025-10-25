function [data, info] = setConfigRequest
%SetConfig gives an empty data for ouster_ros/SetConfigRequest

% Copyright 2019-2020 The MathWorks, Inc.
data = struct();
data.MessageType = 'ouster_ros/SetConfigRequest';
[data.ConfigFile, info.ConfigFile] = ros.internal.ros.messages.ros.char('string',0);
info.MessageType = 'ouster_ros/SetConfigRequest';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,1);
info.MatPath{1} = 'config_file';
