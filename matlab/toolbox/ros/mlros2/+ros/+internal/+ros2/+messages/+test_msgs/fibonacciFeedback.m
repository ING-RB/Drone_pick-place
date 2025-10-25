function [data, info] = fibonacciFeedback
%FibonacciFeedback gives an empty data for test_msgs/FibonacciFeedback

% Copyright 2019-2021 The MathWorks, Inc.
data = struct();
data.MessageType = 'test_msgs/FibonacciFeedback';
[data.sequence, info.sequence] = ros.internal.ros2.messages.ros2.default_type('int32',NaN,0);
info.MessageType = 'test_msgs/FibonacciFeedback';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,1);
info.MatPath{1} = 'sequence';
