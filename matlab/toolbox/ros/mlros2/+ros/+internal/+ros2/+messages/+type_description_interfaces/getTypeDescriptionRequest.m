function [data, info] = getTypeDescriptionRequest
%GetTypeDescription gives an empty data for type_description_interfaces/GetTypeDescriptionRequest

% Copyright 2019-2021 The MathWorks, Inc.
data = struct();
data.MessageType = 'type_description_interfaces/GetTypeDescriptionRequest';
[data.type_name, info.type_name] = ros.internal.ros2.messages.ros2.char('string',1,NaN,0);
[data.type_hash, info.type_hash] = ros.internal.ros2.messages.ros2.char('string',1,NaN,0);
[data.include_type_sources, info.include_type_sources] = ros.internal.ros2.messages.ros2.default_type('logical',1,0, NaN, [1]);
info.MessageType = 'type_description_interfaces/GetTypeDescriptionRequest';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,3);
info.MatPath{1} = 'type_name';
info.MatPath{2} = 'type_hash';
info.MatPath{3} = 'include_type_sources';
