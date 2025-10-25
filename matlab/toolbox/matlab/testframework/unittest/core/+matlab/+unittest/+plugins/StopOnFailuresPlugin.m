classdef StopOnFailuresPlugin < matlab.unittest.plugins.TestRunnerPlugin & ...
        matlab.unittest.internal.mixin.IncludingAssumptionFailuresMixin & ...
        matlab.unittest.internal.plugins.InteractiveTestRunnerPlugin
    % StopOnFailuresPlugin - Plugin to debug test failures.
    %
    %   The StopOnFailuresPlugin can be added to the TestRunner to pause execution
    %   of a test run and enter debug mode upon a qualification failure or
    %   uncaught error. By default, the StopOnFailuresPlugin only reacts to
    %   uncaught errors and verification, assertion, and fatal assertion
    %   qualification failures. However, when 'IncludingAssumptionFailures'
    %   is specified as true, the plugin also reacts to assumption failures.
    %
    %   Upon encountering a failure, the StopOnFailuresPlugin causes MATLAB to
    %   enter debug mode. At that point, MATLAB debugging commands such as
    %   DBUP, DBSTEP, DBCONT, and DBQUIT can be used to investigate the cause
    %   of the test failure.
    %
    %   StopOnFailuresPlugin methods:
    %       StopOnFailuresPlugin - Class constructor
    %
    %   StopOnFailuresPlugin properties:
    %       IncludeAssumptionFailures - Boolean that specifies whether to react to assumption failures
    %
    %   Example:
    %
    %       import matlab.unittest.TestRunner;
    %       import matlab.unittest.TestSuite;
    %       import matlab.unittest.plugins.StopOnFailuresPlugin;
    %
    %       % Create a TestSuite array
    %       suite = TestSuite.fromClass(?mynamespace.MyTestClass);
    %       % Create a TestRunner with no plugins
    %       runner = TestRunner.withNoPlugins;
    %
    %       % Add a new plugin to the TestRunner
    %       runner.addPlugin(StopOnFailuresPlugin('IncludingAssumptionFailures', true));
    %
    %       % Run the suite to enter debug mode upon failures
    %       result = runner.run(suite)
    %
    %   See also: TestRunnerPlugin, DBUP, DBSTEP, DBCONT, DBQUIT

    % Copyright 2012-2023 The MathWorks, Inc.
    
    properties(Access=private)
        FailureHandler = matlab.unittest.internal.plugins.DebugFailureHandler;
        Debugging;
    end

    methods
        function plugin = StopOnFailuresPlugin(varargin)
            % StopOnFailuresPlugin - Class constructor
            %
            %   PLUGIN = StopOnFailuresPlugin creates a StopOnFailuresPlugin
            %   instance and returns it in PLUGIN. This plugin can then be added to
            %   a TestRunner instance to pause execution of a test run and enter
            %   debug mode upon encountering a qualification failure or uncaught error.
            %
            %   Example:
            %
            %       import matlab.unittest.TestRunner;
            %       import matlab.unittest.TestSuite;
            %       import matlab.unittest.plugins.StopOnFailuresPlugin;
            %
            %       % Create a TestSuite array
            %       suite = TestSuite.fromClass(?mynamespace.MyTestClass);
            %       % Create a TestRunner with no plugins
            %       runner = TestRunner.withNoPlugins;
            %
            %       % Add a new plugin to the TestRunner
            %       runner.addPlugin(StopOnFailuresPlugin('IncludingAssumptionFailures', true));
            %
            %       % Run the suite to enter debug mode upon failures
            %       result = runner.run(suite)
            %

            plugin.addNameValue("FailureHandler_", @setFailureHandler);
            plugin = plugin.parse(varargin{:});
        end
    end

    methods (Hidden, Access=protected)
        function runSession(plugin, pluginData)
            plugin.Debugging = false;
            cleaner = matlab.unittest.internal.setStopIfCaughtErrorInTestRunner(true); %#ok<NASGU> 
            runSession@matlab.unittest.plugins.TestRunnerPlugin(plugin, pluginData);
        end

        function fixture = createSharedTestFixture(plugin, pluginData)
            fixture = createSharedTestFixture@matlab.unittest.plugins.TestRunnerPlugin(plugin, pluginData);
            fixture.addPostFailureEventCallback_(@(info)plugin.handleFailure(info));
        end
        function testCase = createTestClassInstance(plugin, pluginData)
            testCase = createTestClassInstance@matlab.unittest.plugins.TestRunnerPlugin(plugin, pluginData);
            testCase.addPostFailureEventCallback_(@(info)plugin.handleFailure(info));
        end
        function testCase = createTestMethodInstance(plugin, pluginData)
            testCase = createTestMethodInstance@matlab.unittest.plugins.TestRunnerPlugin(plugin, pluginData);
            testCase.addPostFailureEventCallback_(@(info)plugin.handleFailure(info));
        end
    end

    methods (Access=private)
        function plugin = setFailureHandler(plugin, handler)
            plugin.FailureHandler = handler;
        end
        
        function handleFailure(plugin, info)
            if ~plugin.Debugging  % don't recursively debug failures from the debug prompt
                c = onCleanup(@()resetDebugging(plugin));
                plugin.Debugging = true;

                if info.Type ~= "Errored" && ...
                        (info.Type ~= "AssumptionFailed" || plugin.IncludeAssumptionFailures)
                    plugin.FailureHandler.handleQualificationFailure;
                end
            end
        end

        function resetDebugging(plugin)
            plugin.Debugging = false;
        end
    end
end

% LocalWords:  mynamespace
