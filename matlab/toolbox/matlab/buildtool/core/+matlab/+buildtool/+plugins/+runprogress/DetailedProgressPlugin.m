classdef (Hidden) DetailedProgressPlugin < matlab.buildtool.plugins.BuildRunProgressPlugin
    % This class is unsupported and might change or be removed without notice
    % in a future version.
    
    % Copyright 2024 The MathWorks, Inc.

    methods (Access = ?matlab.buildtool.plugins.BuildRunProgressPlugin)
        function plugin = DetailedProgressPlugin(varargin)
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
            import matlab.buildtool.fingerprints.ChangeType;
            import matlab.buildtool.plugins.plugindata.TaskRunReason;
            import matlab.automation.internal.diagnostics.indentWithArrow;

            task = pluginData.TaskGraph.Tasks;

            if ~isempty(task.Actions)
                reason = pluginData.RunReason;
                if reason ~= TaskRunReason.Changed
                    msg = plugin.Catalog.getString("Starting", pluginData.Name);
                    msg = sprintf("%s (%s)", msg, plugin.Catalog.getString("RunReason" + string(reason)));
                    plugin.printLine(msg);
                else
                    msg = plugin.Catalog.getString("StartingBecause", pluginData.Name);
                    plugin.printLine(msg);
                    for diag = pluginData.ChangeDiagnostics
                        if diag.ChangeType == ChangeType.Unmodified
                            continue;
                        end
                        diag.diagnose();
                        plugin.printLine(indentWithArrow(diag.DiagnosticText));
                    end
                end
            end
            
            runTask@matlab.buildtool.plugins.BuildRunnerPlugin(plugin, pluginData);
            
            duration = seconds(pluginData.TaskResults.Duration);
            if isempty(task.Actions)
                msg = plugin.Catalog.getString("Done", pluginData.Name);
            elseif pluginData.TaskResults.Failed
                msg = plugin.Catalog.getString("FailedWithDuration", pluginData.Name, num2str(duration));
            else
                msg = plugin.Catalog.getString("FinishedWithDuration", pluginData.Name, num2str(duration));
            end
            plugin.printLine(msg);
            plugin.printEmptyLine();
        end

        function runTaskAction(plugin, pluginData)
            plugin.printIndentedLine(plugin.Catalog.getString("EvaluatingTaskAction", pluginData.Name), " ");

            runTaskAction@matlab.buildtool.plugins.BuildRunnerPlugin(plugin, pluginData);
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