function [data, info] = getMetadataResponse
%GetMetadata gives an empty data for ouster_ros/GetMetadataResponse

% Copyright 2019-2020 The MathWorks, Inc.
data = struct();
data.MessageType = 'ouster_ros/GetMetadataResponse';
[data.Metadata, info.Metadata] = ros.internal.ros.messages.ros.char('string',0);
info.MessageType = 'ouster_ros/GetMetadataResponse';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,1);
info.MatPath{1} = 'metadata';
