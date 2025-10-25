classdef (Hidden) TaskActionRunPluginData < matlab.buildtool.plugins.plugindata.RunPluginData
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % TaskActionRunPluginData - Plugin data describing task action being run
    %
    %   The matlab.buildtool.plugins.plugindata.TaskActionRunPluginData class
    %   defines the data passed by the build runner to plugin methods that
    %   extend the running of a single task action. The build runner
    %   instantiates this class, so you are not required to create an object of
    %   the class directly.
    
    %   Copyright 2021-2022 The MathWorks, Inc.
    
    properties (SetAccess = immutable)
        % TaskAction - Task action being run
        %
        %   Task action being run within the scope of the plugin method, returned
        %   as a matlab.buildtool.TaskAction scalar.
        TaskAction matlab.buildtool.TaskAction {mustBeScalarOrEmpty}
        
        % TaskArguments - Arguments passed to task action
        %
        %   Arguments passed to the task action for evaluation within the scope
        %   of the plugin method, returned as a cell array.
        TaskArguments (1,:) cell
    end
    
    methods (Access = {?matlab.buildtool.BuildRunner, ?matlab.buildtool.plugins.plugindata.TaskActionRunPluginData})
        function data = TaskActionRunPluginData(name, runData, index, action, taskArguments)
            arguments
                name (1,1) string
                runData (1,1) matlab.buildtool.internal.BuildRunData
                index (1,1) {mustBeInteger}
                action (1,1) matlab.buildtool.TaskAction
                taskArguments (1,:) cell
            end
            
            data@matlab.buildtool.plugins.plugindata.RunPluginData(name, runData, index);
            data.TaskArguments = taskArguments;
            data.TaskAction = action;
        end
    end
end

