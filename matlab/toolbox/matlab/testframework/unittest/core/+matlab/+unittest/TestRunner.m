classdef(Sealed) TestRunner < ...
        matlab.unittest.internal.TestContentOperator & ...
        matlab.unittest.internal.PluginOperator & ...
        matlab.unittest.internal.TestRunnerExtension
    % TestRunner - Class used to run tests in matlab.unittest
    %
    %   The matlab.unittest.TestRunner class is the fundamental API used to run
    %   a suite of tests in matlab.unittest. It runs and operates on TestSuite
    %   arrays and is responsible for constructing the TestCase class instances
    %   containing test code, setting up and tearing down fixtures, and
    %   executing the test methods. It ensures that all of the test and fixture
    %   methods are run at the appropriate times and in the appropriate manner,
    %   and records information about the run into TestResults. It is the only
    %   supported class with the ability to run Test content to ensure that
    %   tests are run in the manner guaranteed by the TestCase interface.
    %
    %   To create a TestRunner for use in running tests, one can use one of the
    %   static methods provided by the TestRunner class.
    %
    %   TestRunner methods:
    %       withNoPlugins      - Create the simplest runner possible
    %       withTextOutput     - Create a runner for command window output
    %       withDefaultPlugins - Create a runner with default plugins
    %
    %       run           - Run all the tests in a TestSuite array
    %       runInParallel - Run tests on a parallel pool (requires Parallel Computing Toolbox)
    %       addPlugin     - Add a TestRunnerPlugin to a TestRunner
    %
    %   TestRunner properties:
    %       ArtifactsRootFolder - Root folder where test run artifacts are stored
    %       PrebuiltFixtures    - Fixtures that are set up outside the test runner
    %
    %   Example:
    %
    %       import matlab.unittest.TestRunner;
    %       import matlab.unittest.TestSuite;
    %
    %       % Create a TestSuite array
    %       suite   = TestSuite.fromClass(?mynamespace.MyTestClass);
    %
    %       % Create a "standard" TestRunner and run the suite
    %       runner = TestRunner.withTextOutput;
    %       runner.run(suite)
    %
    %   See also: TestSuite, TestResult, plugins.TestRunnerPlugin
    %

    % Copyright 2012-2024 The MathWorks, Inc.

    properties (Dependent)
        % ArtifactsRootFolder - Root folder where test run artifacts are stored
        %
        %   The ArtifactsRootFolder property is the root folder where artifact
        %   subfolders associated with test runs may be created. By default, the
        %   value of ArtifactsRootFolder is string(tempdir) but can be set to any
        %   writable folder, given as a string scalar or a character vector.
        %
        %   Any artifacts produced during an individual call to run or
        %   runInParallel are stored in a subfolder underneath ArtifactsRootFolder
        %   whose name is a unique identifier associated with that individual run.
        %   For example, if the ArtifactsRootFolder is set to "C:\Temp" and
        %   "1231df38-7515-4dbe-a869-c3d9f885f379" is the automatically generated
        %   run identifier, then if an artifact is produced during the run with the
        %   name "artifact.txt", it will be stored as
        %   "C:\Temp\1231df38-7515-4dbe-a869-c3d9f885f379\artifact.txt". If no
        %   artifacts are produced during a test run, then no artifact subfolder
        %   will be created.
        %
        ArtifactsRootFolder
    end
    properties
        % PrebuiltFixtures - Fixtures that are set up outside the test runner
        %
        %   The PrebuiltFixtures property can be set to a vector of one or more
        %   matlab.unittest.fixtures.Fixture instances which are considered to have
        %   already been set up. The runner never attempts to set up or tear down
        %   any fixture instances specified via the PrebuiltFixtures property.
        %   Furthermore, when running a suite, the test runner does not perform set
        %   up or tear down actions for a shared test fixture required by the suite
        %   if that fixture is specified as a prebuilt fixture. This provides a
        %   means to specify that the environmental configuration which would
        %   otherwise be performed by a fixture has already been performed manually.
        %
        %   Example:
        %       import matlab.unittest.TestRunner;
        %       import matlab.unittest.TestSuite;
        %
        %       % Create a TestSuite array
        %       suite = TestSuite.fromClass(?mynamespace.MyTestClass);
        %
        %       % Create the test runner and add a fixture that need not be set up
        %       runner = TestRunner.withTextOutput;
        %       runner.PrebuiltFixtures = MyFixture;
        %       runner.run(suite)
        %
        %   See also: matlab.unittest.fixtures.Fixture
        %
        PrebuiltFixtures (1,:) matlab.unittest.fixtures.Fixture;
    end

    properties(Dependent, SetAccess=private, Hidden)
        Plugins
    end

    properties(Hidden, Access = {?matlab.unittest.internal.TestRunnerExtension, ?matlab.unittest.internal.TestRunStrategy})
        TestRunStrategy
        PluginData = struct;
        TestRunData;
    end

    properties(Access=private)
        OperatorList;
        ActiveFixtures (1,:) matlab.unittest.internal.FixtureRole;
        SharedTestFixtureToSetup;

        ClassLevelStruct = struct(...
            'TestCase', [], ...
            'TestClassSetupMethods', [], ...
            'TestMethodSetupMethods', [], ...
            'TestMethods', [], ...
            'TestMethodTeardownMethods', [], ...
            'TestClassTeardownMethods', []);

        RepeatLoopTestCase;

        CurrentMethodLevelTestCase;

        PluginsInvokedRunnerContent = false;
        VerificationFailureRecorded = false;

        LastQualificationFailedExceptionMarker = matlab.unittest.internal.qualifications.QualificationFailedExceptionMarker;

        FinalizedResultReportedIndex; % Results have been finalized up to this index
    end

    properties (Dependent, Access=private)
        DiagnosticData %Depends on TestRunData (which is set during a call to run)
    end

    methods(Static)
        function runner = withNoPlugins
            % withNoPlugins  - Create the simplest runner possible
            %
            %   RUNNER = matlab.unittest.TestRunner.withNoPlugins creates a TestRunner
            %   that is guaranteed to have no plugins installed and returns it in
            %   RUNNER. It is the method one can use to create the simplest runner
            %   possible without violating the guarantees a test writer has when
            %   writing TestCase classes. This runner is a silent runner, meaning that
            %   regardless of passing or failing tests, this runner produces no output
            %   whatsoever, although the results returned after running a test suite
            %   are accurate.
            %
            %   This method can also be used when it is desirable to have complete
            %   control over which plugins are installed and in what order. It is the
            %   only method guaranteed to produce the minimal TestRunner with no
            %   plugins, so one can create it and add additional plugins as desired.
            %
            %   Example:
            %
            %       import matlab.unittest.TestRunner;
            %       import matlab.unittest.TestSuite;
            %
            %       % Create a TestSuite array
            %       suite   = TestSuite.fromClass(?mynamespace.MyTestClass);
            %       % Create a silent TestRunner guaranteed to have no plugins
            %       runner = TestRunner.withNoPlugins;
            %
            %       % Run the suite silently
            %       result = runner.run(suite)
            %
            %       % Control over which plugins are installed is maintained
            %       runner.addPlugin(MyCustomRunnerPlugin);
            %       runner.addPlugin(AnotherCustomPlugin);
            %
            %       % Run the suite with the custom plugins
            %       result = runner.run(suite)
            %
            %   See also: plugins.TestRunnerPlugin
            %
            import matlab.unittest.TestRunner;
            runner = TestRunner;
        end

        function runner = withTextOutput(namedargs)
            % withTextOutput - Create a runner for command window output
            %
            %   RUNNER = matlab.unittest.TestRunner.withTextOutput creates a TestRunner
            %   that is configured to run tests from the Command Window and returns it
            %   in RUNNER. The output produced includes test progress as well as
            %   diagnostics in the event of test failures.
            %
            %   RUNNER = matlab.unittest.TestRunner.withTextOutput('LoggingLevel',LOGGINGLEVEL)
            %   creates a TestRunner that is configured to report logged diagnostics at
            %   or below the specified verbosity level LOGGINGLEVEL. Specify
            %   LOGGINGLEVEL as a numeric value (0, 1, 2, 3, or 4), a matlab.automation.Verbosity
            %   enumeration member, or a string or character vector corresponding to the name
            %   of a matlab.automation.Verbosity enumeration member.
            %
            %   RUNNER = matlab.unittest.TestRunner.withTextOutput('OutputDetail',OUTPUTDETAIL)
            %   creates a TestRunner that is configured to display test run progress
            %   and event information with the amount of output detail specified by
            %   OUTPUTDETAIL. Specify OUTPUTDETAIL as a numeric value (0, 1, 2,
            %   3, or 4), a matlab.automation.Verbosity enumeration member, or a string or
            %   character vector corresponding to the name of a matlab.automation.Verbosity
            %   enumeration member.
            %
            %   Example:
            %       import matlab.unittest.TestRunner;
            %       import matlab.unittest.TestSuite;
            %
            %       % Create a TestSuite array
            %       suite   = TestSuite.fromClass(?mynamespace.MyTestClass);
            %       % Create a TestRunner that produced output to the Command Window
            %       runner = TestRunner.withTextOutput;
            %
            %       % Run the suite
            %       result = runner.run(suite)
            %
            %   See also:
            %       matlab.unittest.TestSuite/run
            %       matlab.automation.Verbosity

            arguments
                namedargs.LoggingLevel (1,1) matlab.automation.Verbosity;
                namedargs.OutputDetail (1,1) matlab.automation.Verbosity;
                namedargs.Verbosity (1,1) matlab.automation.Verbosity; % for backward compatibility only
            end

            import matlab.unittest.TestRunner;

            runner = TestRunner;
            runner.addPlugin(runner.createTestRunProgressPlugin(namedargs));
            runner.addPlugin(runner.createDiagnosticsOutputPlugin(namedargs));
        end

        function runner = withDefaultPlugins(namedargs)
            % withDefaultPlugins - Create a runner with default plugins
            %
            %   RUNNER = matlab.unittest.TestRunner.withDefaultPlugins creates a 
            %   TestRunner that is configured with a set of default plugins and returns 
            %   it in RUNNER. This runner provides a balanced setup that includes common 
            %   functionality such as text output for test progress and diagnostics, 
            %   without requiring additional configuration. It is designed to meet the 
            %   typical needs of test writers by providing informative feedback during 
            %   test execution while maintaining simplicity and ease of use. This method 
            %   is ideal for users who want a straightforward setup with essential features 
            %   enabled by default.
            %
            %   RUNNER = matlab.unittest.TestRunner.withDefaultPlugins(LoggingLevel=LOGGINGLEVEL)
            %   creates a TestRunner that is configured to report logged diagnostics at
            %   or below the specified verbosity level LOGGINGLEVEL. Specify
            %   LOGGINGLEVEL as a numeric value (0, 1, 2, 3, or 4), a matlab.automation.Verbosity
            %   enumeration member, or a string or character vector corresponding to the name
            %   of a matlab.automation.Verbosity enumeration member.
            %
            %   RUNNER = matlab.unittest.TestRunner.withDefaultPlugins(OutputDetail=OUTPUTDETAIL)
            %   creates a TestRunner that is configured to display test run progress
            %   and event information with the amount of output detail specified by
            %   OUTPUTDETAIL. Specify OUTPUTDETAIL as a numeric value (0, 1, 2,
            %   3, or 4), a matlab.automation.Verbosity enumeration member, or a string or
            %   character vector corresponding to the name of a matlab.automation.Verbosity
            %   enumeration member.
            %
            %   Example:
            %       import matlab.unittest.TestRunner;
            %       import matlab.unittest.TestSuite;
            %
            %       % Create a TestSuite array
            %       suite   = TestSuite.fromClass(?mynamespace.MyTestClass);
            %       % Create a TestRunner with default plugins
            %       runner = TestRunner.withDefaultPlugins;
            %
            %       % Run the suite
            %       result = runner.run(suite)
            %
            %   See also:
            %       matlab.unittest.TestSuite/run
            %       matlab.automation.Verbosity

            arguments
                namedargs.LoggingLevel (1,1) matlab.automation.Verbosity;
                namedargs.OutputDetail (1,1) matlab.automation.Verbosity;
            end

            import matlab.unittest.TestRunner;
            import matlab.unittest.internal.plugins.PluginProviderData;

            runner = TestRunner;

            pluginProviderData = PluginProviderData(namedargs);

            s = settings;
            pluginsFunction = str2func(s.matlab.unittest.DefaultPluginsFcn.ActiveValue);

            plugins = pluginsFunction(pluginProviderData);

            for idx = 1:numel(plugins)
                runner.addPlugin(plugins(idx));
            end
        end
    end

    methods
        function result = run(runner, suite, varargin)
            % RUN - Run all the tests in a TestSuite array
            %
            %   RESULT = RUN(RUNNER, SUITE) runs the TestSuite defined by SUITE using
            %   the TestRunner provided in RUNNER, and returns the result in RESULT.
            %   RESULT is a matlab.unittest.TestResult which is the same size as SUITE,
            %   and each element is the result of the corresponding element in SUITE.
            %   This method ensures that tests written using the TestCase interface are
            %   correctly run. This includes running all of the appropriate methods of
            %   the TestCase class to set up fixtures and run test content. It ensures
            %   that errors and qualification failures are handled appropriately and
            %   their impacts are recorded into RESULTS.
            %
            %   Example:
            %       import matlab.unittest.TestSuite;
            %       import matlab.unittest.TestRunner;
            %
            %       suite = TestSuite.fromClass(?mynamespace.MyTestClass);
            %       runner = TestRunner.withTextOutput;
            %
            %       result = runner.run(suite)
            %
            %   See also: runInParallel, TestSuite, TestResult, TestCase, plugins.TestRunnerPlugin
            %

            import matlab.unittest.internal.generateParserWithNewRunIdentifier;
            import matlab.unittest.internal.RunOnceTestRunData;
            import matlab.unittest.plugins.plugindata.RunPluginData;

            validateattributes(suite, {'matlab.unittest.TestSuite'}, {});

            parser = generateParserWithNewRunIdentifier();
            parser.parse(varargin{:});

            runner.TestRunData = RunOnceTestRunData.fromSuite(suite, ...
                parser.Results.RunIdentifier,runner);

            nSuites = numel(runner.TestRunData.TestSuite);
            pluginData = RunPluginData('', runner.TestRunData, nSuites);

            result = doRunWithFcn(runner, "runSession", pluginData);
        end

        function addPlugin(runner, plugin)
            % addPlugin - Add a TestRunnerPlugin to a TestRunner
            %
            %   addPlugin(RUNNER, PLUGIN) adds the TestRunnerPlugin PLUGIN to the
            %   TestRunner RUNNER. Plugins are the mechanism provided to customize the
            %   manner in which a TestSuite is run.
            %
            %   Example:
            %
            %       import matlab.unittest.TestRunner;
            %       import matlab.unittest.TestSuite;
            %
            %       % Create a TestSuite array
            %       suite   = TestSuite.fromClass(?mynamespace.MyTestClass);
            %       % Create a TestRunner with no plugins installed
            %       runner = TestRunner.withNoPlugins;
            %
            %       % Add a custom plugin
            %       runner.addPlugin(MyCustomPlugin);
            %       result = runner.run(suite)
            %
            %   See also: plugins.TestRunnerPlugin
            %
            arguments
                runner;
                plugin (1,1) matlab.unittest.plugins.TestRunnerPlugin;
            end
            
            runner.OperatorList.addPlugin(plugin);
        end
    end

    methods (Hidden)
        function result = runRepeatedly(runner, suite, numRepetitions, varargin)
            % RUNREPEATEDLY - Run all the tests in a TestSuite array repeatedly
            %
            %   RESULT = RUNREPEATEDLY(RUNNER, SUITE, NUMREPETITIONS) runs
            %   the TestSuite defined by SUITE repeatedly NUMREPETITIONS times using
            %   the TestRunner provided in RUNNER, and returns the result in RESULT. RESULT is a
            %   matlab.unittest.CompositeTestResult which is the same size as SUITE,
            %   and each element is the result of the corresponding element in SUITE.
            %   Furthermore, each element in the CompositeTestResult is composed of an array of
            %   child test results, each element of which corresponds to a repetition of a suite element.
            %
            %   RESULT = RUNREPEATEDLY(...,'EarlyTerminationFcn',EARLYTERMINATEFCN)
            %   runs the TestSuite defined by SUITE repeatedly NUMREPETITIONS times or
            %   until the EARLYTERMINATEFCN returns true. EARLYTERMINATEFCN is
            %   specified as a function handle that defines the criteria to break out
            %   of the suite repetition early. When EARLYTERMINATEFCN evaluates to true
            %   the repetition stops. It is invoked once for each iteration.
            %
            %   Example:
            %       import matlab.unittest.TestSuite;
            %       import matlab.unittest.TestRunner;
            %
            %       suite = TestSuite.fromClass(?mynamespace.MyTestClass);
            %       runner = TestRunner.withTextOutput;
            %
            %       result = runner.runRepeatedly(suite, 3)
            %
            %   See also: runInParallel, TestSuite, TestResult, TestCase, plugins.TestRunnerPlugin
            %

            import matlab.unittest.internal.generateParserWithNewRunIdentifier;
            import matlab.unittest.internal.RunRepeatedlyTestRunData;
            import matlab.unittest.plugins.plugindata.RunPluginData;

            validateattributes(numRepetitions, {'numeric'}, {'positive', 'scalar', 'integer'});

            parser = generateParserWithNewRunIdentifier();
            parser.addParameter('EarlyTerminationFcn',@(varargin)false,...
                @(x) validateattributes(x,{'function_handle'},{},'','EarlyTerminationFcn'));
            parser.parse(varargin{:});

            runner.TestRunData = RunRepeatedlyTestRunData.fromSuite(suite, ...
                parser.Results.RunIdentifier, numRepetitions, parser.Results.EarlyTerminationFcn,runner);

            nSuites = numel(runner.TestRunData.TestSuite);
            pluginData = RunPluginData('', runner.TestRunData, nSuites);
            result = doRunWithFcn(runner,'runSession', pluginData);
        end
    end

    methods %  Getters & Setters
        function diagData = get.DiagnosticData(runner)
            diagData = runner.TestRunStrategy.getDiagnosticData(runner.TestRunData.RunIdentifier);
        end

        function set.ArtifactsRootFolder(runner,folder)
            runner.TestRunStrategy.ArtifactsRootFolder = folder;
        end

        function folder = get.ArtifactsRootFolder(runner)
            folder = runner.TestRunStrategy.ArtifactsRootFolder;
        end

        function plugins = get.Plugins(runner)
            plugins = [matlab.unittest.plugins.TestRunnerPlugin.empty(1,0), runner.OperatorList.Plugins{:}];
        end
    end

    methods (Access={?matlab.unittest.internal.TestRunStrategy, ?matlab.unittest.internal.TestRunnerExtension})
        function result = doRunWithFcn(runner, methodName, pluginData)
            import matlab.unittest.internal.Teardownable;
            import matlab.unittest.internal.WarningStackPrinter;

            printer = WarningStackPrinter;
            printer.enable; % disabled at scope-exit

            teardownable = Teardownable;
            teardownable.addTeardown(@()runner.deleteTestRunData);
            teardownable.addTeardown(@()runner.deletePluginData);

            runner.PluginData.(methodName) = pluginData;
            runner.evaluateMethodOnPlugins(methodName, pluginData);

            result = runner.TestRunData.TestResult;

            teardownable.runAllTeardownThroughProcedure_( ...
                @(fcn,varargin)fcn(teardownable, varargin{:}));
        end

        function varargout = evaluateMethodOnPlugins(runner, methodName, pluginData)
            [plugin, iter] = runner.prepareToEvaluateMethodOnPlugins(methodName);

            try
                [varargout{1:nargout}] = plugin.(methodName)(pluginData);
            catch exception
                plugin.handlePluginException_(exception, methodName, pluginData, iter);
            end

            runner.completePluginMethodEvaluation(methodName);
        end
    end

    % Duck-typed PluginOperator interface:
    methods (Hidden, Access={?matlab.unittest.internal.PluginOperator, ?matlab.unittest.plugins.TestRunnerPlugin})
        function handlePluginException_(runner, exception, ~, ~, ~)
            runner.rethrowException(exception);
        end

        function acceptOperatorIterator_(~, ~)
            % No-op; TestRunner doesn't need the OperatorIterator.
        end
    end

    methods(Access=private)
        function runner = TestRunner(strategy)
            arguments
                strategy = matlab.unittest.internal.SerialTestRunStrategy;
            end

            import matlab.unittest.internal.TestContentOperatorList;

            runner.OperatorList = TestContentOperatorList(runner);
            runner.TestRunStrategy = strategy;
        end

        function [plugin, iter] = prepareToEvaluateMethodOnPlugins(runner, methodName)
            runner.PluginsInvokedRunnerContent = false;
            runner.VerificationFailureRecorded = false;

            iter = runner.OperatorList.getIteratorFor(methodName);
            plugin = iter.getCurrentOperator;
            plugin.acceptOperatorIterator_(iter);
        end

        function completePluginMethodEvaluation(runner, methodName)
            if ~runner.PluginsInvokedRunnerContent
                error(message("MATLAB:unittest:TestRunner:MustCallSuperclassMethod"));
            end
            runner.validateNoVerificationsInPlugins(methodName);
        end

        function handlePluginExceptionInProhibitedScope(runner, exception, methodName)
            if isa(exception, "matlab.unittest.qualifications.AssertionFailedException") || ...
                    isa(exception, "matlab.unittest.qualifications.AssumptionFailedException")
                throwAsCaller(MException(message("MATLAB:unittest:TestRunner:QualificationInUnsupportedScope", methodName)).addCause(exception));
            else
                runner.rethrowException(exception);
            end
        end

        function runSharedTestCase(runner, pluginData)

            % Update results in the event of Ctrl-C
            resultReporter = matlab.unittest.internal.CancelableCleanup(@runner.recordInterruptedSharedTestCase);

            cleanup = matlab.unittest.internal.CancelableCleanup(@runner.teardownClassLevelTestCase);

            % Get the subsuite from plugin data
            suite = pluginData.TestSuite;

            % prepare test class by creating a test class instance and
            % setting it up.
            runner.prepareTestClass(suite);

            resultReporter.cancel;

            if runner.TestRunData.CurrentResult.Incomplete
                % If TestClassSetup is incomplete, update the current index
                % and proceed with the TestClassTeardown.
                runner.TestRunData.CurrentIndex = runner.TestRunData.CurrentIndex + numel(suite) - 1;
            else
                % If test class setup is successful, then proceed with running
                % the individual tests
                usePlugins = runner.OperatorList.hasPluginThatImplements("runTest");
                for idx = 1:numel(suite)
                    pluginData.CurrentIndex = idx;
                    runner.repeatTest(usePlugins);
                end
            end

            cleanup.cancelAndInvoke;
        end

        function repeatTest(runner, usePlugins)
            import matlab.unittest.plugins.plugindata.RunPluginData;
            import matlab.unittest.plugins.plugindata.ImplicitFixturePluginData;
            import matlab.unittest.plugins.plugindata.TestContentCreationPluginData;
            import matlab.unittest.internal.plugins.DeterminedDetailsLocationProvider;

            % Create repeat loop level testcase
            if runner.TestRunData.ShouldEnterRepeatLoopScope
                if runner.OperatorList.hasPluginThatImplements("createTestRepeatLoopInstance")
                    runner.PluginData.createTestRepeatLoopInstance = TestContentCreationPluginData( ...
                        runner.TestRunData.CurrentResult.Name, runner.TestRunData, ...
                        DeterminedDetailsLocationProvider(runner.TestRunData.CurrentIndex,runner.TestRunData.CurrentIndex));

                    plugin = runner.prepareToEvaluateMethodOnPlugins("createTestRepeatLoopInstance");
                    try
                        runner.RepeatLoopTestCase = plugin.createTestRepeatLoopInstance(runner.PluginData.createTestRepeatLoopInstance);
                    catch exception
                        runner.handlePluginExceptionInProhibitedScope(exception, "createTestRepeatLoopInstance");
                    end
                    runner.completePluginMethodEvaluation("createTestRepeatLoopInstance");

                    delete(runner.PluginData.createTestRepeatLoopInstance);
                else
                    runner.RepeatLoopTestCase = runner.createTestRepeatLoopInstanceCore;
                end

                runner.PluginData.setupTestRepeatLoop = ImplicitFixturePluginData(runner.TestRunData.CurrentResult.Name, runner.RepeatLoopTestCase, runner.TestRunData, runner.TestRunData.CurrentIndex);
                cleanupRepeatLoopTestCase = matlab.unittest.internal.CancelableCleanup(@runner.deleteCurrentRepeatLoopTestCase);
            else
                runner.RepeatLoopTestCase = runner.ClassLevelStruct.TestCase;
            end

            cleanup = matlab.unittest.internal.CancelableCleanup(@runner.finalizeResultsAtMethodLevelIfNeeded);

            runner.TestRunData.resetRepeatLoop;

            keepGoing = true;
            while keepGoing
                runner.TestRunData.beginRepeatLoopIteration;
                % Evaluate runTest
                if usePlugins
                    runner.PluginData.runTest = RunPluginData( ...
                        runner.TestRunData.CurrentResult.Name, runner.TestRunData, runner.TestRunData.CurrentIndex, ForLeafResult=true);
                    plugin = runner.prepareToEvaluateMethodOnPlugins("runTest");
                    try
                        plugin.runTest(runner.PluginData.runTest);
                    catch exception
                        runner.handlePluginExceptionInProhibitedScope(exception, "runTest");
                    end
                    runner.completePluginMethodEvaluation("runTest");
                    delete(runner.PluginData.runTest);
                else
                    runner.runTestCore;
                end

                keepGoing = runner.TestRunData.shouldContinueRepeatLoop;
            end

            if runner.TestRunData.ShouldEnterRepeatLoopScope
                runner.PluginData.teardownTestRepeatLoop = runner.PluginData.setupTestRepeatLoop;
                [plugin, iter] = runner.prepareToEvaluateMethodOnPlugins("teardownTestRepeatLoop");
                try
                    plugin.teardownTestRepeatLoop(runner.PluginData.teardownTestRepeatLoop);
                catch exception
                    plugin.handlePluginException_(exception, "teardownTestRepeatLoop", runner.PluginData.teardownTestRepeatLoop, iter);
                end
                runner.completePluginMethodEvaluation("teardownTestRepeatLoop");
                delete(runner.PluginData.teardownTestRepeatLoop);
                cleanupRepeatLoopTestCase.cancelAndInvoke;
            end

            runner.TestRunData.endRepeatLoop;

            cleanup.cancelAndInvoke;
        end

        function prepareSharedTestFixtures(runner)
            % Create and set up fixtures that are required but are not yet set up
            import matlab.unittest.internal.plugins.UndeterminedDetailsLocationProvider;
            test = runner.TestRunData.CurrentSuite;
            rolesToSetUp = runner.ActiveFixtures.determineSharedFixturesToSetUp(runner.PrebuiltFixtures, ...
                test.InternalSharedTestFixtures, test.SharedTestFixtures);
            for role = rolesToSetUp
                if runner.TestRunData.CurrentResult.Incomplete
                    break;
                end
                detailsLocationProvider = UndeterminedDetailsLocationProvider(runner.TestRunData.CurrentIndex, runner.determineFixtureEndIndex(role.Instance));

                % Update results in the event of Ctrl-C
                resultReporter = matlab.unittest.internal.CancelableCleanup(@()runner.recordInterruptedFixture(detailsLocationProvider));

                runner.ActiveFixtures(end+1) = role.constructFixture(@runner.constructUserFixture, detailsLocationProvider);
                runner.ActiveFixtures(end).setupFixture(@runner.setupUserFixture);

                resultReporter.cancel;
            end
        end

        function fixture = constructUserFixture(runner, role)
            import matlab.unittest.plugins.plugindata.TestContentCreationPluginData;

            runner.SharedTestFixtureToSetup = role;
            runner.PluginData.createSharedTestFixture = TestContentCreationPluginData(class(role.Instance),...
                runner.TestRunData, role.DetailsLocationProvider);
            plugin = runner.prepareToEvaluateMethodOnPlugins("createSharedTestFixture");
            fixture = plugin.createSharedTestFixture(runner.PluginData.createSharedTestFixture);
            runner.completePluginMethodEvaluation("createSharedTestFixture");
            delete(runner.PluginData.createSharedTestFixture);
        end

        function endIndex = determineFixtureEndIndex(runner, fixture)
            suite = runner.TestRunData.TestSuite;
            maximumEndIndex = runner.getNextSharedFixtureTeardownIndex;
            endIndex = runner.TestRunData.CurrentIndex;
            while endIndex < maximumEndIndex
                endIndex = endIndex + 1;
                if ~containsEquivalentFixture(runner.getAllSharedFixturesForSuite(suite(endIndex)), fixture)
                    endIndex = endIndex - 1;
                    break;
                end
            end
        end

        function endIndex = getNextSharedFixtureTeardownIndex(runner)
            if runner.ActiveFixtures.hasFixtureSetUpByRunner
                endIndex = runner.ActiveFixtures(end).DetailsLocationProvider.PotentialAffectedIndices(end);
            else
                endIndex = numel(runner.TestRunData.TestSuite);
            end
        end

        function setupUserFixture(runner, role)
            import matlab.unittest.plugins.plugindata.SharedTestFixturePluginData;

            fixture = role.Instance;
            runner.PluginData.setupSharedTestFixture = ...
                SharedTestFixturePluginData(class(fixture), fixture.SetupDescription, fixture, runner.TestRunData,...
                role.DetailsLocationProvider);
            c = matlab.unittest.internal.Teardownable;
            c.addTeardown(@()fixture.disableQualifications_);

            [plugin, iter] = runner.prepareToEvaluateMethodOnPlugins("setupSharedTestFixture");
            try
                plugin.setupSharedTestFixture(runner.PluginData.setupSharedTestFixture);
            catch exception
                plugin.handlePluginException_(exception, "setupSharedTestFixture", runner.PluginData.setupSharedTestFixture, iter);
            end
            runner.completePluginMethodEvaluation("setupSharedTestFixture");

            delete(runner.PluginData.setupSharedTestFixture);
        end

        function endIndex = determineClassEndIndex(runner)
            suite = runner.TestRunData.TestSuite;

            maximumEndIndex = runner.getNextSharedFixtureTeardownIndex;
            endIndex = runner.TestRunData.CurrentIndex;
            while endIndex < maximumEndIndex
                % Break if the next suite element belongs to a different class
                if suite(endIndex).ClassBoundaryMarker ~= suite(endIndex+1).ClassBoundaryMarker
                    break;
                end

                % Break if there are any shared test fixtures to setup for the next suite element
                if runner.ActiveFixtures.hasFixtureToSetUp(runner.getNextSharedFixtures(suite, endIndex))
                    break;
                end

                endIndex = endIndex + 1;
            end
        end

        function prepareTestClass(runner, suite)
            import matlab.unittest.internal.getAllTestCaseClassesInHierarchy;
            import matlab.unittest.plugins.plugindata.TestContentCreationPluginData;
            import matlab.unittest.plugins.plugindata.ImplicitFixturePluginData;
            import matlab.unittest.internal.plugins.DeterminedDetailsLocationProvider;

            locationProvider = DeterminedDetailsLocationProvider(runner.TestRunData.CurrentIndex, runner.TestRunData.CurrentIndex+numel(suite)-1);
            if runner.OperatorList.hasPluginThatImplements("createTestClassInstance")
                % It is OK to use only the first suite element here since
                % they all belong to the same test class.
                runner.PluginData.createTestClassInstance = TestContentCreationPluginData( ...
                    suite(1).SharedTestClassName, runner.TestRunData, locationProvider);
                plugin = runner.prepareToEvaluateMethodOnPlugins("createTestClassInstance");
                try
                    classLevelTestCase = plugin.createTestClassInstance(runner.PluginData.createTestClassInstance);
                catch exception
                    runner.handlePluginExceptionInProhibitedScope(exception, "createTestClassInstance");
                end
                runner.completePluginMethodEvaluation("createTestClassInstance");
                delete(runner.PluginData.createTestClassInstance);
            else
                classLevelTestCase = runner.createTestClassInstanceCore;
            end

            % Determine the TestClassSetup, TestClassTeardown, TestMethodSetup, and
            % TestMethodTeardown methods for this class. Base class methods first
            % for setup; derived class methods first for teardown.
            allTestClasses = flip(getAllTestCaseClassesInHierarchy(metaclass(classLevelTestCase)));
            testClassMethods = arrayfun(@(cls)cls.MethodList.findobj('DefiningClass', cls), ...
                allTestClasses, 'UniformOutput',false);
            testClassMethods = vertcat(testClassMethods{:});

            [~, idx] = unique({testClassMethods.Name}, 'stable');
            testClassMethods = testClassMethods(idx);

            testClassSetupMethods = findobj(testClassMethods, 'TestClassSetup', true);
            testMethodSetupMethods = findobj(testClassMethods, 'TestMethodSetup', true);
            testClassTeardownMethods = flip(findobj(testClassMethods, 'TestClassTeardown', true));
            testMethodTeardownMethods = flip(findobj(testClassMethods, 'TestMethodTeardown', true));

            % Create a map from test method name to test method meta.method
            % for near constant-time lookup of each test method.
            testMethods = findobj(testClassMethods, 'Test', true);
            testMethodMap = containers.Map({testMethods.Name}, num2cell(testMethods));

            runner.ClassLevelStruct = struct(...
                'TestCase', classLevelTestCase, ...
                'TestClassSetupMethods', testClassSetupMethods, ...
                'TestMethodSetupMethods', testMethodSetupMethods, ...
                'TestMethods', testMethodMap, ...
                'TestMethodTeardownMethods', testMethodTeardownMethods, ...
                'TestClassTeardownMethods', testClassTeardownMethods);

            runner.PluginData.setupTestClass = ImplicitFixturePluginData(suite(1).SharedTestClassName,...
                classLevelTestCase, runner.TestRunData, locationProvider);
            [plugin, iter] = runner.prepareToEvaluateMethodOnPlugins("setupTestClass");
            try
                plugin.setupTestClass(runner.PluginData.setupTestClass);
            catch exception
                plugin.handlePluginException_(exception, "setupTestClass", runner.PluginData.setupTestClass, iter);
            end
            runner.completePluginMethodEvaluation("setupTestClass");
        end

        function performTeardownOnSharedTestFixturesAtTopOfStack(runner, idx)
            role = runner.ActiveFixtures(idx);

            % Update results in the event of Ctrl-C
            resultReporter = matlab.unittest.internal.CancelableCleanup(@()runner.recordInterruptedFixture(role.DetailsLocationProvider));

            % Register teardown to remove the fixture from the active
            % fixtures in case the fixture teardown fatally asserts.
            cleanup = matlab.unittest.internal.CancelableCleanup(@()runner.removeFixture(role, idx));
            role.teardownFixture(@runner.teardownUserFixture);
            cleanup.cancelAndInvoke;

            resultReporter.cancel;
        end

        function reportFinalizedResultsForSharedTestFixtures(runner)
            if ~runner.ActiveFixtures.hasUserFixtureSetUpByRunner
                runner.reportFinalizedResultThroughCurrentIndex;
            end
        end

        function teardownAllSharedFixturesExcluding(runner, fixturesToKeep)
            % Tear down the fixtures that are no longer required.
            fixtureIndices = runner.ActiveFixtures.getIndicesOfFixturesToTearDown(fixturesToKeep);

            % Add teardown for all the fixtures so that even if the
            % teardown errors for a fixture at the top of the stack - the
            % rest of the fixtures are torn down
            if ~isempty(fixtureIndices)
                teardownFixtures = matlab.unittest.internal.Teardownable;
                teardownFixtures.addTeardown(@teardownAllSharedFixturesExcluding, ...
                    runner, fixturesToKeep);
            end

            for idx = fixtureIndices
                performTeardownOnSharedTestFixturesAtTopOfStack(runner, idx);
            end

            % Report finalized results if there are no longer any active shared test fixtures.
            reportFinalizedResultsForSharedTestFixtures(runner);
        end

        function removeFixture(runner, role, idx)
            role.deleteFixture;
            runner.ActiveFixtures(idx) = [];
        end

        function teardownUserFixture(runner, role)
            import matlab.unittest.plugins.plugindata.SharedTestFixturePluginData;

            fixture = role.Instance;
            fixtureClass = metaclass(fixture);
            role.DetailsLocationProvider.supplyEndIndex(runner.TestRunData.CurrentIndex);
            runner.PluginData.teardownSharedTestFixture = ...
                SharedTestFixturePluginData(fixtureClass.Name, fixture.TeardownDescription, ...
                fixture, runner.TestRunData, role.DetailsLocationProvider);
            fixture.enableQualifications_;
            [plugin, iter] = runner.prepareToEvaluateMethodOnPlugins("teardownSharedTestFixture");
            try
                plugin.teardownSharedTestFixture(runner.PluginData.teardownSharedTestFixture);
            catch exception
                plugin.handlePluginException_(exception, "teardownSharedTestFixture", runner.PluginData.teardownSharedTestFixture, iter);
            end
            runner.completePluginMethodEvaluation("teardownSharedTestFixture");
            delete(runner.PluginData.teardownSharedTestFixture);
        end

        function teardownClassLevelTestCase(runner)
            % We may have reached here due to an error while creating a
            % class level testcase instance. In that case, we don't need to
            % go through the teardown process at all.
            if ~isempty(runner.ClassLevelStruct.TestCase)
                % Update results in the event of Ctrl-C
                resultReporter = matlab.unittest.internal.CancelableCleanup(@runner.recordInterruptedSharedTestCase);

                runner.PluginData.teardownTestClass = runner.PluginData.setupTestClass;
                c = matlab.unittest.internal.Teardownable;
                c.addTeardown(@()cleanupTestClass(runner));
                [plugin, iter] = runner.prepareToEvaluateMethodOnPlugins("teardownTestClass");
                try
                    plugin.teardownTestClass(runner.PluginData.teardownTestClass);
                catch exception
                    plugin.handlePluginException_(exception, "teardownTestClass", runner.PluginData.teardownTestClass, iter);
                end
                runner.completePluginMethodEvaluation("teardownTestClass");
                delete(c);

                resultReporter.cancel;
            end

            % Results can be finalized at the class level if there are no active shared test fixtures.
            if ~runner.ActiveFixtures.hasUserFixtureSetUpByRunner
                runner.reportFinalizedResultThroughCurrentIndex;
            end
        end

        function deleteCurrentMethodLevelTestCase(runner)
            runner.executeTeardownThroughPluginsFor(runner.CurrentMethodLevelTestCase);
            delete(runner.CurrentMethodLevelTestCase);
        end

        function deleteCurrentRepeatLoopTestCase(runner)
            delete(runner.RepeatLoopTestCase);
        end

        function finalizeResultsAtMethodLevelIfNeeded(runner)
            % Results can be finalized at the method level if there are no
            % TestClassSetup and TestClassTeardown methods in the TestClass, there are
            % no QualifyingPlugins, and there are no active shared test fixtures.
            if ~runner.OperatorList.HasQualifyingPlugin && ...
                    ~runner.ActiveFixtures.hasUserFixtureSetUpByRunner && ...
                    isempty(runner.ClassLevelStruct.TestClassSetupMethods) && ...
                    isempty(runner.ClassLevelStruct.TestClassTeardownMethods) && ...
                    runner.TestRunData.HasCompletedTestRepetitions
                runner.reportFinalizedResultThroughCurrentIndex;
            end
        end

        function reportFinalizedResultThroughCurrentIndex(runner)
            import matlab.unittest.plugins.plugindata.FinalizedResultPluginData;

            [runner.TestRunData.TestResult(runner.FinalizedResultReportedIndex+1:runner.TestRunData.CurrentIndex).Finalized] = deal(true);
            if runner.OperatorList.hasPluginThatImplements("reportFinalizedResult")
                while runner.FinalizedResultReportedIndex < runner.TestRunData.CurrentIndex
                    runner.FinalizedResultReportedIndex = runner.FinalizedResultReportedIndex + 1;
                    suite = runner.TestRunData.TestSuite(runner.FinalizedResultReportedIndex);
                    finalizedResult = runner.TestRunData.TestResult(runner.FinalizedResultReportedIndex);
                    runner.PluginData.reportFinalizedResult = FinalizedResultPluginData( ...
                        finalizedResult.Name, runner.FinalizedResultReportedIndex, suite, finalizedResult);
                    plugin = runner.prepareToEvaluateMethodOnPlugins("reportFinalizedResult");
                    plugin.reportFinalizedResult(runner.PluginData.reportFinalizedResult);
                    runner.completePluginMethodEvaluation("reportFinalizedResult");
                    delete(runner.PluginData.reportFinalizedResult);
                end
            else
                runner.FinalizedResultReportedIndex = runner.TestRunData.CurrentIndex;
            end
        end

        function recordSharedTestFixtureFailure(runner, property, locationProvider, marker)
            runner.LastQualificationFailedExceptionMarker = marker;
            [runner.TestRunData.TestResult(locationProvider.ActiveAffectedIndices).(property)] = deal(true);
        end

        function recordVerificationFailureForPluginVerificationValidation(runner, property)
            if property == "VerificationFailed" && ~runner.OperatorList.HasQualifyingPlugin
                runner.VerificationFailureRecorded = true;
            end
        end

        function recordSharedTestCaseFailure(runner, property, marker)
            % Apply the failure results from setting up or tearing down a shared test case.
            runner.LastQualificationFailedExceptionMarker = marker;
            [runner.PluginData.runSharedTestCase.TestResult.(property)] = deal(true);
            runner.recordVerificationFailureForPluginVerificationValidation(property);
        end

        function recordTestRepeatLoopFailure(runner, property, marker)
            % Apply the failure results from setting up or tearing down a test repeat loop.
            runner.LastQualificationFailedExceptionMarker = marker;
            idx = runner.PluginData.runSharedTestCase.CurrentIndex;
            runner.PluginData.runSharedTestCase.TestResult(idx).(property) = true;
            runner.recordVerificationFailureForPluginVerificationValidation(property);
        end

        function recordTestMethodFailure(runner, property, marker)
            % Apply the failure results from a single test method (includes
            % test method setup, the test method itself, and test method teardown).
            runner.LastQualificationFailedExceptionMarker = marker;
            runner.TestRunData.CurrentResult.(property) = true;
            runner.recordVerificationFailureForPluginVerificationValidation(property);
        end

        function recordInterruptedTest(runner)
            runner.TestRunData.CurrentResult.Interrupted = true;
        end
        function recordInterruptedSharedTestCase(runner)
            [runner.PluginData.runSharedTestCase.TestResult.Interrupted] = deal(true);
        end
        function recordInterruptedFixture(runner, locationProvider)
            [runner.TestRunData.TestResult(locationProvider.ActiveAffectedIndices).Interrupted] = deal(true);
        end

        function validateNoVerificationsInPlugins(runner, methodName)
            % Prohibit verification failures in non-QualifyingPlugins. Ideally we would
            % always prohibit such qualifications, but for simplicity and performance,
            % we only enforce this condition when no QualifyingPlugins are installed.
            if runner.VerificationFailureRecorded
                error(message("MATLAB:unittest:TestRunner:VerificationFailureInPlugin", methodName));
            end
        end

        function evaluateMethodsOnTestContent(runner, methods, content)
            % Run methods on test content and handle any exceptions.

            import matlab.unittest.plugins.plugindata.MethodEvaluationPluginData;

            usePlugins = runner.OperatorList.hasPluginThatImplements("evaluateMethod");

            for idx = numel(methods):-1:1
                method = methods(idx);
                arguments = runner.TestRunData.CurrentSuite.Parameterization.getInputsFor(method);

                if usePlugins
                    % Determine the name for evaluateMethod
                    if isa(content, 'matlab.unittest.FunctionTestCase') && method.Test
                        name = runner.TestRunData.CurrentSuite.ProcedureName;
                    else
                        name = method.Name;
                    end

                    runner.PluginData.evaluateMethod = MethodEvaluationPluginData(name, false, method, content, arguments);
                    plugin = runner.prepareToEvaluateMethodOnPlugins("evaluateMethod");
                    try
                        plugin.evaluateMethod(runner.PluginData.evaluateMethod);
                    catch exception
                        runner.handlePluginExceptionInProhibitedScope(exception, "evaluateMethod");
                    end
                    runner.completePluginMethodEvaluation("evaluateMethod");
                    delete(runner.PluginData.evaluateMethod);
                else
                    runner.evaluateMethodCore(method, content, arguments);
                end
            end
        end

        function executeTeardownThroughPluginsFor(runner, content)
            content.runAllTeardownThroughProcedure_( ...
                @(varargin)runner.evaluateTeardownMethodOnPlugins(content, varargin{:}));
        end

        function evaluateTeardownMethodOnPlugins(runner, content, fcn, varargin)
            import matlab.unittest.plugins.plugindata.MethodEvaluationPluginData;

            method = runner.identifyMetaMethod(metaclass(content), func2str(fcn));
            name = method.Name;

            if runner.OperatorList.hasPluginThatImplements("evaluateMethod")
                % Determine the name for evaluateMethod plugin data
                addedTeardown = strcmp(name, 'runTeardown');
                if addedTeardown
                    name = func2str(varargin{1});
                end

                runner.PluginData.evaluateMethod = MethodEvaluationPluginData(name, addedTeardown, method, content, varargin);
                plugin = runner.prepareToEvaluateMethodOnPlugins("evaluateMethod");
                plugin.evaluateMethod(runner.PluginData.evaluateMethod);
                runner.completePluginMethodEvaluation("evaluateMethod");
                delete(runner.PluginData.evaluateMethod);
            else
                runner.evaluateMethodCore(method, content, varargin);
            end
        end

        function deletePluginData(runner)
            structfun(@delete, runner.PluginData)
        end

        function deleteTestRunData(runner)
            arrayfun(@delete, runner.TestRunData)
        end

        function evaluateMethodCore(runner, method, content, arguments)
            % Run a method and record its duration.

            import matlab.unittest.internal.LabelEventData;
            import matlab.unittest.internal.qualifications.QualificationFailedExceptionMarker;

            % fire start/stop events if this is a test method
            if isa(method,"matlab.unittest.meta.method") && method.Test && ...
                    (event.hasListener(content, "MeasurementStarted") || event.hasListener(content, "MeasurementStopped"))
                notifyStart = @()content.notify("MeasurementStarted",LabelEventData('_implicit'));
                notifyStop = @()content.notify("MeasurementStopped",LabelEventData('_implicit'));
            else
                notifyStart = @()[];
                notifyStop = @()[];
            end

            func = str2func(method.Name);
            try
                % get the tic/toc as close as possible to the content
                if isempty(arguments)
                    notifyStart();
                    t0 = tic;
                    func(content);
                    duration = toc(t0);
                    notifyStop();
                else
                    notifyStart();
                    t0 = tic;
                    func(content, arguments{:});
                    duration = toc(t0);
                    notifyStop();
                end
                runner.TestRunData.addDurationToCurrentResult(duration);
            catch exception
                duration = toc(t0);
                notifyStop();
                runner.TestRunData.addDurationToCurrentResult(duration);

                if metaclass(exception) <= ?matlab.unittest.qualifications.FatalAssertionFailedException
                    runner.rethrowException(exception);
                elseif ~runner.isQualificationFailedExceptionFromCorrectQualifiable(exception)
                    content.notifyExceptionThrownEvent_(exception,runner.DiagnosticData);
                    
                    qualifiable = content;
                    if isa(content, "matlab.unittest.fixtures.Fixture")
                        qualifiable = qualifiable.Qualifiable;
                    end
                    qualifiable.invokePostFailureEventCallbacks_(struct( ...
                        "Type","Errored", "Marker",QualificationFailedExceptionMarker));
                end
            end

        end

        function runTestCore(runner)
            import matlab.unittest.plugins.plugindata.TestContentCreationPluginData;
            import matlab.unittest.plugins.plugindata.ImplicitFixturePluginData;
            import matlab.unittest.plugins.plugindata.RunPluginData;
            import matlab.unittest.internal.plugins.DeterminedDetailsLocationProvider;

            % Update results in the event of Ctrl-C
            resultReporter = matlab.unittest.internal.CancelableCleanup(@runner.recordInterruptedTest);

            detailsLocationProvider = DeterminedDetailsLocationProvider(runner.TestRunData.CurrentIndex, runner.TestRunData.CurrentIndex);

            % Create method level testcase
            if runner.OperatorList.hasPluginThatImplements("createTestMethodInstance")
                runner.PluginData.createTestMethodInstance = TestContentCreationPluginData( ...
                    runner.TestRunData.CurrentResult.Name, runner.TestRunData, detailsLocationProvider, ForLeafResult=true);
                plugin = runner.prepareToEvaluateMethodOnPlugins("createTestMethodInstance");
                try
                    runner.CurrentMethodLevelTestCase = plugin.createTestMethodInstance(runner.PluginData.createTestMethodInstance);
                catch exception
                    runner.handlePluginExceptionInProhibitedScope(exception, "createTestMethodInstance");
                end
                runner.completePluginMethodEvaluation("createTestMethodInstance");
                delete(runner.PluginData.createTestMethodInstance);
            else
                runner.CurrentMethodLevelTestCase = runner.createTestMethodInstanceCore;
            end

            % Teardown current method level testcase
            cleanup = matlab.unittest.internal.CancelableCleanup(@runner.deleteCurrentMethodLevelTestCase);

            % Evaluate setup test method
            runner.PluginData.setupTestMethod = ImplicitFixturePluginData(runner.TestRunData.CurrentResult.Name,...
                runner.CurrentMethodLevelTestCase, runner.TestRunData, detailsLocationProvider, ForLeafResult=true, LegacyName = runner.TestRunData.CurrentSuite.LegacyName);
            [plugin, iter] = runner.prepareToEvaluateMethodOnPlugins("setupTestMethod");
            try
                plugin.setupTestMethod(runner.PluginData.setupTestMethod);
            catch exception
                plugin.handlePluginException_(exception, "setupTestMethod", runner.PluginData.setupTestMethod, iter);
            end
            runner.completePluginMethodEvaluation("setupTestMethod");

            % Only run if we have completed our fixture setup
            if ~runner.TestRunData.CurrentResult.Incomplete
                if runner.OperatorList.hasPluginThatImplements("runTestMethod")
                    % Run the Test method.
                    runner.PluginData.runTestMethod = RunPluginData( ...
                        runner.TestRunData.CurrentResult.Name, runner.TestRunData, runner.TestRunData.CurrentIndex, ForLeafResult=true);
                    plugin = runner.prepareToEvaluateMethodOnPlugins("runTestMethod");
                    try
                        plugin.runTestMethod(runner.PluginData.runTestMethod);
                    catch exception
                        runner.handlePluginExceptionInProhibitedScope(exception, "runTestMethod");
                    end
                    runner.completePluginMethodEvaluation("runTestMethod");
                    delete(runner.PluginData.runTestMethod);
                else
                    runner.runTestMethodCore;
                end
            end

            % Tear down the fresh fixture.
            runner.PluginData.teardownTestMethod = runner.PluginData.setupTestMethod;
            [plugin, iter] = runner.prepareToEvaluateMethodOnPlugins("teardownTestMethod");
            try
                plugin.teardownTestMethod(runner.PluginData.teardownTestMethod);
            catch exception
                plugin.handlePluginException_(exception, "teardownTestMethod", runner.PluginData.teardownTestMethod, iter);
            end
            runner.completePluginMethodEvaluation("teardownTestMethod");
            delete(runner.PluginData.teardownTestMethod);

            cleanup.cancelAndInvoke;

            resultReporter.cancel;
        end

        function runTestMethodCore(runner)
            runner.TestRunData.CurrentResult.Started  = true;
            testCase = runner.CurrentMethodLevelTestCase;
            testMethodName = runner.TestRunData.CurrentSuite.TestMethodName;
            if ~isKey(runner.ClassLevelStruct.TestMethods,testMethodName)
                error(message('MATLAB:unittest:TestRunner:UnableToFindTestMethod', testMethodName, class(testCase)));
            end
            method = runner.ClassLevelStruct.TestMethods(testMethodName);
            runner.evaluateMethodsOnTestContent(method, testCase);
        end

        function testCase = createTestClassInstanceCore(runner)
            import matlab.unittest.internal.AddVerificationEventDecorator;
            import matlab.unittest.internal.DeferredTask;

            % Create a class-level TestCase instance
            testCase = runner.TestRunData.CurrentSuite.provideClassTestCase;
            testCase.DiagnosticData = runner.DiagnosticData;
            runnerWeakRef = matlab.lang.WeakReference(runner);
            testCase.addPostFailureEventCallback_(@(info)runnerWeakRef.Handle.recordSharedTestCaseFailure(info.Type, info.Marker));
            testCase.onFailure(AddVerificationEventDecorator(DeferredTask(@()runner.ActiveFixtures.getAdditionalOnFailureTasks)));
            testCase.SharedTestFixtures_ = runner.ActiveFixtures.getUserVisibleFixtures;
        end

        function testCase = createTestMethodInstanceCore(runner)
            % Create the testCase instance from the class level prototype
            testCase = runner.TestRunData.CurrentSuite.createTestCaseFromClassPrototype(runner.RepeatLoopTestCase);
            testCase.addPostFailureEventCallback_(@(info)runner.recordTestMethodFailure(info.Type, info.Marker));
        end

        function testCase = createTestRepeatLoopInstanceCore(runner)
            testCase = runner.TestRunData.CurrentSuite.createTestCaseFromClassPrototype(runner.ClassLevelStruct.TestCase);
            testCase.addPostFailureEventCallback_(@(info)runner.recordTestRepeatLoopFailure(info.Type, info.Marker));
        end

        function bool = isQualificationFailedExceptionFromCorrectQualifiable(runner, exception)
            bool = (metaclass(exception) <= ?matlab.unittest.internal.qualifications.QualificationFailedException) && ...
                runner.wasQualificationFailedExceptionThrownByCorrectQualifiable_(exception);
        end

        function cleanupTestClass(runner)
            runner.executeTeardownThroughPluginsFor(runner.ClassLevelStruct.TestCase);
            delete(runner.ClassLevelStruct.TestCase);
            runner.ClassLevelStruct.TestCase = [];
            delete(runner.PluginData.teardownTestClass);
        end

        function plugin = createDiagnosticsOutputPlugin(~, namedargs)
            import matlab.unittest.plugins.DiagnosticsOutputPlugin;
            if isfield(namedargs, "Verbosity") % Map Verbosity to LoggingLevel for backward compatibility
                if ~isfield(namedargs, "LoggingLevel")
                    namedargs.LoggingLevel = namedargs.Verbosity;
                end
                namedargs = rmfield(namedargs, "Verbosity");
            end
            args = namedargs2cell(namedargs);
            plugin = DiagnosticsOutputPlugin(args{:});
        end

        function plugin = createTestRunProgressPlugin(~, namedargs)
            import matlab.automation.Verbosity;
            import matlab.unittest.plugins.TestRunProgressPlugin;
            if isfield(namedargs, "OutputDetail")
                progressVerbosity = namedargs.OutputDetail;
            elseif isfield(namedargs, "Verbosity") % for backward compatibility
                progressVerbosity = namedargs.Verbosity;
            else
                progressVerbosity = Verbosity.Concise;
            end
            plugin = TestRunProgressPlugin.withVerbosity(progressVerbosity);
        end
        
        function registerTeardownMethods(~, content, methods)
            import matlab.unittest.internal.TeardownElement;

            for idx = 1:numel(methods)
                content.addTeardown(TeardownElement(str2func(methods(idx).Name), {}));
            end
        end

        function metaMethod = identifyMetaMethod(~, metaClass, name)
            metaMethod = findobj(metaClass.MethodList, 'Name', name);
        end
        
        function endIndex = calculateSubsuiteWithinSharedTestCaseBoundary(~, suite, startIdx)
            % Calculate the subsuite of tests have the same class setup parameterization.

            endIndex = startIdx;
            while endIndex < numel(suite) && hasSameClassSetupParameters(suite, endIndex, endIndex+1)
                endIndex = endIndex + 1;
            end

            function bool = hasSameClassSetupParameters(suite, idx1, idx2)
                getClassSetupParameterNames = @(suite){suite.Parameterization.filterByType().Name};
                bool = isequal(getClassSetupParameterNames(suite(idx1)), getClassSetupParameterNames(suite(idx2)));
            end
        end

        function fixtures = getNextSharedFixtures(runner, suite, index)
            % Return the shared fixtures needed for suite(index+1)

            import matlab.unittest.fixtures.EmptyFixture;

            if index < numel(suite)
                fixtures = runner.getAllSharedFixturesForSuite(suite(index+1));
            else
                % No fixtures required beyond last suite element
                fixtures = EmptyFixture.empty;
            end
        end

        function fixtures = getAllSharedFixturesForSuite(~, suite)
            fixtures = [suite.SharedTestFixtures, suite.InternalSharedTestFixtures];
        end

        function rethrowException(~, exception)
            % Rethrow an exception without debugging it.
            cleaner = matlab.unittest.internal.setStopIfCaughtErrorInTestRunner(false); %#ok<NASGU> 
            rethrow(exception);
        end
    end

    methods (Hidden, Access=?matlab.unittest.plugins.TestRunnerPlugin)
        function bool = wasQualificationFailedExceptionThrownByCorrectQualifiable_(runner, exception)
            bool = exception.QualificationFailedExceptionMarker == runner.LastQualificationFailedExceptionMarker;
        end
    end

    methods (Access=private)
        function beginPluginMethod(runner, methodName, pluginData)
            % Validate that the plugin data made its way back to TestRunner
            % after going through all the plugins.
            if runner.PluginData.(methodName) ~= pluginData
                error(message("MATLAB:unittest:TestRunner:PluginDataMismatch", methodName));
            end

            runner.validateNoVerificationsInPlugins(methodName);
        end

        function completePluginMethod(runner)
            runner.PluginsInvokedRunnerContent = true;
            runner.VerificationFailureRecorded = false;
        end
    end

    methods(Hidden, Access=protected) % conform to TestContentOperator API
        function runSession(runner, pluginData)
            runner.beginPluginMethod("runSession", pluginData);

            % set worker ID for parallelizable plugins
            plugins = runner.OperatorList.Plugins;
            for idx = 1:numel(plugins)
                plugins{idx}.setIdentifier(-idx);
            end

            runner.TestRunStrategy.runSession(runner,pluginData);

            runner.completePluginMethod;
        end

        function runTestSuite(runner, pluginData)
            import matlab.unittest.internal.createConditionallyKeptFolderEnvironment;
            import matlab.unittest.fixtures.EmptyFixture;
            import matlab.unittest.plugins.plugindata.RunPluginData;

            runner.beginPluginMethod("runTestSuite", pluginData);

            env = runner.TestRunStrategy.createArtifactsStorageFolder(runner.TestRunData.RunIdentifier); %#ok<NASGU>

            % No results have been reported yet.
            runner.FinalizedResultReportedIndex = 0;

            % For exception safety, tear down any fixtures active at the
            % time of a fatal assertion failure.
            teardownFixtures = matlab.unittest.internal.Teardownable;
            teardownFixtures.addTeardown(@teardownAllSharedFixturesExcluding, ...
                runner, matlab.unittest.fixtures.Fixture.empty);

            % Get the initial test suite from plugin data
            suite = pluginData.TestSuite;

            runner.TestRunData.CurrentIndex = 0;
            while runner.TestRunData.CurrentIndex < numel(suite)
                runner.TestRunData.CurrentIndex = runner.TestRunData.CurrentIndex + 1;

                % Set up any required fixtures that aren't already set up.
                runner.prepareSharedTestFixtures();

                % If shared test fixture is incomplete, we don't run the tests
                % that are under that shared test fixture umbrella. We do,
                % however, tear down any unneeded shared test fixtures.
                if runner.TestRunData.CurrentResult.Incomplete
                    fixtureFailureRange = find([runner.TestRunData.TestResult(runner.TestRunData.CurrentIndex:end).Incomplete], 1, 'last');
                    runner.TestRunData.CurrentIndex = runner.TestRunData.CurrentIndex + fixtureFailureRange - 1;
                else
                    suiteEndIdx = runner.determineClassEndIndex;
                    runner.PluginData.runTestClass = RunPluginData( ...
                        runner.TestRunData.CurrentSuite.TestParentName, runner.TestRunData, suiteEndIdx);
                    plugin = runner.prepareToEvaluateMethodOnPlugins("runTestClass");
                    plugin.runTestClass(runner.PluginData.runTestClass);
                    runner.completePluginMethodEvaluation("runTestClass");
                    delete(runner.PluginData.runTestClass);
                end

                % Tear down fixtures that are no longer needed.
                runner.teardownAllSharedFixturesExcluding(runner.getNextSharedFixtures(suite, runner.TestRunData.CurrentIndex));
                [currentResetStatus, fixtureIdx] = getFixtureResetStatus(runner.ActiveFixtures);
                if(currentResetStatus)
                    count = numel(runner.ActiveFixtures);
                    for idx = count:-1:fixtureIdx
                        performTeardownOnSharedTestFixturesAtTopOfStack(runner, idx);
                    end
                    reportFinalizedResultsForSharedTestFixtures(runner);
                end
            end

            runner.completePluginMethod;
        end

        function fixture = createSharedTestFixture(runner, pluginData)
            import matlab.unittest.internal.qualifications.QualificationFailedExceptionMarker;
            import matlab.unittest.internal.DeferredTask;

            runner.beginPluginMethod("createSharedTestFixture", pluginData);

            fixture = copy(runner.SharedTestFixtureToSetup.Instance);
            fixture.Qualifiable.DiagnosticData = runner.DiagnosticData;

            locationProvider = pluginData.DetailsLocationProvider;
            fixture.addPostFailureEventCallback_(@(info)runner.recordSharedTestFixtureFailure(info.Type, locationProvider, info.Marker));
            fixture.transferOnFailureTasks_(DeferredTask(@()runner.ActiveFixtures.getAdditionalFixtureOnFailureTasks(fixture)));

            runner.completePluginMethod;
        end

        function setupSharedTestFixture(runner, pluginData)
            runner.beginPluginMethod("setupSharedTestFixture", pluginData);

            if ~runner.TestRunData.CurrentResult.Incomplete
                fixture = pluginData.Fixture;
                fixtureClass = metaclass(fixture);

                setupMethod = runner.identifyMetaMethod(fixtureClass, 'setup');
                runner.evaluateMethodsOnTestContent(setupMethod, fixture);

                % Update the description which the fixture may have set during setup
                runner.PluginData.setupSharedTestFixture.Description = fixture.SetupDescription;

                teardownMethod = runner.identifyMetaMethod(fixtureClass, 'teardown');
                runner.registerTeardownMethods(fixture, teardownMethod);
            end

            runner.completePluginMethod;
        end

        function runTestClass(runner, pluginData)
            import matlab.unittest.plugins.plugindata.RunPluginData;

            runner.beginPluginMethod("runTestClass", pluginData);

            % Get the subsuite from plugin data
            suite = pluginData.TestSuite;

            startIdx = runner.TestRunData.CurrentIndex;
            pluginData.CurrentIndex = 0;
            while pluginData.CurrentIndex < numel(suite)
                pluginData.CurrentIndex = pluginData.CurrentIndex + 1;

                % Calculate the subsuite within the shared test case boundary -
                % this includes all tests that belong to the same test class
                % and have same class setup parameterization.
                suiteEndIdx = runner.calculateSubsuiteWithinSharedTestCaseBoundary(suite, pluginData.CurrentIndex);
                runner.PluginData.runSharedTestCase = RunPluginData( ...
                    '', runner.TestRunData, startIdx+suiteEndIdx-1);
                runner.runSharedTestCase(runner.PluginData.runSharedTestCase);
                delete(runner.PluginData.runSharedTestCase);
            end

            runner.completePluginMethod;
        end

        function testCase = createTestClassInstance(runner, pluginData)
            runner.beginPluginMethod("createTestClassInstance", pluginData);
            testCase = runner.createTestClassInstanceCore;
            runner.completePluginMethod;
        end

        function setupTestClass(runner, pluginData)
            runner.beginPluginMethod("setupTestClass", pluginData);

            if ~runner.TestRunData.CurrentResult.Incomplete
                testCase = runner.ClassLevelStruct.TestCase;
                runner.evaluateMethodsOnTestContent(runner.ClassLevelStruct.TestClassSetupMethods, testCase);
                runner.registerTeardownMethods(testCase, runner.ClassLevelStruct.TestClassTeardownMethods);
            end

            runner.completePluginMethod;
        end

        function testCase = createTestRepeatLoopInstance(runner, pluginData)
            runner.beginPluginMethod("createTestRepeatLoopInstance", pluginData);
            testCase = runner.createTestRepeatLoopInstanceCore;
            runner.completePluginMethod;
        end

        function runTest(runner, pluginData)
            runner.beginPluginMethod("runTest", pluginData);
            runner.runTestCore;
            runner.completePluginMethod;
        end

        function testCase = createTestMethodInstance(runner, pluginData)
            runner.beginPluginMethod("createTestMethodInstance", pluginData);
            testCase = runner.createTestMethodInstanceCore;
            runner.completePluginMethod;
        end

        function setupTestMethod(runner, pluginData)
            runner.beginPluginMethod("setupTestMethod", pluginData);

            if ~runner.TestRunData.CurrentResult.Incomplete
                testCase = runner.CurrentMethodLevelTestCase;
                runner.evaluateMethodsOnTestContent(runner.ClassLevelStruct.TestMethodSetupMethods, testCase);
                runner.registerTeardownMethods(testCase, runner.ClassLevelStruct.TestMethodTeardownMethods);
            end

            runner.completePluginMethod;
        end

        function runTestMethod(runner, pluginData)
            runner.beginPluginMethod("runTestMethod", pluginData);
            runner.runTestMethodCore;
            runner.completePluginMethod;
        end

        function evaluateMethod(runner, pluginData)
            runner.beginPluginMethod("evaluateMethod", pluginData);
            runner.evaluateMethodCore(pluginData.Method, pluginData.Content, pluginData.Arguments);
            runner.completePluginMethod;
        end

        function teardownTestMethod(runner, pluginData)
            runner.beginPluginMethod("teardownTestMethod", pluginData);
            runner.executeTeardownThroughPluginsFor(runner.CurrentMethodLevelTestCase);
            runner.completePluginMethod;
        end

        function teardownTestRepeatLoop(runner, pluginData)
            runner.beginPluginMethod("teardownTestRepeatLoop", pluginData);
            runner.executeTeardownThroughPluginsFor(runner.RepeatLoopTestCase);
            runner.completePluginMethod;
        end

        function teardownTestClass(runner, pluginData)
            runner.beginPluginMethod("teardownTestClass", pluginData);
            runner.executeTeardownThroughPluginsFor(runner.ClassLevelStruct.TestCase);
            runner.completePluginMethod;
        end

        function teardownSharedTestFixture(runner, pluginData)
            runner.beginPluginMethod("teardownSharedTestFixture", pluginData);

            fixture = pluginData.Fixture;
            runner.executeTeardownThroughPluginsFor(fixture);

            % Update the description which the fixture may have set during teardown
            runner.PluginData.teardownSharedTestFixture.Description = fixture.TeardownDescription;

            runner.completePluginMethod;
        end

        function reportFinalizedResult(runner, pluginData)
            runner.beginPluginMethod("reportFinalizedResult", pluginData);
            % Runner does nothing
            runner.completePluginMethod;
        end

        function reportFinalizedSuite(runner, pluginData)
            runner.beginPluginMethod("reportFinalizedSuite", pluginData);
            % Runner does nothing
            runner.completePluginMethod;
        end
    end

    methods (Hidden)
        function serialized = saveobj(runner)
            serialized.PrebuiltFixtures = runner.PrebuiltFixtures;
            serialized.Plugins = runner.Plugins;
            serialized.TestRunStrategy = runner.TestRunStrategy;
            serialized.Version = 'R2020b';
        end
    end

    methods (Hidden, Static)
        function runner = loadobj(savedRunner)
            import matlab.unittest.TestRunner;

            % Prior to R2019b, the matlab.unittest.TestRunner class did not
            % have a TestRunStrategy property. From R2020b, this property
            % needs to be copied over when the TestRunner instance is
            % serialized when running tests in parallel.
            args = {};
            if isfield(savedRunner,'TestRunStrategy')
                args = {savedRunner.TestRunStrategy};
            end

            % Create a new runner and copy over the necessary state.
            runner = TestRunner(args{:});

            runner.PrebuiltFixtures = savedRunner.PrebuiltFixtures;

            if isfield(savedRunner,'ArtifactsRootFolder')
                runner.ArtifactsRootFolder = savedRunner.ArtifactsRootFolder;
            end

            for idx = 1:numel(savedRunner.Plugins)
                runner.addPlugin(savedRunner.Plugins(idx));
            end
        end
    end
end

% LocalWords:  mynamespace func Teardownable tmp Prebuilt prebuilt cls evd CPROP namedargs
% LocalWords:  mynamespace func Teardownable plugindata subsuite teardownable
% LocalWords:  teardownable's RUNREPEATEDLY NUMREPETITIONS EARLYTERMINATEFCN
% LocalWords:  ADifferent subfolders subfolder df dbe env AWritable Cancelable
% LocalWords:  unittest Plugins plugins Teardown LOGGINGLEVEL OUTPUTDETAIL
% LocalWords:  Getters teardown Qualifiable UUID parallelizable
