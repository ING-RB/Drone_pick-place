%SimpleTaskGraph
% A graph of ExecutionTask instances that represent one complete execution.
% This has no awareness of how the task graph was generated.

%   Copyright 2016-2018 The MathWorks, Inc.

classdef SimpleTaskGraph < matlab.bigdata.internal.executor.TaskGraph
    properties (SetAccess = private)
        % An array of all tasks in the graph sorted in topological order
        % such that tasks only depend on tasks that came before them in the
        % array.
        Tasks
        
        % An ordered list of tasks for which the output is required to be
        % gathered to the client.
        OutputTasks
    end
    
    methods
        function obj = SimpleTaskGraph(tasks, outputTasks)
            % Build a TaskGraph object containing just tasks and
            % outputTasks. This can either accept the list of tasks and
            % output tasks itself, or a digraph from TaskGraph.asDigraph.
             
            if nargin == 1
                [~, outputIdx] = ismember(1:max(tasks.Nodes.OutputIdx), tasks.Nodes.OutputIdx);
                tasks = tasks.Nodes.Task;
                outputTasks = tasks(outputIdx);
            end
            
            obj.Tasks = tasks;
            obj.OutputTasks = outputTasks;
        end
    end
end
