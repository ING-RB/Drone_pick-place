classdef (Hidden) BuildRunnerPlugin < matlab.buildtool.internal.BuildContentOperator
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % BuildRunnerPlugin - Plugin interface for extending build runner
    %
    %   The matlab.buildtool.plugins.BuildRunnerPlugin interface enables
    %   extension of the build runner. To customize a build run, create a
    %   subclass of BuildRunnerPlugin and override select methods.
    %   BuildRunnerPlugin provides you with a default implementation. Override
    %   only the methods that are required to achieve your customization. Every
    %   method you implement must invoke its corresponding superclass method,
    %   passing along the same instance of pluginData that it receives.
    %
    %   To run a build with this extension, add the custom BuildRunnerPlugin to
    %   the build runner by using its addPlugin method.
    %
    %   BuildRunnerPlugin methods:
    %      runTaskGraph         - Extend running task graph
    %      createBuildFixture   - Extend creating build fixture instance
    %      setupBuildFixture    - Extend setting up build fixture
    %      teardownBuildFixture - Extend tearing down build fixture
    %      createTaskContext    - Extend creating task context instance
    %      runTask              - Extend running single task
    %      runTaskAction        - Extend running single task action
    %      skipTask             - Extend skipping single task
    
    %   Copyright 2021-2024 The MathWorks, Inc.
    
    properties (Access = private, Transient)
        OperatorIterator matlab.buildtool.internal.BuildContentOperatorReverseIterator {mustBeScalarOrEmpty}
    end
    
    methods (Access = protected)
        function plugin = BuildRunnerPlugin()
        end
        
        function runTaskGraph(plugin, pluginData)
            % runTaskGraph - Extend running task graph
            %
            %   runTaskGraph(PLUGIN,PLUGINDATA) extends the running of the task graph
            %   formed by the BuildRunner instance. PLUGINDATA holds information about
            %   the task graph being run and is specified as a
            %   matlab.buildtool.plugins.plugindata.RunPluginData scalar.
            
            arguments
                plugin (1,1) matlab.buildtool.plugins.BuildRunnerPlugin
                pluginData (1,1) matlab.buildtool.plugins.plugindata.RunPluginData
            end
            
            nextOperator = plugin.getNextOperator();
            nextOperator.runTaskGraph(pluginData);
        end

        function fixture = createBuildFixture(plugin, pluginData)
            % createBuildFixture - Extend creating build fixture instance
            %
            %   FIXTURE = createBuildFixture(PLUGIN,PLUGINDATA) extends the creation
            %   of Fixture instances, and returns the modified Fixture instance.

            arguments
                plugin (1,1) matlab.buildtool.plugins.BuildRunnerPlugin
                pluginData (1,1) matlab.buildtool.plugins.plugindata.PluginData
            end

            nextOperator = plugin.getNextOperator();
            fixture = nextOperator.createBuildFixture(pluginData);
        end

        function setupBuildFixture(plugin, pluginData)
            % setupBuildFixture - Extend setting up build fixture
            %
            %   setupBuildFixture(PLUGIN,PLUGINDATA) extends the setting up of a build
            %   fixture. PLUGINDATA holds information about the fixture being set up
            %   and is specified as a
            %   matlab.buildtool.plugins.plugindata.BuildFixturePluginData scalar.

            arguments
                plugin (1,1) matlab.buildtool.plugins.BuildRunnerPlugin
                pluginData (1,1) matlab.buildtool.plugins.plugindata.BuildFixturePluginData
            end

            nextOperator = plugin.getNextOperator();
            nextOperator.setupBuildFixture(pluginData);
        end

        function teardownBuildFixture(plugin, pluginData)
            % teardownBuildFixture - Extend tearing down build fixture
            %
            %   teardownBuildFixture(PLUGIN,PLUGINDATA) extends the tearing down of a
            %   build fixture. PLUGINDATA holds information about the fixture being
            %   torn down and is specified as a
            %   matlab.buildtool.plugins.plugindata.BuildFixturePluginData scalar.

            arguments
                plugin (1,1) matlab.buildtool.plugins.BuildRunnerPlugin
                pluginData (1,1) matlab.buildtool.plugins.plugindata.BuildFixturePluginData
            end

            nextOperator = plugin.getNextOperator();
            nextOperator.teardownBuildFixture(pluginData);
        end

        function context = createTaskContext(plugin, pluginData)
            % createTaskContext - Extend creating task context instance 
            %
            %   CONTEXT = createTaskContext(PLUGIN,PLUGINDATA) extends the creation 
            %   of TaskContext instances, and returns the modified TaskContext
            %   instance.

            arguments
                plugin (1,1) matlab.buildtool.plugins.BuildRunnerPlugin
                pluginData (1,1) matlab.buildtool.plugins.plugindata.TaskContextCreationPluginData
            end

            nextOperator = plugin.getNextOperator();
            context = nextOperator.createTaskContext(pluginData);
        end
        
        function runTask(plugin, pluginData)
            % runTask - Extend running single task
            %
            %   runTask(PLUGIN,PLUGINDATA) extends the running of a single task in the
            %   running task graph. PLUGINDATA holds information about the task being
            %   run and is specified as a
            %   matlab.buildtool.plugins.plugindata.TaskRunPluginData scalar.
            
            arguments
                plugin (1,1) matlab.buildtool.plugins.BuildRunnerPlugin
                pluginData (1,1) matlab.buildtool.plugins.plugindata.TaskRunPluginData
            end
            
            nextOperator = plugin.getNextOperator();
            nextOperator.runTask(pluginData);
        end
        
        function runTaskAction(plugin, pluginData)
            % runTaskAction - Extend running single task action
            %
            %   runTaskAction(PLUGIN,PLUGINDATA) extends the running of a single task
            %   action in the running task. PLUGINDATA holds information about the task
            %   action being run and is specified as a
            %   matlab.buildtool.plugins.plugindata.TaskActionRunPluginData scalar.
            
            arguments
                plugin (1,1) matlab.buildtool.plugins.BuildRunnerPlugin
                pluginData (1,1) matlab.buildtool.plugins.plugindata.TaskActionRunPluginData
            end
            
            nextOperator = plugin.getNextOperator();
            nextOperator.runTaskAction(pluginData);
        end

        function skipTask(plugin, pluginData)
            % skipTask - Extend skipping single task
            %
            %   skipTask(PLUGIN,PLUGINDATA) extends the skipping of a single task in the
            %   running task graph. PLUGINDATA holds information about the task being
            %   skipped and is specified as a
            %   matlab.buildtool.plugins.plugindata.TaskSkipPluginData scalar.
            
            arguments
                plugin (1,1) matlab.buildtool.plugins.BuildRunnerPlugin
                pluginData (1,1) matlab.buildtool.plugins.plugindata.TaskSkipPluginData
            end
            
            nextOperator = plugin.getNextOperator();
            nextOperator.skipTask(pluginData);
        end
    end
    
    methods (Access = private)
        function nextOperator = getNextOperator(plugin)
            iter = plugin.OperatorIterator;
            iter.advance();
            nextOperator = iter.getCurrentOperator();
            nextOperator.acceptOperatorIterator_(iter);
        end
    end
    
    % Duck-typed PluginOperator interface
    methods (Hidden, Sealed, Access = ?matlab.buildtool.internal.PluginOperator)
        function acceptOperatorIterator_(plugin, iter)
            plugin.OperatorIterator = iter;
        end
    end
end

% LocalWords:  PLUGINDATA plugindata
