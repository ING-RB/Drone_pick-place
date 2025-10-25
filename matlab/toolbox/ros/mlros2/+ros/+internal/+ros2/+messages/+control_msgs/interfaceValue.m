function [data, info] = interfaceValue
%InterfaceValue gives an empty data for control_msgs/InterfaceValue

% Copyright 2019-2021 The MathWorks, Inc.
data = struct();
data.MessageType = 'control_msgs/InterfaceValue';
[data.interface_names, info.interface_names] = ros.internal.ros2.messages.ros2.char('string',NaN,NaN,0);
[data.values, info.values] = ros.internal.ros2.messages.ros2.default_type('double',NaN,0);
info.MessageType = 'control_msgs/InterfaceValue';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,2);
info.MatPath{1} = 'interface_names';
info.MatPath{2} = 'values';
