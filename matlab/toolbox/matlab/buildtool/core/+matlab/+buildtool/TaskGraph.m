classdef (Hidden) TaskGraph < matlab.buildtool.internal.TaskGraphExtension
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % TaskGraph - Directed acyclic graph of tasks
    %
    %   The matlab.buildtool.TaskGraph class represents a directed acyclic
    %   graph of tasks where nodes are tasks and edges are dependencies.
    %
    %   Create a TaskGraph instance using the fromPlan static method.
    %
    %   TaskGraph properties:
    %      Tasks - Tasks of graph
    %
    %   TaskGraph methods:
    %      fromPlan - Create task graph from plan
    %      plot     - Plot task graph
    %
    %   Example:
    %
    %      % Load a plan from buildfile.m in your current folder.
    %      plan = matlab.buildtool.Plan.load;
    %
    %      % Create and plot a task graph from all the tasks in the plan.
    %      graph = matlab.buildtool.TaskGraph.fromPlan(plan);
    %      plot(graph)
    %
    %      % Create and plot a task graph that includes the "package" task and
    %      % its depended-on tasks.
    %      graph = matlab.buildtool.TaskGraph.fromPlan(plan,"package");
    %      plot(graph)
    %
    %   See also matlab.buildtool.Plan, matlab.buildtool.Task

    %   Copyright 2021-2023 The MathWorks, Inc.

    properties (SetAccess = private)
        % Tasks - Tasks of graph
        %
        %   Tasks of the graph in evaluation order, returned as a row vector of
        %   matlab.buildtool.Task objects.
        Tasks (1,:) matlab.buildtool.Task
    end

    properties (Hidden, SetAccess = private)
        % Edges - Edges of graph
        %
        %   Edges of the graph, returned as an N-by-2 string matrix where N is the
        %   number of edges in the graph. An edge flowing from a source to target
        %   indicates that the source has a dependency on the target.
        Edges (:,2) string
    end

    properties (Hidden, SetAccess = private)
        Strengths (:,1) matlab.buildtool.internal.EdgeStrength
    end

    properties (SetAccess = protected, GetAccess = ?matlab.buildtool.internal.TaskGraphExtension)
        Digraph
    end

    methods
        function tasks = get.Tasks(graph)
            tasks = graph.Digraph.Nodes.Task';
        end

        function edges = get.Edges(graph)
            edges = string(graph.Digraph.Edges.EndNodes);
        end

        function strengths = get.Strengths(graph)
            strengths = graph.Digraph.Edges.Strength;
        end
    end

    methods (Hidden)
        function sub = subgraph(graph, idx)
            arguments
                graph (1,1) matlab.buildtool.TaskGraph
                idx (1,:) {mustBeNumericOrLogical}
            end

            g = subgraph(graph.Digraph, idx);
            sub = matlab.buildtool.TaskGraph.fromDigraph(g);
        end
    end

    methods (Static)
        function graph = fromPlan(plan, taskName, options)
            % fromPlan - Create graph from plan
            %
            %   GRAPH = matlab.buildtool.TaskGraph.fromPlan(PLAN) creates a task graph
            %   that includes all the tasks defined in the specified plan. The graph
            %   cannot contain any cycles.
            %
            %   GRAPH = matlab.buildtool.TaskGraph.fromPlan(PLAN,TASKNAME) creates a
            %   task graph that includes the task named TASKNAME as well as all tasks
            %   on which the specified task depends. TASKNAME can be a string vector,
            %   character vector, or cell vector of character vectors.
            %
            %   Example:
            %
            %      % Load a plan from buildfile.m in your current folder.
            %      plan = matlab.buildtool.Plan.load;
            %
            %      % Create a task graph from all tasks in the plan.
            %      graph = matlab.buildtool.TaskGraph.fromPlan(plan);
            %
            %      % Create a task graph that includes the "package" task and its
            %      % depended-on tasks.
            %      graph = matlab.buildtool.TaskGraph.fromPlan(plan,"package");
            %
            %   See also matlab.buildtool.Plan, matlab.buildtool.Task

            arguments
                plan (1,1) matlab.buildtool.Plan
                taskName (1,:) string = [plan.Tasks.Name]
                options.Prune (1,:) string = string.empty()
            end

            import matlab.buildtool.Task;
            import matlab.buildtool.internal.EdgeStrength;

            currentFolder = pwd();
            restoreFolder = onCleanup(@()cd(currentFolder));
            cd(plan.RootFolder);

            names = string.empty();

            % Collect all tasks the task depends on
            queue = taskName;
            visiting = string.empty();

            while ~isempty(queue)
                name = queue(1);

                if ismember(name, names) || ismember(name, options.Prune) || startsWith(name, options.Prune+":")
                    % Already added task to list or task is pruned
                    queue(1) = [];
                    continue;
                end

                if ~ismember(name, visiting)
                    % Never visited, add all task dependencies to front of queue
                    visiting(end+1) = name; %#ok<AGROW>
                    deps = resolveDependencies(plan, name);
                    queue = union(deps, queue, "stable");
                else
                    % Already visited, add task to list
                    names(end+1) = name; %#ok<AGROW>
                    queue(1) = [];
                    visiting(visiting == name) = [];
                end
            end

            % Create source and target pairs from collected tasks
            sources = [];
            targets = [];
            strength = [];
            for i = 1:numel(names)
                [deps,epreds,ppreds] = resolveDependencies(plan, names(i));
                
                % Get target indices
                [~,idx] = ismember(unique([deps,epreds,ppreds]), names);

                % Remove targets where dependency not found
                idx(idx == 0) = [];

                sources = [sources, repmat(i,1,numel(idx))]; %#ok<AGROW>
                targets = [targets, idx]; %#ok<AGROW>

                for j = 1:numel(idx)
                    target = names(idx(j));

                    if ismember(target, deps)
                        s = EdgeStrength.Dependency;
                    elseif ismember(target, epreds)
                        s = EdgeStrength.StrictOrdering;
                    else
                        s = EdgeStrength.WeakOrdering;
                    end

                    strength = [strength; s]; %#ok<AGROW>
                end
            end

            graph = matlab.buildtool.TaskGraph(sources, targets, strength, plan(names));
        end
    end

    methods (Static, Access = private)
        function graph = fromDigraph(digraph)
            sources = digraph.Edges.EndNodes(:,1);
            targets = digraph.Edges.EndNodes(:,2);
            tasks = digraph.Nodes.Task;
            strength = digraph.Edges.Strength;
            graph = matlab.buildtool.TaskGraph(sources, targets, strength, tasks);
        end
    end

    methods (Access = protected)
        function graph = TaskGraph(sources, targets, strength, tasks)
            arguments
                sources
                targets
                strength
                tasks (1,:) matlab.buildtool.Task
            end

            nodes = table([tasks.Name string.empty(1,0)]', tasks', 'VariableName', ["Name","Task"]);
            edges = table(strength, 'VariableName', "Strength");

            dg = digraph(sources, targets, edges, nodes);
            dg = resolveCycles(dg);
            [~,sorted] = toposort(flipedge(dg), "Order", "stable");
            graph.Digraph = flipedge(sorted);
        end
    end
end

function [deps,epreds,ppreds] = resolveDependencies(plan, name)
task = plan(name);

deps = [task.Dependencies task.InferredDependencies];
epreds = [task.EssentialPredecessors allSubtasks(plan(task.EssentialPredecessors)).Name];
ppreds = [task.PreferredPredecessors allSubtasks(plan(task.PreferredPredecessors)).Name];

if isTaskGroup(task)
    deps = [deps task.Tasks.Name];
end

pn = parentName(name);
while pn ~= ""
    parent = plan(pn);

    [matching,nonmatching] = matchingTasks(plan, task, [parent.Dependencies parent.InferredDependencies]);
    if isempty(matching) || isempty(nonmatching)
        deps = [deps parent.Dependencies parent.InferredDependencies]; %#ok<AGROW>
    else
        deps = [deps matching.Name]; %#ok<AGROW>
    end

    [matching,nonmatching] = matchingTasks(plan, task, parent.EssentialPredecessors);
    if isempty(matching)
        epreds = [epreds nonmatching.Name]; %#ok<AGROW>
    else
        epreds = [epreds matching.Name]; %#ok<AGROW>
    end

    [matching,nonmatching] = matchingTasks(plan, task, parent.PreferredPredecessors);
    if isempty(matching)
        ppreds = [ppreds nonmatching.Name]; %#ok<AGROW>
    else
        ppreds = [ppreds matching.Name]; %#ok<AGROW>
    end

    pn = parentName(pn);
end
end

function [matching,nonmatching] = matchingTasks(plan, task, names)
tasks = [plan(names) allSubtasks(plan(names))];
tf = arrayfun(@(t)task.isMatch(t), tasks);
matching = tasks(tf);
nonmatching = tasks(~tf);
end

function subtasks = allSubtasks(tasks)
subtasks = matlab.buildtool.Task.empty(1,0);
for t = tasks(:)'
    subtasks = [subtasks matlab.buildtool.internal.allSubtasks(t)]; %#ok<AGROW>
end
end

function pn = parentName(n)
s = strsplit(n, ":");
pn = strjoin(s(1:end-1), ":");
end

function dg = resolveCycles(dg)
import matlab.buildtool.internal.EdgeStrength;
cycles = allcycles(dg);

for i = 1:length(cycles)
    cycle = [cycles{i}, cycles{i}(1)];
    isCycleResolved = false;

    for j = length(cycle):-1:2
        source = cycle{j-1};
        target = cycle{j};

        mask = ismember(string(dg.Edges.EndNodes), string({source target}), "rows");
        if ~any(mask) || dg.Edges.Strength(mask) == EdgeStrength.WeakOrdering
            dg = rmedge(dg, source, target);
            isCycleResolved = true;
            break;
        end
    end

    if ~isCycleResolved
        error(message("MATLAB:buildtool:TaskGraph:CircularDependency", strjoin(cycle, " -> ")));
    end
end
end

function tf = isTaskGroup(obj)
tf = isa(obj, "matlab.buildtool.TaskGroup");
end

% LocalWords:  subgraph buildfile TASKNAME
