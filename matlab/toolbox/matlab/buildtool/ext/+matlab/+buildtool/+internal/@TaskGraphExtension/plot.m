function plot(graph, options)
% PLOT - Plot task graph
%
%   PLOT(GRAPH) plots the specified task graph. The function labels each
%   task by its name and displays all the dependencies.
%
%   Example:
%
%      % Load a plan from buildfile.m in your current folder.
%      plan = matlab.buildtool.Plan.load;
%
%      % Create a task graph from all the tasks in the plan.
%      graph = matlab.buildtool.TaskGraph.fromPlan(plan);
%
%      % Plot the task graph.
%      plot(graph)
%
%   See also matlab.buildtool.Plan, matlab.buildtool.TaskGraph

%   Copyright 2021-2024 The MathWorks, Inc.

arguments
    graph (1,1) matlab.buildtool.TaskGraph
    options.ShowAllTasks (1,1) logical = false
    options.ShowPredecessors (1,1) logical = false
end

import matlab.buildtool.internal.plotDigraph;
import matlab.buildtool.internal.EdgeStrength;

dg = graph.Digraph;

if ~options.ShowAllTasks
    names = dg.Nodes.Name;
    edges = dg.Edges.EndNodes;
    strengths = [dg.Edges.Strength EdgeStrength.empty(0,1)];

    names = strtok(names, ":");
    edges = strtok(edges, ":");

    nodeTable = table(unique(names), 'VariableNames', "Name");
    edgeTable = table(edges, strengths, 'VariableNames', ["EndNodes","Strength"]);
    
    dg = digraph(edgeTable, nodeTable);
    dg = simplify(dg, "max", PickVariable="Strength");
end

if ~options.ShowPredecessors
    dg = rmedge(dg, find(dg.Edges.Strength < EdgeStrength.Dependency));
end

style = repmat("-", size(dg.Edges.Strength));
style(dg.Edges.Strength == EdgeStrength.StrictOrdering) = "--";
style(dg.Edges.Strength == EdgeStrength.WeakOrdering) = ":";

plotDigraph(dg, Interpreter="none", LineStyle=style);
end

% LocalWords:  buildfile
