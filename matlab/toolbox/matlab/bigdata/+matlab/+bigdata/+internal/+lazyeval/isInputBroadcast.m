function tfArray = isInputBroadcast(taskDependencies, inputFutureMap)
% Helper for createExecutionTasks that returns an array of
% logicals, each true if and only if the corresponding
% operation input is a broadcast.
%
% Note, this requires both the input task dependencies and the
% map from dependencies to actual operation inputs (inputFutureMap).

%	Copyright 2022 The MathWorks, Inc.

tfArray = arrayfun(@(d) d.OutputPartitionStrategy.IsBroadcast, taskDependencies);
tfArray = inputFutureMap.mapScalars(tfArray);
end