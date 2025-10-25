function obj = createInvalidVersionArray(verStr)
% Create a LazyPartitionedArray that represents an invalid array backed by
% an invalid executor.

%   Copyright 2022 The MathWorks, Inc.
import matlab.bigdata.internal.executor.PartitionedArrayExecutorReference
import matlab.bigdata.internal.lazyeval.LazyPartitionedArray
import matlab.bigdata.internal.serial.SerialExecutor

% When the version information does not match, we simply
% load the array as an invalid tall.
serialExecutor = SerialExecutor();
invalidExecutor = PartitionedArrayExecutorReference(serialExecutor);
obj = LazyPartitionedArray.createFromConstant(verStr, invalidExecutor);
% We use partitionfun here because that will not be
% evaluated immediately.
obj = partitionfun(@(~,~) iIssueInvalidVersionError(verStr), obj);
delete(serialExecutor);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Helper function to lazily throw the version error. This is likely not
% reachable such a tall array is initialized with an invalid executor.
function varargout = iIssueInvalidVersionError(ver) %#ok<STOUT>
error(message('MATLAB:bigdata:array:InvalidTallVersion', ver));
end
