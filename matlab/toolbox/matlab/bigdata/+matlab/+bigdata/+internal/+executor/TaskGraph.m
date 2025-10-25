%TaskGraph
% A graph of ExecutionTask instances that represent one complete execution.
%

%   Copyright 2015-2022 The MathWorks, Inc.

classdef (Abstract) TaskGraph < handle
    properties (Abstract, SetAccess = private)
        % An array of all tasks in the graph sorted in topological order
        % such that tasks only depend on tasks that came before them in the
        % array.
        Tasks
        
        % An ordered list of tasks for which the output is required to be
        % gathered to the client.
        OutputTasks
    end

    properties (Dependent)
        % A vector of all CacheEntryKey objects from the closure graph.
        CacheEntryKeys
    end
    
    methods
        function keys = get.CacheEntryKeys(obj)
            import matlab.bigdata.internal.executor.CacheEntryKey;
            isCachable = {obj.Tasks.CacheLevel}' ~= "None";
            keys = [CacheEntryKey.empty(); obj.Tasks(isCachable).CacheEntryKey];
            keys = keys([keys.IsValid]);
        end
        
        function graphObj = asDigraph(obj)
            % Build a digraph object that represents the same information.
            [~, outputTaskIdx] = ismember(obj.Tasks, obj.OutputTasks);
            nodes = obj.buildNodeTable(obj.Tasks, outputTaskIdx);
            edges = obj.buildEdgeTable(obj.Tasks);
            graphObj = digraph(edges, nodes);
        end
    end
    
    methods (Static)
        function nodeTable = buildNodeTable(tasks, outputTaskIdx)
            % Build the node table for a digraph representation of this
            % object. This is exposed publicly to allow optimizers to
            % build the node table representation to merge into an existing
            % digraph.
            nodeTable = table(string({tasks.Id})', tasks, outputTaskIdx, ...
                'VariableNames', ["Name", "Task", "OutputIdx"]);
        end
        
        function edgeTable = buildEdgeTable(tasks)
            % Build the edge table for a digraph representation of this
            % object. This is exposed publicly to allow optimizers to
            % build the edge table representation to merge into an existing
            % digraph.
            edges = string.empty(0, 2);
            for ii = 1:numel(tasks)
                task = tasks(ii);
                ids = string(task.InputIds(:));
                ids(:, 2) = task.Id;
                edges = [edges; ids]; %#ok<AGROW>
            end
            edgeTable = table(edges, 'VariableNames', "EndNodes");
        end
    end
end
