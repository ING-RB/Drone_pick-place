classdef(Hidden) RunnableTestContent < matlab.unittest.internal.TestContent & ...
        matlab.unittest.internal.qualifications.ThrowingQualifiable & ...
        matlab.unittest.qualifications.Verifiable & ...
        matlab.unittest.internal.Measurable
    % Undocumented.
    
    % Copyright 2012-2024 The MathWorks, Inc.
    
    properties (Access={?matlab.unittest.TestRunner,?matlab.unittest.internal.SharedTestFixtureSetup})
        SharedTestFixtures_ = matlab.unittest.fixtures.EmptyFixture.empty;
    end

    properties (Transient, Access=private)
        AppliedFixtures = matlab.unittest.fixtures.Fixture.empty;
    end
    
    methods(Sealed)
        function result = run(testCase, varargin)
            % RUN - Run a TestCase test.
            %
            %   RESULT = RUN(TESTCASE) uses TESTCASE as a prototype to run a TestSuite
            %   created from all test methods in the class defining TESTCASE. This
            %   suite is run using a TestRunner configured for text output. RESULT is a
            %   matlab.unittest.TestResult containing the result of the test run.
            %
            %   RESULT = RUN(TESTCASE, TESTMETHOD) uses TESTCASE as a prototype to run
            %   a TestSuite created from TESTMETHOD. TESTMETHOD is either the name of
            %   the desired test method as a string, character vector, or the
            %   meta.method instance which describes the desired test method. The
            %   method must correspond to a valid Test method of the TESTCASE instance.
            %   This test is run using a TestRunner configured for text output. RESULT
            %   is a matlab.unittest.TestResult containing the result of the test run.
            %
            %   This is a convenience method to allow interactive experimentation of
            %   TestCase classes in MATLAB, yet running the tests contained in them
            %   using a supported TestRunner.
            %
            %   Example:
            %
            %       testCase = mynamespace.MyTestClass;
            %
            %       % Run all tests in mynamespace.MyTestClass
            %       allResults = run(testCase);
            %
            %       % Run the "testSomething" method in the mynamespace.MyTestClass
            %       testSomethingResult = run(testCase, 'testSomething');
            %
            %   See also: TestRunner, TestSuite, TestResult
            import matlab.unittest.Test;
            
            suite = Test.fromTestCase(testCase, varargin{:});
            result = run(suite);
        end
        
        function appliedFixture = applyFixture(testCase, fixture)
            % applyFixture - Use a fixture within a TestCase class.
            %
            %   applyFixture(TESTCASE, FIXTURE) sets up FIXTURE for use with TESTCASE.
            %   This method allows a fixture to be used within the scope of a single
            %   Test method or TestCase class. Call applyFixture within a Test method
            %   to use a fixture for that Test method alone. Use applyFixture within a
            %   TestClassSetup method to set up a fixture for the entire class.
            %
            %   By using applyFixture, the life-cycle of FIXTURE is tied to that of
            %   TESTCASE. When TESTCASE is torn down or deleted, FIXTURE is also torn
            %   down.
            %
            %   Example:
            %
            %       classdef TSomeTest < matlab.unittest.TestCase
            %           methods(TestMethodSetup)
            %               function addHelpersToPath(testCase)
            %                   import matlab.unittest.fixtures.PathFixture;
            %                   testCase.applyFixture(PathFixture('testHelpers'));
            %               end
            %           end
            %       end
            %
            
            validateattributes(fixture, {'matlab.unittest.fixtures.Fixture'}, {'scalar'}, '', 'fixture');
            testCase.AppliedFixtures(end+1) = fixture;
            fixture.setupAppliedFixture_(testCase);
            if nargout > 0
                appliedFixture = fixture;
            end
        end
        
        function fixtures = getSharedTestFixtures(testCase, fixtureClassName)
            % getSharedTestFixtures - Access shared test fixtures.
            %
            %   FIXTURES = getSharedTestFixtures(TESTCASE) returns in FIXTURES the
            %   array of all shared test fixtures that have been set up for TESTCASE.
            %   Shared test fixtures are specified using the SharedTestFixtures class
            %   attribute.
            %
            %   FIXTURES = getSharedTestFixtures(TESTCASE, FIXTURECLASSNAME) returns
            %   in FIXTURES only those shared test fixtures whose class name is
            %   FIXTURECLASSNAME,specified as a string or character vector.
            %
            %   Example:
            %
            %       classdef (SharedTestFixtures={matlab.unittest.fixtures.PathFixture('testHelpers')}) ...
            %               TSomeTest < matlab.unittest.TestCase
            %           methods(Test)
            %               function accessPathFixture(testCase)
            %                   pathFixture = testCase.getSharedTestFixtures('matlab.unittest.fixtures.PathFixture');
            %                   folderOnPath = pathFixture.Folder;
            %               end
            %           end
            %       end
            %
            import matlab.unittest.internal.mustBeTextScalar;
            import matlab.unittest.internal.mustContainCharacters;
            
            fixtures = testCase.SharedTestFixtures_;
            
            if nargin > 1
                mustBeTextScalar(fixtureClassName,'fixtureClassName');
                mustContainCharacters(fixtureClassName,'fixtureClassName');
                fixtures = fixtures.getFixturesByClassName(fixtureClassName);
            end
        end 
    end
    
    methods(Sealed)
        function onFailure(testCase,failureTasks,varargin)
            % onFailure - Dynamically add diagnostics for test failures.
            %
            % onFailure(TESTCASE,ONFAILUREDIAGNOSTICS) adds diagnostics for TESTCASE.
            % If a test fails, then the test framework executes the diagnostics.
            % Specify ONFAILUREDIAGNOSTICS as a function handle, array of
            % matlab.unittest.diagnostics.Diagnostic objects, character vector, or
            % string array. By default, onFailure adds diagnostics that are executed
            % for verification failures, assertion failures, fatal assertion failures
            % and uncaught exceptions.
            %
            % onFailure(TESTCASE,ONFAILUREDIAGNOSTICS,'IncludingAssumptionFailures',true)
            % adds diagnostics that are also executed for assumption failures.
            %
            %   Example:
            %
            %       classdef SomeTest < matlab.unittest.TestCase
            %           methods(TestMethodSetup)
            %               function test1(testCase)
            %                   import matlab.unittest.diagnostics.ScreenshotDiagnostic
            %
            %                   testCase.onFailure(@() disp('Failure Detected'));
            %                   testCase.onFailure(ScreenshotDiagnostic);
            %               end
            %           end
            %       end                     
            import matlab.unittest.internal.AddAssumptionEventDecorator
            import matlab.unittest.internal.AddVerificationEventDecorator
            import matlab.unittest.internal.FailureTask
            
            if ~isa(failureTasks,'matlab.unittest.internal.Task')
                validateattributes(failureTasks, {'function_handle','matlab.unittest.diagnostics.Diagnostic',...
                    'char', 'string'},{'row'},'','OnFailureDiagnostics');

                defaultIncludeAssumption = false;
                validationFcn = @(x)(islogical(x)&&isscalar(x));
                
                onFailureParser = matlab.unittest.internal.strictInputParser;
                onFailureParser.addParameter('IncludingAssumptionFailures',...
                    defaultIncludeAssumption,validationFcn);
                onFailureParser.parse(varargin{:});
                parserResults = onFailureParser.Results;

                failureTasks = FailureTask(failureTasks);
                                
                if parserResults.IncludingAssumptionFailures
                    failureTasks = AddAssumptionEventDecorator(failureTasks);
                end
            end
            failureTasks =  AddVerificationEventDecorator(failureTasks);
            for onFailureDecoratedTask = failureTasks
                onFailure@matlab.unittest.qualifications.Verifiable(testCase,onFailureDecoratedTask);
                onFailure@matlab.unittest.internal.qualifications.ThrowingQualifiable(testCase,onFailureDecoratedTask);
                testCase.setOnFailureTasksForExceptions_(onFailureDecoratedTask);
            end
        end
    end

    methods
        function tempFolder = createTemporaryFolder(testCase)
            % createTemporaryFolder - Create temporary folder
            %
            %   FOLDER = createTemporaryFolder(TESTCASE) returns a
            %   temporary folder. The scope of the TESTCASE controls
            %   the lifetime of the temporary folder. For example, a 
            %   temporary folder created within a Test method is deleted 
            %   when the method-level TestCase instance goes out of scope.
            %
            %   Example: 
            %
            %       classdef SomeTest < matlab.unittest.TestCase
            %           properties
            %               Folder
            %           end
            %
            %           methods(TestMethodSetup)
            %               function setup(testCase)
            %                   testCase.Folder = testCase.createTemporaryFolder();
            %               end
            %           end
            %       end
            %
            import matlab.unittest.fixtures.TemporaryFolderFixture

            fixture = testCase.applyFixture(TemporaryFolderFixture);
            tempFolder = fixture.Folder;
        end

        function delete(testCase)
            testCase.AppliedFixtures(:) = [];
        end
    end
end
% LocalWords:  TESTMETHOD mynamespace TSome Substitutor FIXTURECLASSNAME ONFAILUREDIAGNOSTICS
% LocalWords:  ONFAILUREFCN INCLUDINGASSUMPTIONFAILURES Screenshot
