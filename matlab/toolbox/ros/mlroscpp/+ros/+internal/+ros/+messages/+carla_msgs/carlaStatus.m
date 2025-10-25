function [data, info] = carlaStatus
%CarlaStatus gives an empty data for carla_msgs/CarlaStatus

% Copyright 2019-2020 The MathWorks, Inc.
%#codegen
data = struct();
data.MessageType = 'carla_msgs/CarlaStatus';
[data.Frame, info.Frame] = ros.internal.ros.messages.ros.default_type('uint64',1);
[data.FixedDeltaSeconds, info.FixedDeltaSeconds] = ros.internal.ros.messages.ros.default_type('single',1);
[data.SynchronousMode, info.SynchronousMode] = ros.internal.ros.messages.ros.default_type('logical',1);
[data.SynchronousModeRunning, info.SynchronousModeRunning] = ros.internal.ros.messages.ros.default_type('logical',1);
info.MessageType = 'carla_msgs/CarlaStatus';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,4);
info.MatPath{1} = 'frame';
info.MatPath{2} = 'fixed_delta_seconds';
info.MatPath{3} = 'synchronous_mode';
info.MatPath{4} = 'synchronous_mode_running';
