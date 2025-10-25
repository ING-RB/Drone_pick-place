function [data, info] = pointHeadFeedback
%PointHeadFeedback gives an empty data for control_msgs/PointHeadFeedback

% Copyright 2019-2021 The MathWorks, Inc.
data = struct();
data.MessageType = 'control_msgs/PointHeadFeedback';
[data.pointing_angle_error, info.pointing_angle_error] = ros.internal.ros2.messages.ros2.default_type('double',1,0);
info.MessageType = 'control_msgs/PointHeadFeedback';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,1);
info.MatPath{1} = 'pointing_angle_error';
