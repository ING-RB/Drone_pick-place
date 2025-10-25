function [data, info] = getLoggerLevelsResponse
%GetLoggerLevels gives an empty data for rcl_interfaces/GetLoggerLevelsResponse

% Copyright 2019-2021 The MathWorks, Inc.
data = struct();
data.MessageType = 'rcl_interfaces/GetLoggerLevelsResponse';
[data.levels, info.levels] = ros.internal.ros2.messages.rcl_interfaces.loggerLevel;
info.levels.MLdataType = 'struct';
info.levels.MaxLen = NaN;
info.levels.MinLen = 0;
info.MessageType = 'rcl_interfaces/GetLoggerLevelsResponse';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,9);
info.MatPath{1} = 'levels';
info.MatPath{2} = 'levels.LOG_LEVEL_UNKNOWN';
info.MatPath{3} = 'levels.LOG_LEVEL_DEBUG';
info.MatPath{4} = 'levels.LOG_LEVEL_INFO';
info.MatPath{5} = 'levels.LOG_LEVEL_WARN';
info.MatPath{6} = 'levels.LOG_LEVEL_ERROR';
info.MatPath{7} = 'levels.LOG_LEVEL_FATAL';
info.MatPath{8} = 'levels.name';
info.MatPath{9} = 'levels.level';
