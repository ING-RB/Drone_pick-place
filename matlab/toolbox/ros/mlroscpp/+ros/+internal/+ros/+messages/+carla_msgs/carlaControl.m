function [data, info] = carlaControl
%CarlaControl gives an empty data for carla_msgs/CarlaControl

% Copyright 2019-2020 The MathWorks, Inc.
%#codegen
data = struct();
data.MessageType = 'carla_msgs/CarlaControl';
[data.PLAY, info.PLAY] = ros.internal.ros.messages.ros.default_type('int8',1, 0);
[data.PAUSE, info.PAUSE] = ros.internal.ros.messages.ros.default_type('int8',1, 1);
[data.STEPONCE, info.STEPONCE] = ros.internal.ros.messages.ros.default_type('int8',1, 2);
[data.Command, info.Command] = ros.internal.ros.messages.ros.default_type('int8',1);
info.MessageType = 'carla_msgs/CarlaControl';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,4);
info.MatPath{1} = 'PLAY';
info.MatPath{2} = 'PAUSE';
info.MatPath{3} = 'STEP_ONCE';
info.MatPath{4} = 'command';
