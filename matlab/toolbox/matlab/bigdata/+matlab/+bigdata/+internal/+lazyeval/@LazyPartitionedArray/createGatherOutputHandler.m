function handler = createGatherOutputHandler(taskToClosureMap)
% Get an output handler object that completes closure futures on receiving
% all of the output corresponding to each closure.

%   Copyright 2022 The MathWorks, Inc.

handleFcn = @(varargin) iHandleGatherOutput(varargin{:}, taskToClosureMap);
import matlab.bigdata.internal.executor.GatheringOutputHandler
handler = GatheringOutputHandler(handleFcn);
end


function cancel = iHandleGatherOutput(taskId, argoutIndex, data, taskToClosureMap)
% Handle all output intended to be gathered to the client. This maps
% returned results back to the relevant promises to be completed.
% At this point we have the entire array, assert that it is
% not an UnknownEmptyArray.
assert(~matlab.bigdata.internal.UnknownEmptyArray.isUnknown(data), ...
    'Assertion Failed: UnknownEmptyArray blocks are not allowed in the output array of gather.');
closure = taskToClosureMap(taskId);
closure.OutputPromises(argoutIndex).setValue(data);
cancel = false;
end
