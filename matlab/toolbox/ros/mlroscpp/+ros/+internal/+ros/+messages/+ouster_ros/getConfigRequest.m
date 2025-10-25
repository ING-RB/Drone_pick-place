function [data, info] = getConfigRequest
%GetConfig gives an empty data for ouster_ros/GetConfigRequest

% Copyright 2019-2020 The MathWorks, Inc.
data = struct();
data.MessageType = 'ouster_ros/GetConfigRequest';
info.MessageType = 'ouster_ros/GetConfigRequest';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,0);
