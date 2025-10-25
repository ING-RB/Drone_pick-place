classdef (Hidden) TerseProgressPlugin < matlab.buildtool.plugins.BuildRunProgressPlugin
    % This class is unsupported and might change or be removed without notice
    % in a future version.
    
    % Copyright 2024 The MathWorks, Inc.

    methods (Access = ?matlab.buildtool.plugins.BuildRunProgressPlugin)
        function plugin = TerseProgressPlugin(varargin)
            plugin = plugin@matlab.buildtool.plugins.BuildRunProgressPlugin(varargin{:});
        end
    end

    methods (Access = protected)
        function runTask(plugin, pluginData)
            plugin.printLine(pluginData.Name);

            runTask@matlab.buildtool.plugins.BuildRunnerPlugin(plugin, pluginData);

            plugin.printEmptyLine();
        end

        function skipTask(plugin, pluginData)
            import matlab.buildtool.plugins.plugindata.TaskSkipReason;

            skipTask@matlab.buildtool.plugins.BuildRunnerPlugin(plugin, pluginData);
            
            reason = pluginData.SkipReason;
            if reason ~= TaskSkipReason.DependencyFailed
                reasonMsg = plugin.Catalog.getString("SkipReason" + string(reason));
                skippedMsg = plugin.Catalog.getString("SkippedWithReason", reasonMsg);
                msg = sprintf("%s (%s)", pluginData.Name, skippedMsg);
                plugin.printLine(msg);
                plugin.printEmptyLine();
            end
        end
    end
end