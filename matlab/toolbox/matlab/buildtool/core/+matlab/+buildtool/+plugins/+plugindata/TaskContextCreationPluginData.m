classdef (Hidden) TaskContextCreationPluginData < matlab.buildtool.plugins.plugindata.PluginData
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % TaskContextCreationPluginData - Plugin data describing task context being created
    %
    %   The matlab.buildtool.plugins.plugindata.TaskContextCreationPluginData class
    %   defines the data passed by the build runner to plugin methods that
    %   extend the creation of task context. The build runner
    %   instantiates this class, so you are not required to create an object of
    %   the class directly.

    %   Copyright 2023-2024 The MathWorks, Inc.

    properties (SetAccess = immutable)
        % TaskChanges - Changes made to task since last successful run
        %
        %   Changes made to the task since the last successful run, returned as a
        %   matlab.buildtool.fingerprints.TaskChanges scalar.
        TaskChanges (1,1) matlab.buildtool.fingerprints.TaskChanges

        % BuildOptions - Build options passed to task action
        %
        %   Build options passed to the task action for evaluation within the scope
        %   of the plugin method, returned as a scalar struct.
        BuildOptions (1,1) struct
    end

    methods (Access = {?matlab.buildtool.BuildRunner, ?matlab.buildtool.plugins.plugindata.TaskContextCreationPluginData})
        function data = TaskContextCreationPluginData(name, taskChanges, buildOptions)
            arguments
                name (1,1) string
                taskChanges (1,1) matlab.buildtool.fingerprints.TaskChanges
                buildOptions (1,1) struct
            end

            data@matlab.buildtool.plugins.plugindata.PluginData(name);
            data.TaskChanges = taskChanges;
            data.BuildOptions = buildOptions;
        end
    end
end

