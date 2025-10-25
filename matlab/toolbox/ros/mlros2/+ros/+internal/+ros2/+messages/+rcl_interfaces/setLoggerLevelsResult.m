function [data, info] = setLoggerLevelsResult
%SetLoggerLevelsResult gives an empty data for rcl_interfaces/SetLoggerLevelsResult

% Copyright 2019-2021 The MathWorks, Inc.
data = struct();
data.MessageType = 'rcl_interfaces/SetLoggerLevelsResult';
[data.successful, info.successful] = ros.internal.ros2.messages.ros2.default_type('logical',1,0);
[data.reason, info.reason] = ros.internal.ros2.messages.ros2.char('string',1,NaN,0);
info.MessageType = 'rcl_interfaces/SetLoggerLevelsResult';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,2);
info.MatPath{1} = 'successful';
info.MatPath{2} = 'reason';
