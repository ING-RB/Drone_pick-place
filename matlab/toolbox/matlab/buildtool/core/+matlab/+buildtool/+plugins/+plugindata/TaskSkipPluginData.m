classdef (Hidden) TaskSkipPluginData < matlab.buildtool.plugins.plugindata.RunPluginData
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % TaskSkipPluginData - Plugin data describing task graph being skipped
    %
    %   The matlab.buildtool.plugins.plugindata.TaskSkipPluginData class defines the
    %   data passed by the build runner to plugin methods that extend the
    %   skipping of the task graph. The build runner instantiates this class, so
    %   you are not required to create an object of the class directly.
    
    %   Copyright 2022-2024 The MathWorks, Inc.

    properties (SetAccess = immutable)
        SkipReason (1,1) matlab.buildtool.plugins.plugindata.TaskSkipReason
    end
        
    methods (Access = {?matlab.buildtool.BuildRunner, ?matlab.buildtool.plugins.plugindata.TaskSkipPluginData})
        function data = TaskSkipPluginData(name, runData, indices, reason)
            arguments
                name (1,1) string
                runData (1,1) matlab.buildtool.internal.BuildRunData
                indices (1,:) {mustBeNumeric}
                reason (1,1) matlab.buildtool.plugins.plugindata.TaskSkipReason
            end
            
            data@matlab.buildtool.plugins.plugindata.RunPluginData(name, runData, indices);

            data.SkipReason = reason;
        end
    end
end

