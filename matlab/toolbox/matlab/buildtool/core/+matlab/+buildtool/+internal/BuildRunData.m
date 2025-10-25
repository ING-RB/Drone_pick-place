classdef BuildRunData < handle
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % Copyright 2021-2024 The MathWorks, Inc.

    properties (SetAccess = private)
        Plan (1,1) matlab.buildtool.Plan = buildplan()
        TaskGraph matlab.buildtool.TaskGraph {mustBeScalarOrEmpty}
        TaskResults (1,:) matlab.buildtool.TaskResult
        TaskArguments (1,1) dictionary
        Skip (1,:) string
        ContinueOnFailure (1,1) logical
        Parallel (1,1) logical
        CacheFolder (1,1) string
        Verbosity matlab.automation.Verbosity {mustBeScalarOrEmpty}
    end

    properties (Dependent)
        CurrentTask matlab.buildtool.Task {mustBeScalarOrEmpty}
        CurrentResult matlab.buildtool.TaskResult {mustBeScalarOrEmpty}
        CurrentTaskArguments cell
    end

    properties (SetAccess = private)
        CurrentIndex {mustBeInteger} = 0
    end

    methods (Static)
        function data = fromPlan(plan, taskName, taskArguments, options)
            arguments
                plan (1,1) matlab.buildtool.Plan
                taskName (1,:) string = [plan.Tasks.Name]
                taskArguments (1,1) dictionary = dictionary(string.empty(), cell.empty())
                options (1,1) struct = struct(...
                    "Prune", string.empty(), ...
                    "Skip", string.empty(), ...
                    "ContinueOnFailure", false, ...
                    "Parallel", false, ...
                    "CacheFolder", matlab.buildtool.internal.cacheRoot(plan.RootFolder), ...
                    "Verbosity", matlab.automation.Verbosity.empty())
            end

            graph = matlab.buildtool.TaskGraph.fromPlan(plan, taskName, Prune=options.Prune);
            options = rmfield(options, "Prune");

            results = createInitialTaskResults(graph);

            args = namedargs2cell(options);
            data = matlab.buildtool.internal.BuildRunData(plan, graph, results, taskArguments, args{:});
        end
    end

    methods
        function tf = hasTasksRemaining(data)
            tf = data.CurrentIndex < numel(data.TaskGraph.Tasks);
        end

        function task = selectNextTask(data)
            data.CurrentIndex = data.CurrentIndex + 1;
            task = data.CurrentTask;
        end

        function addDurationToCurrentResult(data, dur)
            arguments
                data
                dur (1,1) duration
            end
            data.CurrentResult.Duration = data.CurrentResult.Duration + dur;
        end

        function task = get.CurrentTask(data)
            task = data.TaskGraph.Tasks(data.CurrentIndex);
        end

        function taskArgs = get.CurrentTaskArguments(data)
            taskArgs = {};

            name = data.CurrentTask.Name;
            while name ~= ""
                if data.TaskArguments.isKey(name)
                    taskArgs = data.TaskArguments{name};
                    break;
                end
                name = parentName(name);
            end
        end

        function result = get.CurrentResult(data)
            result = data.TaskResults(data.CurrentIndex);
        end

        function set.CurrentResult(data, result)
            data.TaskResults(data.CurrentIndex) = result;
        end
    end

    methods (Access = protected)
        function data = BuildRunData(plan, graph, results, taskArguments, options)
            arguments
                plan (1,1) matlab.buildtool.Plan
                graph matlab.buildtool.TaskGraph {mustBeScalarOrEmpty}
                results (1,:) matlab.buildtool.TaskResult
                taskArguments (1,1) dictionary = dictionary(string.empty(), cell.empty())
                options.Skip (1,:) string = string.empty(1,0)
                options.ContinueOnFailure (1,1) logical = false
                options.Parallel (1,1) logical = false
                options.CacheFolder {mustBeNonzeroLengthTextScalar} = matlab.buildtool.internal.cacheRoot(plan.RootFolder)
                options.Verbosity matlab.automation.Verbosity {mustBeScalarOrEmpty} = matlab.automation.Verbosity.empty()
            end

            data.Plan = plan;
            data.TaskGraph = graph;
            data.TaskResults = results;
            data.TaskArguments = taskArguments;

            for prop = string(fieldnames(options))'
                data.(prop) = options.(prop);
            end
        end
    end
end

function results = createInitialTaskResults(graph)
import matlab.buildtool.TaskResult;

results = TaskResult.empty();
numElements = numel(graph.Tasks);
if numElements > 0
    results(numElements) = TaskResult();
end

for i = 1:numElements
    t = graph.Tasks(i);
    results(i).Name = t.Name;
end
end

function pn = parentName(n)
s = strsplit(n, ":");
pn = strjoin(s(1:end-1), ":");
end

function mustBeNonzeroLengthTextScalar(x)
mustBeTextScalar(x);
mustBeNonzeroLengthText(x);
end
