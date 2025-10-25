classdef TestTask < ...
        matlab.buildtool.Task & ...
        matlab.buildtool.internal.tasks.TestTaskExtension
    % TestTask - Task to run tests
    %
    %   The matlab.buildtool.tasks.TestTask class provides a task to run a
    %   suite of tests.
    %
    %   TestTask properties:
    %       Tests                - Tests to run
    %       SourceFiles          - Source files and folders under test
    %       SupportingFiles      - Supporting files and folders used by tests
    %       IncludeSubfolders    - Whether to run tests in subfolders
    %       Tag                  - Name of tag
    %       Selector             - Test selector
    %       RunOnlyImpactedTests - Option to run only impacted tests
    %       OutputDetail         - Display level for event details
    %       LoggingLevel         - Maximum verbosity level for logged diagnostics
    %       Strict               - Whether to apply strict checks
    %       TestResults          - Results of running tests
    %       CodeCoverageResults  - Results of collecting code coverage
    %       ModelCoverageResults - Results of collecting model coverage
    %
    %   TestTask methods:
    %       TestTask - Class constructor
    %
    %   Examples:
    %
    %       % Import the TestTask class
    %       import matlab.buildtool.tasks.TestTask
    %
    %       % Create a task to run the tests in your current folder and its
    %       % subfolders
    %       task = TestTask();
    %
    %       % Create a task to run the tests in a folder that have the
    %       % "featureA" tag
    %       task = TestTask("myTestFolder",IncludeSubfolders=false,Tag="featureA");
    %
    %       % Create a task to run a test file at the "detailed" verbosity level
    %       task = TestTask("myTestFile.m",LoggingLevel="detailed",OutputDetail="detailed");
    %
    %       % Create a task to run the test files that match a pattern
    %       task = TestTask("myTestFolder/*Test.m");
    %
    %       % Create a task to produce test results in JUnit-style XML format
    %       task = TestTask("myTestFolder",TestResults="test-results/results.xml");
    %
    %       % Create a task to produce JUnit-style test results as well as a PDF report
    %       task = TestTask("myTestFolder",TestResults=["test-results/results.xml" "test-results/report.pdf"]);
    %
    %       % Create a task to export Simulink Test Manager results in MLDATX format
    %       task = TestTask("myTestFolder",TestResults="test-results/results.mldatx");
    %
    %       % Create a task to produce code coverage results in Cobertura
    %       % XML format for the specified source code
    %       task = TestTask("myTestFolder",SourceFiles="sourceFolder",CodeCoverageResults="code-coverage/coverage.xml");
    %
    %       % Create a task to produce code coverage results in both
    %       % Cobertura XML and HTML formats
    %       task = TestTask("myTestFolder",SourceFiles="sourceFolder",CodeCoverageResults=["code-coverage/coverage.xml" "code-coverage/html/index.html"]);
    %
    %       % Create a task to save the code coverage results to a MAT-file
    %       % for programmatic access
    %       task = TestTask("myTestFolder",SourceFiles="sourceFolder",CodeCoverageResults="code-coverage/coverage.mat");
    %
    %       % Create a task to produce model coverage results in Cobertura
    %       % XML format for models defined in Simulink tests of the
    %       % specified test folder
    %       task = TestTask("myTestFolder",ModelCoverageResults="model-coverage/coverage.xml");
    %
    %       % Create a task to produce model coverage results in both Cobertura XML
    %       % and HTML formats
    %       task = TestTask("myTestFolder",ModelCoverageResults=["model-coverage/coverage.xml" "model-coverage/report.html"]);
    %
    %       % Create a task to run tests selected using a selector
    %       % import matlab.unittest.selectors.HasTag
    %       % import matlab.unittest.constraints.ContainsSubstring
    %       task = TestTask(Selector=HasTag(ContainsSubstring("unit")));
    %
    %       % Create a task to run only tests that are impacted by changes 
    %       % since the last successful run
    %       task = TestTask(RunOnlyImpactedTests=true);
    %
    %       % Create a build plan
    %       plan = buildplan();
    %
    %       % Add a "test" task to the plan
    %       plan("test") = TestTask("myTestFolder",SourceFiles="sourceFolder",TestResults="test-results/results.xml",CodeCoverageResults="code-coverage/coverage.xml");
    %
    %       % Run the "test" task
    %       >> buildtool test
    %
    %       % Run tests in parallel
    %       >> buildtool -parallel test
    %
    %       % Run only impacted tests using a task argument
    %       >> buildtool test(RunOnlyImpactedTests=true)
    %   
    %   See also:
    %       runtests
    %       testsuite
    %       matlab.automation.Verbosity

    %   Copyright 2023-2024 The MathWorks, Inc.

    properties (Dependent)
        % Tests - Tests to run
        %
        %   Tests to run, specified as a string vector, character vector,
        %   cell vector of character vectors, or vector of
        %   matlab.buildtool.io.FileCollection objects, and returned as a
        %   row vector of matlab.buildtool.io.FileCollection objects.
        Tests (1,:) matlab.buildtool.io.FileCollection
    end

    properties (TaskInput, Dependent)
        % IncludeSubfolders - Whether to run tests in subfolders
        %
        %   Whether to run the tests in subfolders, specified as a
        %   numeric or logical 1 (true) or 0 (false). By default, the task
        %   runs the tests in subfolders.
        IncludeSubfolders (1,1) logical

        % Tag - Name of tag
        %
        %   Name of tag used by the test, specified as a string vector,
        %   character vector, or cell vector of character vectors.
        Tag (1,:) string

        % Selector - Test selector
        %
        %   Test selector, specified as a
        %   matlab.unittest.selectors.Selector object.
        Selector matlab.unittest.selectors.Selector {mustBeScalarOrEmpty}

        % RunOnlyImpactedTests - Option to run only impacted tests
        %
        %   Option to run only the tests that are impacted by changes since
        %   the last successful run, specified as a numeric or logical 1
        %   (true) or 0 (false). If the value is true, the task runs only
        %   these tests:
        %   
        %       * Modified or new tests
        %       * Tests with a modified test class folder or test superclass
        %       * Tests that depend on modified or new source files
        %       * Tests that depend on modified or new supporting files
        %   
        %   Running only the impacted tests requires MATLAB Test. If you do
        %   not have a MATLAB Test license, the task runs all the tests
        %   regardless of the value of RunOnlyImpactedTests.
        RunOnlyImpactedTests (1,1) logical
    end

    properties (TaskInput, Hidden, Dependent)
        % ExternalParameters - External Parameters to use in tests
        %
        %   External parameters to use in the tests, specified as an array
        %   of matlab.unittest.parameters.Parameter objects. Use this 
        %   property to specify external parameters instead of the existing 
        %   parameters in a parameterized test .
        ExternalParameters (1, :) matlab.unittest.parameters.Parameter
    end

    properties (TaskInput, SetAccess=private, Hidden, Dependent)
        ExternalParameterValues
    end

    properties (TaskInput)
        % SourceFiles - Source files and folders under test
        %
        %   Source files and folders under test, specified as a string
        %   vector, character vector, cell vector of character vectors, or
        %   vector of matlab.buildtool.io.FileCollection objects, and
        %   returned as a row vector of matlab.buildtool.io.FileCollection
        %   objects. Use this argument alongside the CodeCoverageResults
        %   argument to collect code coverage.
        SourceFiles (1,:) matlab.buildtool.io.FileCollection

        % Strict - Whether to apply strict checks
        %
        %   Whether to apply strict checks when running the tests,
        %   specified as numeric or logical 1 (true) or 0 (false). By
        %   default, the task does not apply strict checks.
        Strict (1,1) logical

        % SupportingFiles - Supporting files and folders used by tests
        %
        %   Supporting files and folders used by tests, specified
        %   as a string vector, character vector, cell vector of character
        %   vectors, or vector of matlab.buildtool.io.FileCollection
        %   objects, and returned as a row vector of
        %   matlab.buildtool.io.FileCollection objects. Use this argument
        %   to specify auxiliary files and folders that tests depend on in
        %   addition to SourceFiles.
        SupportingFiles (1,:) matlab.buildtool.io.FileCollection
    end

    properties
        % OutputDetail - Display level for event details
        %
        %   Display level for event details, specified as an integer value
        %   from 0 through 4, or a matlab.automation.Verbosity enumeration
        %   object. Integer values correspond to the members of the
        %   matlab.automation.Verbosity enumeration. By default, the task
        %   displays failing and logged events at the
        %   matlab.automation.Verbosity.Detailed level (level 3) and test
        %   run progress at the matlab.automation.Verbosity.Terse level
        %   (level 1).
        OutputDetail matlab.automation.Verbosity {mustBeScalarOrEmpty}

        % LoggingLevel - Maximum verbosity level for logged diagnostics
        %
        %   Maximum verbosity level for logged diagnostics, specified as an
        %   integer value from 0 through 4, or a
        %   matlab.automation.Verbosity enumeration object. The task
        %   includes diagnostics logged at this level and below. Integer
        %   values correspond to the members of the
        %   matlab.automation.Verbosity enumeration. By default, the task
        %   includes diagnostics logged at the
        %   matlab.automation.Verbosity.Terse level (level 1).
        LoggingLevel matlab.automation.Verbosity {mustBeScalarOrEmpty}
    end

    properties (TaskOutput, SetAccess=private)
        % TestResults - Results of running tests
        %
        %   Results of running the tests, returned as a row vector of
        %   matlab.buildtool.io.File objects. You can set this property
        %   during creation of the task by specifying the TestResults
        %   name-value argument.
        %
        %   See also: matlab.buildtool.tasks.TestTask/TestTask
        TestResults (1,:) matlab.buildtool.io.File
    end

    properties (TaskOutput, Dependent, SetAccess=private)
        % CodeCoverageResults - Results of collecting code coverage
        %
        %   Results of collecting code coverage for the source code defined
        %   in the SourceFiles property, returned as a row vector of
        %   matlab.buildtool.io.File objects. You can set this property by
        %   specifying the CodeCoverageResults name-value argument or
        %   invoking the addCodeCoverage method.
        %
        %   See also:
        %       matlab.buildtool.tasks.TestTask/TestTask
        %       matlab.buildtool.tasks.TestTask/addCodeCoverage
        CodeCoverageResults (1,:) matlab.buildtool.io.File

        % ModelCoverageResults - Results of collecting model coverage
        %
        %   Results of collecting model coverage for models in Simulink(R)
        %   Test(TM) and MATLAB-based Simulink tests of the TESTS property,
        %   returned as a row vector of matlab.buildtool.io.File objects.
        %   You can set this property by specifying the
        %   ModelCoverageResults name-value argument or invoking the
        %   addModelCoverage method. Model coverage analysis requires a
        %   license for Simulink Test and Simulink Coverage.
        %
        %   See also:
        %       matlab.buildtool.tasks.TestTask/TestTask
        %       matlab.buildtool.tasks.TestTask/addModelCoverage
        ModelCoverageResults (1,:) matlab.buildtool.io.File
    end

    properties (TaskInput, Hidden)
        CodeCoverageSettings (1,:) matlab.buildtool.internal.tasks.codecoverage.CodeCoverageSettings
        ModelCoverageSettings (1,:) matlab.buildtool.internal.tasks.modelcoverage.ModelCoverageSettings
    end

    properties (TaskOutput, Hidden, Dependent)
        AdditionalCodeCoverageOutputFiles
    end

    properties (TaskInput, SetAccess=private, Hidden)
        TestDerivatives (1,1) matlab.buildtool.internal.tasks.TestFileDerivatives
    end

    properties (Transient, SetAccess=private, GetAccess=protected, Dependent, Hidden)
        TestSuite (1,:) matlab.unittest.TestSuite
    end

    properties (Constant, Hidden)
        MATFileExtension = ".mat"
        Catalog = "TestTask"
    end

    properties (Dependent, Hidden)
        MATFileTestResult
    end

    properties (SetAccess = immutable, GetAccess = private)
        OutputStream (1,1) matlab.automation.streams.OutputStream = matlab.automation.streams.ToStandardOutput()
    end

    methods
        function task = TestTask(tests, options)
            % TestTask - Class constructor
            %
            %   TASK = matlab.buildtool.tasks.TestTask(TESTS) creates a
            %   task to run the specified tests. You can specify TESTS as a
            %   string vector, character vector, cell vector of character
            %   vectors, or vector of matlab.buildtool.io.FileCollection
            %   objects. By default, the task runs the tests identified in
            %   the current folder and all of its subfolders.
            %
            %   If TESTS includes Simulink(R) Test(TM) based tests, the
            %   task runs those tests and provides access to their
            %   corresponding Test Manager results.
            %
            %   TASK = matlab.buildtool.tasks.TestTask(TESTS,Name=Value)
            %   creates a task with additional options specified by one or
            %   more of these name-value arguments:
            %
            %       * SourceFiles - Source files and folders under test,
            %       specified as a string vector, character vector, cell
            %       vector of character vectors, or vector of
            %       matlab.buildtool.io.FileCollection objects. Use this
            %       argument alongside the CodeCoverageResults
            %       argument to collect code coverage.
            %
            %       * SupportingFiles - Supporting files and folders used
            %       by tests, specified as a string vector, character
            %       vector, cell vector of character vectors, or vector of
            %       matlab.buildtool.io.FileCollection objects. Use this
            %       argument to specify auxiliary files and folders that
            %       tests depend on in addition to SourceFiles.
            %
            %       * IncludeSubfolders - Whether to run the tests in
            %       subfolders, specified as a numeric or logical 1 (true)
            %       or 0 (false). By default, the task runs the tests in
            %       subfolders.
            %
            %       * Tag - Name of tag used by a test, specified as a string
            %       vector, character vector, or cell vector of character
            %       vectors. Use this argument to create a task that filters
            %       tests based on specified tags.
            %
            %       * Selector - Test selector, specified as a
            %       matlab.unittest.selectors.Selector object.
            %
            %       * RunOnlyImpactedTests - Option to run only the tests that
            %       are impacted by changes since the last successful run,
            %       specified as a numeric or logical 1 (true) or 0
            %       (false). If the value is true, the task runs only these
            %       tests:
            %   
            %           * Modified or new tests
            %           * Tests with a modified test class folder or test superclass
            %           * Tests that depend on modified or new source files
            %           * Tests that depend on modified or new supporting files
            %       
            %       Running only the impacted tests requires MATLAB Test.
            %       If you do not have a MATLAB Test license, the task runs
            %       all the tests regardless of the value of
            %       RunOnlyImpactedTests.
            %
            %       * OutputDetail - Display level for event details, specified
            %       as an integer value from 0 through 4, or a
            %       matlab.automation.Verbosity enumeration object. Use
            %       this argument to control the verbosity of information
            %       displayed about failing and logged events from the test
            %       run.
            %
            %       * LoggingLevel - Maximum verbosity level for logged
            %       diagnostics, specified as an integer value from 0
            %       through 4, or a matlab.automation.Verbosity enumeration
            %       object. Use this argument to include diagnostics from
            %       the test run logged at the specified level or below.
            %
            %       * Strict - Whether to apply strict checks when running
            %       tests, specified as numeric or logical 1 (true) or 0
            %       (false). By default, the task does not apply strict
            %       checks when running the tests.
            %
            %       * TestResults - Results of running the tests, specified
            %       as a string vector, character vector, cell vector of
            %       character vectors, or vector matlab.buildtool.io.File
            %       objects. Use this argument to output test results in
            %       the following formats. The task infers formats from
            %       file extension.
            %
            %           * HTML   - Produce an HTML test report.
            %           * PDF    - Produce a PDF test report.
            %           * XML    - Produce test results in JUnit-style XML format.
            %           * MAT    - Store the matlab.unittest.TestResult array in a MAT-file.
            %           * MLDATX - Export Simulink Test Manager results in MLDATX format (requires Simulink(R) Test(TM)).
            %
            %       * CodeCoverageResults - Results of collecting code
            %       coverage for the source code defined in the SourceFiles
            %       property of the task, specified as a string vector,
            %       character vector, cell vector of character vectors, or
            %       vector matlab.buildtool.io.File objects. Use this
            %       argument with the SourceFiles argument to collect
            %       statement and function coverage metrics in various
            %       formats. (For higher-level coverage metrics, use the
            %       addCodeCoverage method instead.) Specify formats by
            %       using file extensions:
            %
            %           * HTML - Produce an HTML coverage report.
            %           * XML  - Produce code coverage results in Cobertura XML format.
            %           * MAT  - Store the matlab.coverage.Result array in a MAT-file.
            %
            %       * ModelCoverageResults - Results of collecting model
            %       coverage for models in Simulink Test and MATLAB-based
            %       Simulink tests of the TESTS property, specified as a
            %       string vector, character vector, cell vector of
            %       character vectors, or vector of
            %       matlab.buildtool.io.File objects. If you have a license
            %       for Simulink Test and Simulink Coverage, you can use
            %       this argument to collect model coverage in various
            %       formats with the coverage options already applied in
            %       Simulink Test. (To customize model coverage options
            %       with the TestTask instance, use the addModelCoverage
            %       method instead.) Specify formats by using the file
            %       extensions:
            %
            %           * HTML - Produce an HTML model coverage report.
            %           * XML  - Produce model coverage results in Cobertura XML format.
            %
            %   Examples:
            %
            %       % Import the TestTask class
            %       import matlab.buildtool.tasks.TestTask
            %
            %       % Create a task to run the tests in your current folder and its
            %       % subfolders
            %       task = TestTask();
            %
            %       % Create a task to run the tests in a folder that have the "featureA" tag
            %       task = TestTask("myTestFolder",IncludeSubfolders=false,Tag="featureA");
            %
            %       % Create a task to run a test file by adding the required
            %       % source code to the path
            %       task = TestTask("someTestFile.m",SourceFiles=fullfile("myFolder","mySrc.m"));
            %
            %       % Create a task to run a test file at the "detailed" verbosity level
            %       task = TestTask("myTestFile.m",LoggingLevel="detailed",OutputDetail="detailed");
            %
            %       % Create a task to run the test files that match a pattern
            %       task = TestTask("myTestFolder/*Test.m");
            %
            %       % Create a task to produce test results in JUnit-style XML format
            %       task = TestTask("myTestFolder",TestResults="test-results/results.xml");
            %
            %       % Create a task to produce JUnit-style test results as well as a PDF report
            %       task = TestTask("myTestFolder",TestResults=["test-results/results.xml" "test-results/report.pdf"]);
            %
            %       % Create a task to export Simulink Test Manager results in MLDATX format
            %       task = TestTask("myTestFolder",TestResults="test-results/results.mldatx");
            %
            %       % Create a task to produce code coverage results in Cobertura XML format
            %       % for the specified source code
            %       task = TestTask("myTestFolder",SourceFiles="sourceFolder",CodeCoverageResults="code-coverage/coverage.xml");
            %
            %       % Create a task to produce code coverage results in both Cobertura XML
            %       % and HTML formats
            %       task = TestTask("myTestFolder",SourceFiles="sourceFolder",CodeCoverageResults=["code-coverage/coverage.xml" "code-coverage/html/index.html"]);
            %
            %       % Create a task to save the code coverage results to a MAT-file
            %       % for programmatic access
            %       task = TestTask("myTestFolder",SourceFiles="sourceFolder",CodeCoverageResults="code-coverage/coverage.mat");
            %
            %       % Create a task to produce model coverage results in Cobertura
            %       % XML format for models defined in Simulink tests of the
            %       % specified test folder
            %       task = TestTask("myTestFolder",ModelCoverageResults="model-coverage/coverage.xml");
            %
            %       % Create a task to produce model coverage results in both Cobertura XML
            %       % and HTML formats
            %       task = TestTask("myTestFolder",ModelCoverageResults=["model-coverage/coverage.xml" "model-coverage/report.html"]);
            %
            %       % Create a task to run tests selected using a selector
            %       % import matlab.unittest.selectors.HasTag
            %       % import matlab.unittest.constraints.ContainsSubstring
            %       task = TestTask(Selector=HasTag(ContainsSubstring("unit")));
            %
            %       % Create a task to run only tests that are impacted by 
            %       % changes since the last run
            %       task = TestTask(RunOnlyImpactedTests=true);
            %
            %   See also:
            %       runtests
            %       matlab.unittest.plugins.CodeCoveragePlugin
            %       matlab.unittest.plugins.TestReportPlugin
            %       matlab.unittest.plugins.XMLPlugin
            %       sltest.plugins.TestManagerResultsPlugin
            %       sltest.plugins.ModelCoveragePlugin

            arguments
                tests = pwd()

                options.Description = getString(message("MATLAB:buildtool:TestTask:DefaultDescription"))
                options.Dependencies = string.empty(1,0)

                options.SourceFiles (1,:) matlab.buildtool.io.FileCollection
                options.SupportingFiles (1,:) matlab.buildtool.io.FileCollection
                options.TestResults (1,:) matlab.buildtool.io.File
                options.CodeCoverageResults (1,:) matlab.buildtool.io.File
                options.ModelCoverageResults (1,:) matlab.buildtool.io.File

                % Test identification
                options.IncludeSubfolders = true
                options.Tag = string.empty(1,0)
                options.Selector matlab.unittest.selectors.Selector {mustBeScalarOrEmpty} = matlab.unittest.selectors.NotSelector.empty()

                % Test run customization
                options.OutputDetail = matlab.automation.Verbosity.empty
                options.LoggingLevel = matlab.automation.Verbosity.empty
                options.Strict = false

                % Test impact analysis
                options.RunOnlyImpactedTests (1,1) logical = false
            end

            task.TestDerivatives = TestFileDerivatives();
            task.Tests = tests;
            for prop = string(fieldnames(options))'
                task.(prop) = options.(prop);
            end

            task.OutputStream = matlab.automation.streams.ToStandardOutput();
        end

        function task = set.Tests(task, value)
            task.TestDerivatives.Tests = value;
        end

        function value = get.Tests(task)
            value = task.TestDerivatives.Tests;
        end

        function task = set.IncludeSubfolders(task, value)
            task.TestDerivatives.IncludeSubfolders = value;
        end

        function value = get.IncludeSubfolders(task)
            value = task.TestDerivatives.IncludeSubfolders;
        end

        function task = set.Tag(task, value)
            task.TestDerivatives.Tag = value;
        end

        function value = get.Tag(task)
            value = task.TestDerivatives.Tag;
        end

        function task = set.Selector(task, value)
            task.TestDerivatives.Selector = value;
        end

        function value = get.Selector(task)
            value = task.TestDerivatives.Selector;
        end

        function value = get.RunOnlyImpactedTests(task)
            value = task.TestDerivatives.RunOnlyImpactedTests;
        end

        function task = set.RunOnlyImpactedTests(task, value)
            task.TestDerivatives.RunOnlyImpactedTests = value;
        end

        function task = set.ExternalParameters(task, value)
            if matlab.internal.feature('MBTTestTaskExternalParameters') == 1
                task.TestDerivatives.ExternalParameters = value;
            else
                error(message("MATLAB:buildtool:TestTask:InvalidProperty", ...
                    getString(message("MATLAB:buildtool:TestTask:ExternalParameters"))));
            end
        end

        function value = get.ExternalParameters(task)
            value = task.TestDerivatives.ExternalParameters;
        end

        function value = get.ExternalParameterValues(task)
            if matlab.internal.feature('MBTTestTaskExternalParameters') == 1
                value = [task.ExternalParameters.Value];
            else
                value = matlab.unittest.parameters.Parameter.empty(1, 0);
            end
        end

        function suite = get.TestSuite(task)
            suite = task.TestDerivatives.TestSuite;
        end

        function matFileTestResult = get.MATFileTestResult(task)
            import matlab.buildtool.internal.services.testresult.MATFileTestResultsExtensionService

            trPaths = task.TestResults.paths;
            [~, ~, ext] = fileparts(trPaths);
            mask = ext == MATFileTestResultsExtensionService.Extension | ext == "";
            matFileTestResult = trPaths(mask);
        end

        function task = set.TestResults(task, results)
            import matlab.buildtool.internal.tasks.addExtensionIfNeeded
            import matlab.buildtool.internal.services.testresult.MATFileTestResultsExtensionService
            results = results.transform(@(p)addExtensionIfNeeded(p, MATFileTestResultsExtensionService.Extension));
            task.TestResults = results;
        end

        function task = set.CodeCoverageResults(task, results)
            task.CodeCoverageSettings = matlab.buildtool.internal.tasks.codecoverage.CodeCoverageSettings(results);
        end

        function results = get.CodeCoverageResults(task)
            results = [task.CodeCoverageSettings.ResultFiles matlab.buildtool.io.File.empty(1,0)];
        end

        function files = get.AdditionalCodeCoverageOutputFiles(task)
            import matlab.buildtool.internal.tasks.codeCoverageResultsServices
            import matlab.buildtool.internal.services.codecoverage.CodeCoverageResultsLiaison
            import matlab.buildtool.io.FileCollection

            covResultServices = codeCoverageResultsServices();

            resultFiles = [task.CodeCoverageSettings.ResultFiles];
            resultFormats = [task.CodeCoverageSettings.ResultFormats];

            files = FileCollection.empty(1,0);
            for i = 1:numel(resultFiles)
                liaison = CodeCoverageResultsLiaison(resultFiles(i).absolutePaths(), CoverageFormat=class(resultFormats(i)));
                supportingService = covResultServices.findServiceThatSupports(liaison.ResultPath, liaison.ResultFormat);
                if ~isempty(supportingService)
                    files = [files supportingService.listSupportingOutputFiles(liaison)]; %#ok<AGROW>
                end
            end
        end

        function task = set.ModelCoverageResults(task, results)
            task.ModelCoverageSettings = matlab.buildtool.internal.tasks.modelcoverage.ModelCoverageSettings(results);
        end

        function results = get.ModelCoverageResults(task)
            results = [task.ModelCoverageSettings.ResultFiles matlab.buildtool.io.File.empty(1,0)];
        end
    end

    methods (TaskAction, Sealed, Hidden)
        function runTests(task, context, options)
            arguments
                task (1,1) matlab.buildtool.tasks.TestTask
                context
                options.RunOnlyImpactedTests (1,1) logical = task.RunOnlyImpactedTests
            end
            
            import matlab.automation.Verbosity;
            import matlab.buildtool.internal.isProductInstalled;

            suite = task.TestSuite;
            if options.RunOnlyImpactedTests
                if ~isProductInstalled("MATLAB Test")
                    % If MATLAB Test is not available, fall back to running all tests.
                    tripWireToMATLABTest = sprintf("matlab.internal.addons.launchers.showExplorer('tripwire_matlab_test', identifier='TE')");
                    MATLABTestRichText = FormattableStringDiagnostic(CommandHyperlinkableString("MATLAB Test", tripWireToMATLABTest));
                    context.log(Verbosity.Concise, getStringFromCatalog("RequiredProductNotAvailableToRunImpactedTests", MATLABTestRichText.DiagnosticText));
                elseif ~task.supportsIncremental()
                    warning(message("MATLAB:buildtool:TestTask:AllTestsAreImpactedWhenIncrementalIsNotSupported"));
                else
                    taskChanges = context.TaskChanges;
                    fingerprintChanges = taskChanges.classInputChange(listClassInputsForImpactAnalysis());
                    changedFiles = findAddedOrModifiedFiles(fingerprintChanges);
                    suite = findImpactedTests(context, suite, changedFiles);
                end
            end

            runner = constructTestRunner(task, context);

            testRunCustomizationData = struct();
            testRunCustomizationData = customizeTestRunner(task, runner, testRunCustomizationData);

            runFcn = getRunFunction(task, context, runner, suite);
            result = runFcn(runner, suite);
            saveTestResults(task, result);

            % Report out test execution summary
            execSummaryDiag = createTestRunSummaryDiagnostic(result);
            context.log(Verbosity.Concise, execSummaryDiag);

            % Report out test results summary
            testResultsPaths = task.TestResults.absolutePaths();
            if numel(testResultsPaths) > 0
                testResultsHeaderDiag = FormattableStringDiagnostic(PlainString(sprintf("%s:", getStringFromCatalog("TestResultsHeader"))));
                context.log(Verbosity.Concise, testResultsHeaderDiag);

                testResultsDiag = createTestResultsSummaryDiagnostic(task);
                context.log(Verbosity.Concise, testResultsDiag);
            end

            % Report out code coverage results summary
            saveCodeCoverageResults(task, testRunCustomizationData);
            codeCovResultsPaths = task.CodeCoverageResults.absolutePaths();
            if numel(codeCovResultsPaths) > 0
                codeCoverageResultsHeaderDiag = FormattableStringDiagnostic(PlainString(sprintf("%s:", getStringFromCatalog("CodeCoverageResultsHeader"))));
                context.log(Verbosity.Concise, codeCoverageResultsHeaderDiag);

                covResultsDiag = createCodeCoverageResultsSummaryDiagnostic(task);
                context.log(Verbosity.Concise, covResultsDiag);
            end

            % Report out model coverage results summary
            modelCovResultsPaths = task.ModelCoverageResults.absolutePaths();
            if numel(modelCovResultsPaths) > 0
                modelCoverageResultsHeaderDiag = FormattableStringDiagnostic(PlainString(sprintf("%s:", getStringFromCatalog("ModelCoverageResultsHeader"))));
                context.log(Verbosity.Concise, modelCoverageResultsHeaderDiag);

                covResultsDiag = createModelCoverageResultsSummaryDiagnostic(task);
                context.log(Verbosity.Concise, covResultsDiag);
            end

            context.assertTrue(~any([result.Failed]), ...
                getString(message("MATLAB:unittest:TestResult:UnsuccessfulRun")));
        end
    end

    methods (Hidden)
        function tf = supportsIncremental(task)
            tf = ~isempty(task.SourceFiles);
        end
    end

    methods (Access = protected)
        function runner = constructTestRunner(task, context)
            import matlab.automation.Verbosity;
            import matlab.unittest.plugins.TestRunProgressPlugin;
            import matlab.unittest.plugins.DiagnosticsOutputPlugin;
            import matlab.unittest.plugins.DiagnosticsRecordingPlugin;

            args = struct;
            if isfield(context.BuildOptions,"Verbosity") && ~isempty(context.BuildOptions.Verbosity)
                args.OutputDetail = context.BuildOptions.Verbosity;
            elseif ~isempty(task.OutputDetail)
                args.OutputDetail = task.OutputDetail;
            end
            if isfield(context.BuildOptions,"Verbosity") && ~isempty(context.BuildOptions.Verbosity)
                args.LoggingLevel = context.BuildOptions.Verbosity;
            elseif ~isempty(task.LoggingLevel)
                args.LoggingLevel = task.LoggingLevel;
            end
            runnerOptions = namedargs2cell(args);

            runner = matlab.unittest.TestRunner.withNoPlugins();
            runner.addPlugin(DiagnosticsOutputPlugin(runnerOptions{:}));
            runner.addPlugin(DiagnosticsRecordingPlugin(runnerOptions{:}));

            % Use "terse" OutputDetail for test run progress, by default
            if ~isfield(args, "OutputDetail")
                args.OutputDetail = Verbosity.Terse;
            end
            runner.addPlugin(TestRunProgressPlugin.withVerbosity(args.OutputDetail));
        end

        function testRunCustomizationData = customizeTestRunner(task, runner, testRunCustomizationData)
            configureTestRunnerWithRunCustomizationOptions(task, runner);
            configureTestRunnerWithTestResults(task, runner);
            testRunCustomizationData = configureTestRunnerWithCodeCoverageResults(task, runner, testRunCustomizationData);
            testRunCustomizationData = configureTestRunnerWithModelCoverageResults(task, runner, testRunCustomizationData);
            configureTestRunnerWithCIPlugins(task, runner);
        end
    end

    methods (Access = private)
        function configureTestRunnerWithRunCustomizationOptions(task, runner)
            import matlab.buildtool.internal.tasks.testRunCustomizationServices
            import matlab.buildtool.internal.services.testruncustomization.TestRunCustomizationLiaison

            args.Strict = task.Strict;

            services = testRunCustomizationServices();
            runnerOptions = string(fieldnames(args));

            for i = 1:numel(runnerOptions)
                liaison = TestRunCustomizationLiaison(runnerOptions(i), args.(runnerOptions(i)));
                fulfill(services, liaison);
                supportingService = services.findServiceThatSupports(liaison.RunnerOption);
                if ~isempty(supportingService)
                    customizeTestRunner(supportingService, liaison, runner);
                end
            end
        end

        function configureTestRunnerWithTestResults(task, runner)
            import matlab.buildtool.internal.tasks.testResultsFileExtensionServices
            import matlab.buildtool.internal.services.testresult.TestResultExtensionLiaison
            import matlab.buildtool.internal.services.testresult.MLDATXTestResultsExtensionService

            services = testResultsFileExtensionServices();
            testResultsPaths = task.TestResults.absolutePaths();

            options.OutputDetail = task.OutputDetail;
            options.LoggingLevel = task.LoggingLevel;

            if isempty(options.OutputDetail)
                options = rmfield(options, "OutputDetail");
            end

            if isempty(options.LoggingLevel)
                options = rmfield(options, "LoggingLevel");
            end

            % Add plugin to include Simulink Test Manager test results if
            % the test suite contains any Simulink Test files.
            [~,~,ext] = fileparts(testResultsPaths);
            mask = strcmpi(MLDATXTestResultsExtensionService.Extension, ext);
            slTestMgrResultsPath = testResultsPaths(mask);
            task.addSimulinkTestManagerResults(runner, slTestMgrResultsPath);

            testResultsPaths = testResultsPaths(~mask);
            for i = 1:numel(testResultsPaths)
                liaison = TestResultExtensionLiaison(testResultsPaths(i), options);
                fulfill(services, liaison);
                supportingService = services.findServiceThatSupports(liaison.Extension);
                supportingService.createResultsFolder(liaison);
                customizeTestRunner(supportingService, liaison, runner);
            end
        end

        function testRunCustomizationData = configureTestRunnerWithCodeCoverageResults(task, runner, testRunCustomizationData)
            import matlab.buildtool.internal.services.codecoverage.CodeCoverageLiaison
            import matlab.buildtool.internal.tasks.coverageServices
            import matlab.buildtool.internal.tasks.CoverageSourceType

            services = coverageServices();
            liaison = CodeCoverageLiaison(CoverageSourceType.Code, task.SourceFiles, task.CodeCoverageSettings);
            fulfill(services, liaison);
            supportingService = services.findServiceThatSupports(liaison.SourceType);
            supportingService.customizeTestRunner(liaison, runner);
            testRunCustomizationData.CodeCoverageFormats = liaison.CoverageFormats;
        end

        function testRunCustomizationData = configureTestRunnerWithModelCoverageResults(task, runner, testRunCustomizationData)
            import matlab.buildtool.internal.services.modelcoverage.ModelCoverageLiaison
            import matlab.buildtool.internal.tasks.coverageServices
            import matlab.buildtool.internal.tasks.CoverageSourceType

            services = coverageServices();
            liaison = ModelCoverageLiaison(CoverageSourceType.Model, task.ModelCoverageSettings);
            fulfill(services, liaison);
            supportingService = services.findServiceThatSupports(liaison.SourceType);
            supportingService.customizeTestRunner(liaison, runner);
            testRunCustomizationData.ModelCoverageFormats = liaison.CoverageFormats;
        end

        function configureTestRunnerWithCIPlugins(~, runner)
            import matlab.unittest.internal.plugins.PluginProviderData;
            import matlab.unittest.internal.services.plugins.locateDefaultPlugins;

            plugins = locateDefaultPlugins(?matlab.buildtool.internal.services.ciplugins.CITestRunnerPluginService, ...
                "matlab.unittest.internal.services.plugins", PluginProviderData);
            for idx = 1:numel(plugins)
                runner.addPlugin(plugins(idx));
            end
        end

        function runFcn = getRunFunction(task, context, runner, suite)
            useParallel = isfield(context.BuildOptions, "Parallel") && ...
                context.BuildOptions.Parallel;
            options = struct(...
                "UseParallel", useParallel, ...
                "OutputStream", task.OutputStream);
            runFcn = matlab.unittest.internal.getRunFcn(options, runner.Plugins, suite, runner.ArtifactsRootFolder);
        end

        function saveTestResults(task, result) %#ok<INUSD>
            import matlab.buildtool.internal.services.testresult.TestResultExtensionLiaison

            matFiles = task.MATFileTestResult;
            resultsVarName = TestResultExtensionLiaison.TestResultsVarName;
            for i = 1:numel(matFiles)
                eval(resultsVarName + " = result;");
                save(matFiles(i), resultsVarName);
            end
        end

        function saveCodeCoverageResults(task, testRunCustomizationData)
            import matlab.buildtool.internal.services.codecoverage.CoverageResultService
            import matlab.buildtool.internal.services.codecoverage.CodeCoverageResultsLiaison

            if ~isfield(testRunCustomizationData, "CodeCoverageFormats")
                return
            end

            coverageResultsPaths = task.CodeCoverageResults.absolutePaths();
            [~, ~, ext] = fileparts(coverageResultsPaths);
            mask = ext == CoverageResultService.Extension | ext == "";
            coverageMATFiles = coverageResultsPaths(mask);
            coverageResultFormats = testRunCustomizationData.CodeCoverageFormats(mask); %#ok<NASGU>

            resultsVarName = CodeCoverageResultsLiaison.ResultVarName;
            for i = 1:numel(coverageMATFiles)
                eval(resultsVarName + " = coverageResultFormats(i).Result;");
                save(coverageMATFiles(i), resultsVarName);
            end
        end

        function addSimulinkTestManagerResults(~, runner, resultsPath)
            import matlab.buildtool.internal.services.testresult.TestResultExtensionLiaison
            import matlab.buildtool.internal.services.testresult.MLDATXTestResultsExtensionService
            import matlab.buildtool.internal.services.testresult.SimulinkTestManagerResultsService

            if isempty(resultsPath)
                service = SimulinkTestManagerResultsService;
                service.fulfill(runner);
            else
                service = MLDATXTestResultsExtensionService;
                for i = 1:numel(resultsPath)
                    liaison = TestResultExtensionLiaison(resultsPath(i));
                    service.customizeTestRunner(liaison, runner);
                end
            end
        end

        function diag = createTestResultsSummaryDiagnostic(task)
            import matlab.buildtool.internal.tasks.testResultsFileExtensionServices
            import matlab.buildtool.internal.services.testresult.TestResultExtensionLiaison

            testResultsPaths = task.TestResults.absolutePaths();
            testResultServices = testResultsFileExtensionServices();
            formattedResultsStr = LabelAlignedListString;
            for i = 1:numel(testResultsPaths)
                liaison = TestResultExtensionLiaison(testResultsPaths(i), struct);
                fulfill(testResultServices, liaison);
                supportingService = testResultServices.findServiceThatSupports(liaison.Extension);
                if ~isempty(supportingService)
                    formattedResultsStr = supportingService.addLabelAndString(liaison, formattedResultsStr);
                end
            end
            diag = FormattableStringDiagnostic(PlainString(sprintf("%s\n", IndentedString(formattedResultsStr.Text))));
        end

        function diag = createCodeCoverageResultsSummaryDiagnostic(task)
            import matlab.buildtool.internal.tasks.codeCoverageResultsServices
            import matlab.buildtool.internal.services.codecoverage.CodeCoverageResultsLiaison

            resultFiles = [task.CodeCoverageSettings.ResultFiles];
            resultFormats = [task.CodeCoverageSettings.ResultFormats];
            covResultServices = codeCoverageResultsServices();
            formattedResultsStr = LabelAlignedListString;

            for i = 1:numel(resultFiles)
                liaison = CodeCoverageResultsLiaison(resultFiles(i).absolutePaths(), CoverageFormat=class(resultFormats(i)));
                fulfill(covResultServices, liaison);
                supportingService = covResultServices.findServiceThatSupports(liaison.ResultPath, liaison.ResultFormat);
                if ~isempty(supportingService)
                    formattedResultsStr = supportingService.addLabelAndString(liaison, formattedResultsStr);
                end
            end
            diag = FormattableStringDiagnostic(PlainString(sprintf("%s\n", IndentedString(formattedResultsStr.Text))));
        end

        function diag = createModelCoverageResultsSummaryDiagnostic(task)
            import matlab.buildtool.internal.tasks.modelCoverageResultsServices
            import matlab.buildtool.internal.services.modelcoverage.ModelCoverageResultsLiaison

            resultFiles = [task.ModelCoverageSettings.ResultFiles];
            resultFormats = [task.ModelCoverageSettings.ResultFormats];
            covResultServices = modelCoverageResultsServices();
            formattedResultsStr = LabelAlignedListString;

            for i = 1:numel(resultFiles)
                liaison = ModelCoverageResultsLiaison(resultFiles(i).absolutePaths(), CoverageFormat=class(resultFormats(i)));
                fulfill(covResultServices, liaison);
                supportingService = covResultServices.findServiceThatSupports(liaison.ResultPath, liaison.ResultFormat);
                if ~isempty(supportingService)
                    formattedResultsStr = supportingService.addLabelAndString(liaison, formattedResultsStr);
                end
            end
            diag = FormattableStringDiagnostic(PlainString(sprintf("%s\n", IndentedString(formattedResultsStr.Text))));
        end
    end
end

function diag = createTestRunSummaryDiagnostic(result)
headerDiag = FormattableStringDiagnostic(PlainString(sprintf("\n%s:", getStringFromCatalog("SummaryHeader"))));

summary = LabelAlignedListString;
summary = summary.addLabelAndString(...
    sprintf("%s:", getStringFromCatalog("TotalTests")), num2str(numel(result)));
summary = summary.addLabelAndString(...
    sprintf("%s:", getStringFromCatalog("Passed")), num2str(nnz([result.Passed])));
summary = summary.addLabelAndString(...
    sprintf("%s:", getStringFromCatalog("Failed")), num2str(nnz([result.Failed])));
summary = summary.addLabelAndString(...
    sprintf("%s:", getStringFromCatalog("Incomplete")), num2str(nnz([result.Incomplete])));
summary = summary.addLabelAndString(...
    sprintf("%s:", getStringFromCatalog("Duration")), sprintf("%s\n", getString(message('MATLAB:unittest:TestResult:Duration', num2str(sum([result.Duration]))))));
summaryDiag = FormattableStringDiagnostic(IndentedString(summary.Text));

diag = [headerDiag summaryDiag];
end

function props = listClassInputsForImpactAnalysis()
props = ["SourceFiles" "SupportingFiles" "TestDerivatives"];
end

function files = findAddedOrModifiedFiles(fingerprintChanges)
fingerprintChanges = fingerprintChanges(fingerprintChanges.isChanged);
files = unique([fingerprintChanges.addedPaths() fingerprintChanges.createdFiles() fingerprintChanges.modifiedFiles()]);
end


function suite = findImpactedTests(context, suite, changedFiles)
% Find tests impacted by changes since the last successful run

import matlab.automation.Verbosity;
import matlab.automation.internal.diagnostics.indentWithArrow;
import matlab.buildtool.internal.io.relativePath;

% Select tests that depend on changed files.
context.log(Verbosity.Concise, ...
    StringDiagnostic(sprintf("%s", getStringFromCatalog("FindingImpactedTests"))));

numTotalTests = numel(suite);
if isempty(changedFiles)
    suite(:) = [];
else
    suite = selectIf(suite, matlabtest.selectors.DependsOn(changedFiles));
end
numImpactedTests = numel(suite);

if numImpactedTests == 1
    numImpactedTestsText = getStringFromCatalog("NumTestsSingular");
else
    numImpactedTestsText = getStringFromCatalog("NumTestsPlural", numImpactedTests);
end

if numImpactedTests > 0
    % Hyperlink the text if tests are found
    testFileNames = string({suite.Filename});
    testFileNames = relativePath(testFileNames, context.Plan.RootFolder);
    procedureNames = string({suite.ProcedureName});
    commandToDisplayImpactedTests = sprintf("matlab.unittest.internal.diagnostics.displayCellArrayAsTable([{%s} {%s}], {'%s' '%s'})", ...
        sprintf("'%s';", testFileNames{:}), ...
        sprintf("'%s';", procedureNames{:}), ...
        "TestFile", ...
        "ProcedureName");
    numImpactedTestsRichText = FormattableStringDiagnostic(CommandHyperlinkableString(numImpactedTestsText, commandToDisplayImpactedTests));
    numImpactedTestsText = numImpactedTestsRichText.DiagnosticText; % enriched text
end
foundImpactedTestsFullText = getStringFromCatalog("ImpactedTestsFoundSinceLastSuccessfulRun", numImpactedTestsText, numTotalTests);
context.log(Verbosity.Concise, ...
    FormattableStringDiagnostic(indentWithArrow(foundImpactedTestsFullText)));
end

function d = StringDiagnostic(varargin)
d = matlab.automation.diagnostics.StringDiagnostic(varargin{:});
end

function d = FormattableStringDiagnostic(varargin)
d = matlab.automation.internal.diagnostics.FormattableStringDiagnostic(varargin{:});
end

function fs = LabelAlignedListString(varargin)
fs = matlab.automation.internal.diagnostics.LabelAlignedListString(varargin{:});
end

function fs = IndentedString(varargin)
fs = matlab.automation.internal.diagnostics.IndentedString(varargin{:});
end

function fs = PlainString(varargin)
fs = matlab.automation.internal.diagnostics.PlainString(varargin{:});
end

function fs = CommandHyperlinkableString(varargin)
fs = matlab.automation.internal.diagnostics.CommandHyperlinkableString(varargin{:});
end

function str = getStringFromCatalog(id, varargin)
str = matlab.buildtool.internal.tasks.getStringFromCatalog(matlab.buildtool.tasks.TestTask.Catalog, id, varargin{:});
end

function c = TestFileDerivatives(varargin)
c = matlab.buildtool.internal.tasks.TestFileDerivatives(varargin{:});
end

% LocalWords:  MLDATX mldatx Cobertura buildplan MBT addons
