function [taskGraph, taskToClosureMap, closureToTaskMap, executor, optimUndoGuard] = getEvaluationObjects(varargin)
% Convert the PartitionedArray into the necessary task graph object
% and executor object.

%   Copyright 2022-2024 The MathWorks, Inc.

import matlab.bigdata.internal.executor.PartitionedArrayExecutor;
import matlab.bigdata.internal.lazyeval.Closure;
import matlab.bigdata.internal.lazyeval.LazyTaskGraph;
import matlab.bigdata.internal.serial.SerialExecutor;
import matlab.bigdata.internal.util.isPreviewCheap;

% Before gathering, call the optimizer.
op = matlab.bigdata.internal.Optimizer.default();
optimUndoGuard = op.optimize(varargin{:});

closures = cell(size(varargin));
executor = PartitionedArrayExecutor.getOverride();
for ii = 1:numel(varargin)
    if ~varargin{ii}.ValueFuture.IsDone
        closures{ii} = varargin{ii}.ValueFuture.Closure;
        if isempty(executor)
            executor = getExecutor(varargin{ii});
        end
    end
end
closures = vertcat(closures{:}, Closure.empty());

if ~isempty(executor) && executor.supportsSinglePartition()
    isGatherCheap = true(size(varargin));
    ii=1;
    while all(isGatherCheap) && ii<=numel(varargin)
        [~, isGatherCheap(ii)] = isPreviewCheap(varargin{ii});
        ii = ii + 1;
    end
    if all(isGatherCheap)
        executor = SerialExecutor('UseSinglePartition', true);
    end
end

if isempty(closures)
    taskGraph = [];
    taskToClosureMap = [];
    closureToTaskMap = [];
else
    taskGraph = LazyTaskGraph(closures);
    taskToClosureMap = taskGraph.TaskToClosureMap;
    closureToTaskMap = containers.Map(KeyType="char", ValueType="any");
    existingOutputIds = {taskGraph.OutputTasks.Id};

    % We apply this back-end optimization here because it is
    % common to all back-ends.
    backEndOp = matlab.bigdata.internal.optimizer.VertcatBackendOptimizer;
    taskGraph = backEndOp.optimize(taskGraph);
    for ii = 1:numel(existingOutputIds)
        closure = taskToClosureMap(existingOutputIds{ii});
        taskToClosureMap(taskGraph.OutputTasks(ii).Id) = closure;
        closureToTaskMap(closure.Id) = taskGraph.OutputTasks(ii);
    end
end
end

