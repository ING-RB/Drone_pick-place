function [data, info] = loggerLevel
%LoggerLevel gives an empty data for rcl_interfaces/LoggerLevel

% Copyright 2019-2021 The MathWorks, Inc.
data = struct();
data.MessageType = 'rcl_interfaces/LoggerLevel';
[data.LOG_LEVEL_UNKNOWN, info.LOG_LEVEL_UNKNOWN] = ros.internal.ros2.messages.ros2.default_type('uint8',1,0, 0, [NaN]);
[data.LOG_LEVEL_DEBUG, info.LOG_LEVEL_DEBUG] = ros.internal.ros2.messages.ros2.default_type('uint8',1,0, 10, [NaN]);
[data.LOG_LEVEL_INFO, info.LOG_LEVEL_INFO] = ros.internal.ros2.messages.ros2.default_type('uint8',1,0, 20, [NaN]);
[data.LOG_LEVEL_WARN, info.LOG_LEVEL_WARN] = ros.internal.ros2.messages.ros2.default_type('uint8',1,0, 30, [NaN]);
[data.LOG_LEVEL_ERROR, info.LOG_LEVEL_ERROR] = ros.internal.ros2.messages.ros2.default_type('uint8',1,0, 40, [NaN]);
[data.LOG_LEVEL_FATAL, info.LOG_LEVEL_FATAL] = ros.internal.ros2.messages.ros2.default_type('uint8',1,0, 50, [NaN]);
[data.name, info.name] = ros.internal.ros2.messages.ros2.char('string',1,NaN,0);
[data.level, info.level] = ros.internal.ros2.messages.ros2.default_type('uint32',1,0);
info.MessageType = 'rcl_interfaces/LoggerLevel';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,8);
info.MatPath{1} = 'LOG_LEVEL_UNKNOWN';
info.MatPath{2} = 'LOG_LEVEL_DEBUG';
info.MatPath{3} = 'LOG_LEVEL_INFO';
info.MatPath{4} = 'LOG_LEVEL_WARN';
info.MatPath{5} = 'LOG_LEVEL_ERROR';
info.MatPath{6} = 'LOG_LEVEL_FATAL';
info.MatPath{7} = 'name';
info.MatPath{8} = 'level';
