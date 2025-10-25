classdef (Hidden) ConciseProgressPlugin < matlab.buildtool.plugins.BuildRunProgressPlugin
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % ConciseProgressPlugin - Plugin that reports build run progress
    
    % Copyright 2021-2024 The MathWorks, Inc.
    
    methods (Access = ?matlab.buildtool.plugins.BuildRunProgressPlugin)
        function plugin = ConciseProgressPlugin(varargin)
            plugin = plugin@matlab.buildtool.plugins.BuildRunProgressPlugin(varargin{:});
        end
    end
    
    methods (Access = protected)
        function setupBuildFixture(plugin, pluginData)
            setupBuildFixture@matlab.buildtool.plugins.BuildRunnerPlugin(plugin, pluginData);

            if pluginData.Description ~= ""
                plugin.printLine(pluginData.Description);
                plugin.printEmptyLine();
            end
        end

        function teardownBuildFixture(plugin, pluginData)
            teardownBuildFixture@matlab.buildtool.plugins.BuildRunnerPlugin(plugin, pluginData);

            if pluginData.Description ~= ""
                plugin.printLine(pluginData.Description);
                plugin.printEmptyLine();
            end
        end

        function runTask(plugin, pluginData)
            task = pluginData.TaskGraph.Tasks;

            if ~isempty(task.Actions)
                plugin.printLine(plugin.Catalog.getString("Starting", pluginData.Name));
            end
            
            runTask@matlab.buildtool.plugins.BuildRunnerPlugin(plugin, pluginData);
            
            if isempty(task.Actions)
                resultMsgId = "Done";
            elseif pluginData.TaskResults.Failed
                resultMsgId = "Failed";
            else
                resultMsgId = "Finished";
            end
            plugin.printLine(plugin.Catalog.getString(resultMsgId, pluginData.Name));
            plugin.printEmptyLine();
        end

        function skipTask(plugin, pluginData)
            import matlab.buildtool.plugins.plugindata.TaskSkipReason;

            skipTask@matlab.buildtool.plugins.BuildRunnerPlugin(plugin, pluginData);
            
            reason = pluginData.SkipReason;
            if reason ~= TaskSkipReason.DependencyFailed
                msg = plugin.Catalog.getString("Skipped", pluginData.Name);
                msg = sprintf("%s (%s)", msg, plugin.Catalog.getString("SkipReason" + string(reason)));
                plugin.printLine(msg);
                plugin.printEmptyLine();
            end
        end
    end
end

