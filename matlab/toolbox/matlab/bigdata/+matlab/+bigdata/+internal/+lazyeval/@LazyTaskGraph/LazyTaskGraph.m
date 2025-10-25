%LazyTaskGraph
% Class that represents a graph of ExecutionTask that is equivalent to the
% graph of closures that is required to be executed.
%
% General model for tasks:
%
% Each closure will have one or more execution tasks that represents it.
%
% Every task in this graph will emit a N x NumOutputs cell array.
% * Each column corresponds with exactly one output of the operation.
% * Each cell contains one chunk of data of that output.
% Tasks are expected to extract out the correct columns from upstream tasks.
% * The input to a task will be one N x NumOutputs cell array from each
%   upstream task.
% * The task is responsible for extracting out the data that corresponds to
%   the input futures that the corresponding operation requires.
%
% Constructor:
%  obj = LazyTaskGraph(closures) constructs a LazyTaskGraph from zero or
%  more closure objects.
%
% Properties:
%  Tasks:
%   A list of all ExecutionTask objects for the graph.
%
%  OutputTasks:
%   The subset of Tasks that generates output to be gathered to the client.
%
%  ClosureToTaskMap:
%   A map of Closure ID to the corresponding ExecutionTask instance.
%
%  ClosureToTaskMap:
%    A map of Task ID to the corresponding Closure instance.

%   Copyright 2015-2023 The MathWorks, Inc.
