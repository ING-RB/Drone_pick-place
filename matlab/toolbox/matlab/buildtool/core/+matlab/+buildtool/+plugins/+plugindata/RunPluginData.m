classdef (Hidden) RunPluginData < matlab.buildtool.plugins.plugindata.PluginData
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % RunPluginData - Plugin data describing task graph being run
    %
    %   The matlab.buildtool.plugins.plugindata.RunPluginData class defines the
    %   data passed by the build runner to plugin methods that extend the
    %   running of the task graph. The build runner instantiates this class, so
    %   you are not required to create an object of the class directly.
    
    %   Copyright 2021-2022 The MathWorks, Inc.
    
    properties (Dependent, SetAccess = immutable)
        % TaskGraph - Task graph being run
        %
        %   Task graph being run within the scope of the plugin method, returned as
        %   a matlab.buildtool.TaskGraph scalar.
        TaskGraph (1,1) matlab.buildtool.TaskGraph
    end
    
    properties (Dependent, SetAccess = immutable)
        % TaskResults - Results from running tasks
        %
        %   Results from running the tasks within the task graph of the plugin data
        %   TaskGraph property, returned as a matlab.buildtool.TaskResult row
        %   vector.
        TaskResults (1,:) matlab.buildtool.TaskResult
    end
    
    properties (SetAccess = immutable, GetAccess = private)
        BuildRunData matlab.buildtool.internal.BuildRunData {mustBeScalarOrEmpty}
    end

    properties (Dependent, SetAccess = private)
        Plan
    end

    properties (SetAccess = immutable, GetAccess = private)
        Indices (1,:) {mustBeNumeric}
    end
        
    methods (Access = {?matlab.buildtool.BuildRunner, ?matlab.buildtool.plugins.plugindata.RunPluginData})
        function data = RunPluginData(name, runData, indices)
            arguments
                name (1,1) string
                runData (1,1) matlab.buildtool.internal.BuildRunData
                indices (1,:) {mustBeNumeric}
            end
            
            data@matlab.buildtool.plugins.plugindata.PluginData(name);
            
            data.BuildRunData = runData;
            data.Indices = indices;
        end
    end
    
    methods
        function graph = get.TaskGraph(data)
            graph = data.BuildRunData.TaskGraph.subgraph(data.Indices);
        end
        
        function results = get.TaskResults(data)
            results = data.BuildRunData.TaskResults(data.Indices);
        end

        function plan = get.Plan(data)
            plan = data.BuildRunData.Plan;
        end
    end
end

