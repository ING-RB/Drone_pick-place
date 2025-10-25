function [data, info] = packetMsg
%PacketMsg gives an empty data for ouster_ros/PacketMsg

% Copyright 2019-2020 The MathWorks, Inc.
data = struct();
data.MessageType = 'ouster_ros/PacketMsg';
[data.Buf, info.Buf] = ros.internal.ros.messages.ros.default_type('uint8',NaN);
info.MessageType = 'ouster_ros/PacketMsg';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,1);
info.MatPath{1} = 'buf';
