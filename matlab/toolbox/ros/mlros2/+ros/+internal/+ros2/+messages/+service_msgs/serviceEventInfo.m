function [data, info] = serviceEventInfo
%ServiceEventInfo gives an empty data for service_msgs/ServiceEventInfo

% Copyright 2019-2021 The MathWorks, Inc.
data = struct();
data.MessageType = 'service_msgs/ServiceEventInfo';
[data.REQUEST_SENT, info.REQUEST_SENT] = ros.internal.ros2.messages.ros2.default_type('uint8',1,0, 0, [NaN]);
[data.REQUEST_RECEIVED, info.REQUEST_RECEIVED] = ros.internal.ros2.messages.ros2.default_type('uint8',1,0, 1, [NaN]);
[data.RESPONSE_SENT, info.RESPONSE_SENT] = ros.internal.ros2.messages.ros2.default_type('uint8',1,0, 2, [NaN]);
[data.RESPONSE_RECEIVED, info.RESPONSE_RECEIVED] = ros.internal.ros2.messages.ros2.default_type('uint8',1,0, 3, [NaN]);
[data.event_type, info.event_type] = ros.internal.ros2.messages.ros2.default_type('uint8',1,0);
[data.stamp, info.stamp] = ros.internal.ros2.messages.builtin_interfaces.time;
info.stamp.MLdataType = 'struct';
[data.client_gid, info.client_gid] = ros.internal.ros2.messages.ros2.char('char',16,NaN,0);
[data.sequence_number, info.sequence_number] = ros.internal.ros2.messages.ros2.default_type('int64',1,0);
info.MessageType = 'service_msgs/ServiceEventInfo';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,10);
info.MatPath{1} = 'REQUEST_SENT';
info.MatPath{2} = 'REQUEST_RECEIVED';
info.MatPath{3} = 'RESPONSE_SENT';
info.MatPath{4} = 'RESPONSE_RECEIVED';
info.MatPath{5} = 'event_type';
info.MatPath{6} = 'stamp';
info.MatPath{7} = 'stamp.sec';
info.MatPath{8} = 'stamp.nanosec';
info.MatPath{9} = 'client_gid';
info.MatPath{10} = 'sequence_number';
