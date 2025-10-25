function [data, info] = getMetadataRequest
%GetMetadata gives an empty data for ouster_ros/GetMetadataRequest

% Copyright 2019-2020 The MathWorks, Inc.
data = struct();
data.MessageType = 'ouster_ros/GetMetadataRequest';
info.MessageType = 'ouster_ros/GetMetadataRequest';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,0);
