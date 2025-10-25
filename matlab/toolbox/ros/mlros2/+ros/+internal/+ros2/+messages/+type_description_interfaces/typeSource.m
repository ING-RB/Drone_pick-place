function [data, info] = typeSource
%TypeSource gives an empty data for type_description_interfaces/TypeSource

% Copyright 2019-2021 The MathWorks, Inc.
data = struct();
data.MessageType = 'type_description_interfaces/TypeSource';
[data.type_name, info.type_name] = ros.internal.ros2.messages.ros2.char('string',1,NaN,0);
[data.encoding, info.encoding] = ros.internal.ros2.messages.ros2.char('string',1,NaN,0);
[data.raw_file_contents, info.raw_file_contents] = ros.internal.ros2.messages.ros2.char('string',1,NaN,0);
info.MessageType = 'type_description_interfaces/TypeSource';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,3);
info.MatPath{1} = 'type_name';
info.MatPath{2} = 'encoding';
info.MatPath{3} = 'raw_file_contents';
