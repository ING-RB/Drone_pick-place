function [data, info] = multiDOFCommand
%MultiDOFCommand gives an empty data for control_msgs/MultiDOFCommand

% Copyright 2019-2021 The MathWorks, Inc.
data = struct();
data.MessageType = 'control_msgs/MultiDOFCommand';
[data.dof_names, info.dof_names] = ros.internal.ros2.messages.ros2.char('string',NaN,NaN,0);
[data.values, info.values] = ros.internal.ros2.messages.ros2.default_type('double',NaN,0);
[data.values_dot, info.values_dot] = ros.internal.ros2.messages.ros2.default_type('double',NaN,0);
info.MessageType = 'control_msgs/MultiDOFCommand';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,3);
info.MatPath{1} = 'dof_names';
info.MatPath{2} = 'values';
info.MatPath{3} = 'values_dot';
