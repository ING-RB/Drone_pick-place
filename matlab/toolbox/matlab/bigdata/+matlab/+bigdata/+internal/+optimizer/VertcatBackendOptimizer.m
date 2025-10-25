%VertcatBackendOptimizer
% Optimizer for back-end IR that removes all communication associated with
% tall vertical concatenation.
%
% This uses the back-end IR because this optimization requires to modify
% based on communication and partition strategy, both are better
% represented in the back-end IR.
%
% This optimization is also a bit greedy. If an intermediate partitioned
% array is used for both a vertical concatenation and a reduction, it will
% attempt to modify the reduction as well. This allows back-ends to fuse
% the reduction and vertical concatenation because partition strategies of
% the two will continue to align after optimization.
%
% This works by:
%  1. Find a PadWithEmptyPartitions operation in the graph.
%  2. Seek all operations connected to the inputs of PadWithEmptyPartitions
%     via non-communication edges. This is greedy, it will include other
%     calculations that are unrelated to the vertical concatenation.
%  3. Change all those operations to all be padded in the same way as the
%     output of the PadWithEmptyPartitions.
%  4. Repeat 1-3 until there are no more PadWithEmptyPartitions operations.

% Copyright 2018-2021 The MathWorks, Inc.

classdef VertcatBackendOptimizer < handle
    methods
        function taskGraph = optimize(obj, taskGraph)
            % Optimize the provided back-end graph object.
            if ~obj.enable()
                return;
            end
            while iHasPadOperation(taskGraph)
                taskGraph = iOptimizeOnePadOperation(taskGraph);
            end
        end
    end
    
    methods (Static)
        function out = enable(in)
            % Whether this optimization is enabled. If no, tall/vertcat
            % will revert to R2018b behavior.
            persistent state
            if isempty(state)
                state = true;
            end
            if nargout
                out = state;
            end
            if nargin
                state = in;
            end
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function tf = iHasPadOperation(taskGraph)
% Check whether the graph object has a PadWithEmptyPartitions operation.
import matlab.bigdata.internal.executor.OutputCommunicationType;
tf = any([taskGraph.Tasks.OutputCommunicationType] == OutputCommunicationType.PadWithEmptyPartitions);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function taskGraph = iOptimizeOnePadOperation(taskGraph)
% Optimize a single PadWithEmptyPartitions operation. This is done per
% operation as updates for the different PadWithEmptyPartitions operations
% will typically be independent of each other.

graphObj = taskGraph.asDigraph();

% First, figure out the set of tasks that are identical to the
% first PadWithEmptyPartitions in the list.
[startIdx, outputPartitionStrategy, outputSubIndex] = iFindFirstPadOperation(graphObj);
[requiresExecutionUpdate, requiresCommUpdate, requiresInputUpdate] = iFindTasksToUpdate(graphObj, startIdx);
requiresUpdate = requiresExecutionUpdate | requiresCommUpdate | requiresInputUpdate;

% Then update each individual task object according to the optimization.
tasks = graphObj.Nodes.Task;
idToTaskMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
for ii = 1:numel(tasks)
    task = tasks(ii);
    oldId = task.Id;
    if requiresUpdate(ii)
        task = iUpdateTaskObject(task, outputPartitionStrategy, outputSubIndex, idToTaskMap, ...
            requiresExecutionUpdate(ii), requiresCommUpdate(ii), requiresInputUpdate(ii));
    end
    tasks(ii) = task;
    idToTaskMap(oldId) = task;
end

% Finally inject the updated tasks back into the graphObj and cleanup
% redundant tasks. Redundant tasks can exist because the update so far is
% blind to whether a given operation's output is necessary to tasks not
% being updated. To be conservative, it leaves the old task in place to be
% cleaned up here.
graphObj = iReplaceTasks(graphObj, tasks(requiresUpdate), graphObj.Nodes.OutputIdx(requiresUpdate));
graphObj = iRemoveRedundentTasks(graphObj);
taskGraph = matlab.bigdata.internal.executor.SimpleTaskGraph(graphObj);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [idx, outputPartitionStrategy, outputSubIndex] = iFindFirstPadOperation(graphObj)
% Find the first PadWithEmptyPartitions operation in the graph and return
% an array of indices to all PadWithEmptyPartitions that match it.
import matlab.bigdata.internal.executor.OutputCommunicationType;

% First look for the first PadWithEmptyPartitions operation.
tasks = graphObj.Nodes.Task;
commType = [tasks.OutputCommunicationType]';
idx = find(commType == OutputCommunicationType.PadWithEmptyPartitions);
firstTask = tasks(idx(1));
assert(~firstTask.ExecutionPartitionStrategy.IsBroadcast, ...
    "Assertion Failed: Partition padding does not support broadcasts");
outputPartitionStrategy = firstTask.OutputPartitionStrategy;
outputSubIndex = firstTask.OutputSubIndex;

% Now  all other PadWithEmptyPartitions that do not match.
isSameAsFirst = false(size(idx));
isSameAsFirst(1) = true;
for ii = 2:numel(idx)
    task = tasks(idx(ii));
    isSameAsFirst(ii) = isequal(task.OutputPartitionStrategy, outputPartitionStrategy) ...
        && task.OutputSubIndex == outputSubIndex;
end
idx = idx(isSameAsFirst);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [requiresExecutionUpdate, requiresCommUpdate, requiresInputUpdate] ...
    = iFindTasksToUpdate(graphObj, startIdx)
% Find all tasks that need to be changed as part of the optimization. This
% returns three logicals per task:
%
% requiresExecutionUpdate: Does ExecutionPartitionStrategy need to be updated?
% requiresCommUpdate: Does OutputPartitionStrategy need to be updated?
% requiresInputUpdate: Do Input IDs need to be updated?
%
% This algorithm seeks to find all the information necessary for:
%  1. For each node, if the input is connected via non-communicating edges
%     to any input of one of startIdx, that node needs execution update.
%  2. For non-communicating operations, the output need to be updated
%     alongside execution.
%  3. Anything downstream of a node being changed needs to update it's
%     input IDs to respond.
%
% This expects graphObj to be in topological sorted order.
import matlab.bigdata.internal.executor.OutputCommunicationType;

tasks = graphObj.Nodes.Task;

% Certain tasks cannot be optimized (I.E. PadWithEmptyPartition that are
% not compatible with the one being optimized).
forbiddenIdxs = setdiff(...
    find([tasks.OutputCommunicationType] == OutputCommunicationType.PadWithEmptyPartitions), ...
    startIdx);

requiresExecutionUpdate = false(size(tasks));
requiresCommUpdate = false(size(tasks));
requiresInputUpdate = false(size(tasks));

% This uses a stack-based algorithm, it picks a task from the stack,
% analyzes it, then adds the predecessors or successors of that task as
% necessary back to the stack.
hasBeenSeenFromPredecessor = false(size(tasks));
hasBeenSeenFromSuccessors = false(size(tasks));
stackIdx = startIdx(:);
stackDir = -1 * ones(numel(startIdx), 1);
while ~isempty(stackIdx)
    % The task being analyzed
    taskIdx = stackIdx(end);
    % The direction from which task was hit in the search:
    %  -1 for input is connected via non-communicating edges to an output of startIdx
    %  1 for output is connected via non-communicating edges to an input of startIdx
    linkDir = stackDir(end);
    
    stackIdx(end) = [];
    stackDir(end) = [];
    % Ignore stack entries that have already been analyzed
    if linkDir < 0
        if hasBeenSeenFromPredecessor(taskIdx)
            continue;
        end
        hasBeenSeenFromPredecessor(taskIdx) = true;
    else
        if hasBeenSeenFromSuccessors(taskIdx)
            continue;
        end
        hasBeenSeenFromSuccessors(taskIdx) = true;
    end
    
    task = tasks(taskIdx);
    % Output of broadcasts do not need to be updated. They do not care
    % about the partition of where they will be used.
    if linkDir > 0 && task.OutputPartitionStrategy.IsBroadcast
        continue;
    end
    % Ignore PadWithEmptyPartitions that are not compatible with the
    % PadWithEmptyPartitions being optimized.
    if ismember(taskIdx, forbiddenIdxs)
        continue;
    end
    
    % This task is being updated, better mark it's successors as needing ID
    % update.
    s = successors(graphObj, taskIdx);
    requiresInputUpdate(s) = true;
    
    isNonCommunicating = task.OutputCommunicationType == OutputCommunicationType.Simple;
    % If the input of this task is connected via non-communicating edges to
    % an input of startIdx, then execution partition strategy needs updating.
    % Also add other predecessors to the list of tasks needing update as all
    % inputs to a task must have the same partitioning.
    if linkDir < 0 || isNonCommunicating
        requiresExecutionUpdate(taskIdx) = true;
        p = predecessors(graphObj, taskIdx);
        stackIdx = [stackIdx; p]; %#ok<AGROW>
        stackDir = [stackDir; 1 * ones(size(p))]; %#ok<AGROW>
    end
    % If the output of this task is connected via non-communicating edges to
    % an input of startIdx, then output partition strategy needs updating.
    % Also add other successors to the list of tasks needing update because
    % of the reasons to be greedy explained above.
    if linkDir > 0 || isNonCommunicating
        requiresCommUpdate(taskIdx) = ~isNonCommunicating;
        stackIdx = [stackIdx; s]; %#ok<AGROW>
        stackDir = [stackDir; -1 * ones(size(s))]; %#ok<AGROW>
    end
end
requiresInputUpdate(forbiddenIdxs) = false;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function task = iUpdateTaskObject(task, newPartitionStrategy, subIndex, idToTaskMap, ...
    requiresExecutionUpdate,  requiresCommUpdate, requiresInputUpdate)
% Update the given task object to be in terms of the new partition strategy.
import matlab.bigdata.internal.executor.OutputCommunicationType;
import matlab.bigdata.internal.optimizer.PadCommOutputProcessorFactory;
import matlab.bigdata.internal.optimizer.PadExecutionProcessorFactory;

% If the output of communication is needed in the new partition
% strategy, we wrap the communication itself to output to the new
% partition strategy.
if requiresCommUpdate
    wasAnyToAny = task.OutputCommunicationType == OutputCommunicationType.AnyToAny;
    newCommType = OutputCommunicationType.AnyToAny;
    processorFactory = task.DataProcessorFactory;
    processorFactory = PadCommOutputProcessorFactory(processorFactory, wasAnyToAny, subIndex);
    task = copyWithReplacedCommunication(task, newCommType, newPartitionStrategy, processorFactory);
end

% If the execution needs to be updated into the new partition strategy,
% we do that here.
if requiresExecutionUpdate
    processorFactory = task.DataProcessorFactory;
    processorFactory = PadExecutionProcessorFactory(processorFactory, ...
        subIndex, numel(task.InputIds), task.NumOutputs);
    task = copyWithReplacedExecutionStrategy(task, newPartitionStrategy, processorFactory);
    % With the update to execution, PadWithEmptyPartitions can be
    % converted to non-communicating tasks.
    if task.OutputCommunicationType == OutputCommunicationType.PadWithEmptyPartitions
        newCommType = OutputCommunicationType.Simple;
        task = copyWithReplacedCommunication(task, newCommType, newPartitionStrategy, processorFactory);
    end
end

% We give this thing a new ID in-case there are downstream operations
% that are intentionally not updated but still depend on the original
% output of this task. This will be hit when there are multiple
% vertical concatenations on the same inputs, e.g. gather([X;Y], [Y;X])
if requiresExecutionUpdate || requiresCommUpdate
    task = copyWithNewId(task);
end

% Finally, anything that is downstream of a task that has been modified
% needs to be given the new IDs.
if requiresInputUpdate
    inputs = cellstr(task.InputIds);
    for jj = 1:numel(inputs)
        inputs{jj} = idToTaskMap(inputs{jj});
    end
    inputs = vertcat(inputs{:});
    task = copyWithReplacedInputs(task, inputs);
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function graphObj = iReplaceTasks(graphObj, newTasks, newOutputIdx)
% Replace tasks in the old graph with the new task objects of same ID. If
% a new task exists with an ID not in graphObj, it will be just be added.
nodes = graphObj.Nodes;
edges = graphObj.Edges;

% Force any  final outputs to be in terms of the replaced nodes.
nodes.OutputIdx(ismember(nodes.OutputIdx, newOutputIdx)) = 0;

newNodes = matlab.bigdata.internal.executor.TaskGraph.buildNodeTable(newTasks, newOutputIdx);
newEdges = matlab.bigdata.internal.executor.TaskGraph.buildEdgeTable(newTasks);

isNodeOverlap = ismember(nodes.Name, newNodes.Name);
isEdgeOverlap = ismember(edges.EndNodes(:, 2), nodes.Name(isNodeOverlap));

nodes(isNodeOverlap, :) = [];
nodes = [nodes; newNodes];

edges(isEdgeOverlap, :) = [];
edges = [edges; newEdges];

graphObj = digraph(edges, nodes);
graphObj = reordernodes(graphObj, toposort(graphObj));
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function graphObj = iRemoveRedundentTasks(graphObj)
% Remove tasks from the graph that are not predecessors of any final
% output.
isStillValid = graphObj.Nodes.OutputIdx ~= 0;
for ii = numnodes(graphObj):-1:1
    if isStillValid(ii)
        p = predecessors(graphObj, ii);
        isStillValid(p) = true;
    end
end
graphObj = rmnode(graphObj, find(~isStillValid));
end
