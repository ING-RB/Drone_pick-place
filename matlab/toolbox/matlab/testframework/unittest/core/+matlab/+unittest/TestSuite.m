classdef TestSuite < matlab.unittest.internal.TestSuiteExtension
    % TestSuite - Interface for grouping tests to run
    %
    %   The matlab.unittest.TestSuite class is the fundamental interface used
    %   to group and run a set of tests using the test framework. The
    %   TestRunner can only run arrays of TestSuites.
    %
    %   TestSuites are created using static methods of the TestSuite class.
    %   These methods may return subclasses of TestSuite depending on
    %   the method call and context.
    %
    %   TestSuite methods:
    %       fromName      - Create a suite from the name of the test element
    %       fromFile      - Create a suite from a TestCase class filename
    %       fromFolder    - Create a suite from all tests in a folder
    %       fromNamespace - Create a suite from all tests in a namespace
    %       fromProject   - Create a suite from all tests with the label Test in a project
    %       fromClass     - Create a suite from a TestCase class
    %       fromMethod    - Create a suite from a single test method
    %
    %       run            - Run a TestSuite using a TestRunner configured for text output
    %       selectIf       - Select suite elements that satisfy one or more constraints
    %       sortByFixtures - Sort a suite of tests based on its fixtures
    %
    %   Example:
    %
    %       import matlab.unittest.TestSuite;
    %
    %       % Create test suites using a variety of methods.
    %       fileSuite      = TestSuite.fromFile('SomeTestFile.m');
    %       folderSuite    = TestSuite.fromFolder(pwd);
    %       namespaceSuite = TestSuite.fromNamespace('mynamespace.innernamespace');
    %       projectSuite   = TestSuite.fromProject(SomeProjectHandle);
    %       classSuite     = TestSuite.fromClass(?mynamespace.MyTestClass);
    %       methodSuite    = TestSuite.fromMethod(?SomeTestClass,'testMethod');
    %
    %       % Now concatenate them all together and run them using a test
    %       % runner configured  for text output.
    %       largeSuite = [fileSuite, folderSuite, namespaceSuite, projectSuite, classSuite, methodSuite];
    %
    %       % Run the full suite
    %       result = run(largeSuite)
    %
    %   See also: TestRunner, TestResult, Test
    %
    
    % Copyright 2012-2023 The MathWorks, Inc.
    
    methods (Static)
        function suite = fromName(name, varargin)
            % fromName - Create a suite from the name of the test element
            %
            %   SUITE = matlab.unittest.TestSuite.fromName(NAME) creates a scalar
            %   TestSuite given its name and returns it in SUITE. NAME is a character
            %   vector or a string corresponding to the name of the Test suite array
            %   element to be created. The name of a test element contains the name of
            %   the TestCase class or function as well as the test method or local
            %   function. The name also contains information about parameterization.
            %
            %   SUITE = matlab.unittest.TestSuite.fromName(__, 'ExternalParameters', PARAM)
            %   allows the suite to use PARAM, an array of matlab.unittest.parameters.Parameter
            %   instances. The framework uses the external parameters in place of
            %   corresponding parameters that are defined within a parameterized test.
            %
            %   The test class or function described by NAME must be on the MATLAB path
            %   when creating SUITE using this method as well as when SUITE is run.
            %
            %   Examples:
            %       import matlab.unittest.TestSuite;
            %
            %       % Create a suite for the "TestFoo" method in class "MyTest"
            %       suite = TestSuite.fromName('MyTest/TestFoo');
            %       result = run(suite)
            %
            %       % Create a suite for the "TestFoo" method in class "MyTest" with
            %       % TestParameter "Param".
            %       suite = TestSuite.fromName('MyTest/TestFoo(Param=val)');
            %       result = run(suite)
            %
            %       % Create a suite using an external parameter value.
            %       % Force the suite to use this value instead of how the
            %       % "Param" property was defined in the class-based test.
            %       import matlab.unittest.parameters.Parameter;
            %       parameter = Parameter.fromData('Param', struct('val', 'mydata');
            %       suite = TestSuite.fromName('MyTest/TestFoo(Param=val#ext)', ...
            %           'ExternalParameters', parameter);
            %       result = run(suite);
            %
            %   See also: TestRunner
            %
            
            import matlab.unittest.internal.strictInputParser;
            import matlab.unittest.internal.validateParameter;
            import matlab.unittest.Test;
            import matlab.unittest.internal.locateTestSuiteNameValuePairs;
            
            narginchk(1,Inf);
            
            parser = strictInputParser;
            parser.addParameter('ExternalParameters',...
                matlab.unittest.parameters.Parameter.empty(1,0),...
                @validateParameter);
            nameValueLiaison = locateTestSuiteNameValuePairs(parser);
            nameValueLiaison.parse(varargin{:});

            modifier = parsingResultsToModifier(nameValueLiaison);
            externalParameters = nameValueLiaison.Results.ExternalParameters;
            suite = Test.fromName(name, modifier, externalParameters);
        end
        
        function suite = fromFile(testFile, varargin)
            % fromFile - Create a suite from a test file
            %
            %   SUITE = matlab.unittest.TestSuite.fromFile(FILE) creates a TestSuite
            %   array from all of the Test methods in FILE and returns that array in
            %   SUITE. FILE is a character vector or a string corresponding to the name
            %   of the desired file. FILE can contain either an absolute or relative
            %   path to the desired file.
            %
            %   SUITE = matlab.unittest.TestSuite.fromFile(FILE, ATTRIBUTE_1, CONSTRAINT_1, ...)
            %   creates a TestSuite array for all of the Test methods in FILE that
            %   satisfy the specified conditions. Specify any of the following attributes:
            %
            %       * Name              - Name of the suite element
            %       * ProcedureName     - Name of the test procedure in the test
            %       * Superclass        - Name of a class that the test class derives
            %                             from
            %       * BaseFolder        - Name of the folder that holds the file
            %                             defining the test class or function.
            %       * ParameterProperty - Name of a property that defines a
            %                             Parameter used by the suite element
            %       * ParameterName     - Name of a Parameter used by the suite element
            %       * Tag               - Name of a tag defined on the suite element. 
            %
            %   The value of each attribute is specified as a string array, character vector, 
            %   or cell array of character vectors. For all attributes except Superclass, the 
            %   value can contain wildcard characters "*" (matches any number of characters, 
            %   including zero) and "?" (matches exactly one character). A test is included 
            %   in the suite only if it satisfies the criteria specified by all attributes. 
            %   For each attribute, the test element must satisfy at least one of the options
            %   specified for that attribute.
            %
            %   SUITE = matlab.unittest.TestSuite.fromFile(FILE, SELECTOR) creates a
            %   TestSuite array for all of the Test methods contained in TESTCLASS that
            %   satisfy the SELECTOR.
            %
            %   SUITE = matlab.unittest.TestSuite.fromFile(__, 'ExternalParameters', PARAM)
            %   allows the suite to use PARAM, an array of matlab.unittest.parameters.Parameter
            %   instances. The framework uses the external parameters in place of
            %   corresponding parameters that are defined within a parameterized test.
            %
            %   Examples:
            %       import matlab.unittest.TestSuite;
            %       import matlab.unittest.selectors.HasParameter;
            %
            %       % Create a suite for the file "MyTestFile.m"
            %       suite = TestSuite.fromFile('MyTestFile.m');
            %       result = run(suite)
            %
            %       % Create a suite for the Test methods in file
            %       % "MyTest.m" whose name starts with "TestFoo".
            %       suite = TestSuite.fromFile('MyTest.m', 'Name','TestFoo*');
            %       result = run(suite)
            %
            %       % Create a suite for all parameterized Test methods in "MyTest.m"
            %       suite = TestSuite.fromFile('MyTest.m', HasParameter);
            %       result = run(suite)
            %
            %   See also: TestRunner, TestSuite.fromFolder, matlab.unittest.selectors
            %

            import matlab.unittest.TestSuite;

            narginchk(1,Inf);
            parser = parseInputs(varargin{:});
            externalParameters = parser.Results.ExternalParameters;
            modifier = parsingResultsToModifier(parser);
            suite = TestSuite.fromFileCore_(testFile, modifier, externalParameters);
        end
        
        function suite = fromClass(testClass, varargin)
            % fromClass - Create a suite from a TestCase class
            %
            %   SUITE = matlab.unittest.TestSuite.fromClass(TESTCLASS) creates a
            %   TestSuite array from all of the Test methods contained in TESTCLASS and
            %   returns that array in SUITE. TESTCLASS is a meta.class instance which
            %   describes the desired test class. The test class described by TESTCLASS
            %   must derive from matlab.unittest.TestCase.
            %
            %   This test class must be on the MATLAB path when creating SUITE using
            %   this method as well as when SUITE is run.
            %
            %   SUITE = matlab.unittest.TestSuite.fromClass(TESTCLASS, ATTRIBUTE_1, CONSTRAINT_1, ...)
            %   creates a TestSuite array for all of the Test methods in TESTCLASS that
            %   satisfy the specified conditions. Specify any of the following attributes:
            %
            %       * Name              - Name of the suite element
            %       * ProcedureName     - Name of the test procedure in the test
            %       * Superclass        - Name of a class that the test class derives
            %                             from
            %       * BaseFolder        - Name of the folder that holds the file
            %                             defining the test class or function.
            %       * ParameterProperty - Name of a property that defines a
            %                             Parameter used by the suite element
            %       * ParameterName     - Name of a Parameter used by the suite element
            %       * Tag               - Name of a tag defined on the suite element. 
            %
            %   The value of each attribute is specified as a string array, character vector, 
            %   or cell array of character vectors. For all attributes except Superclass, the 
            %   value can contain wildcard characters "*" (matches any number of characters, 
            %   including zero) and "?" (matches exactly one character). A test is included 
            %   in the suite only if it satisfies the criteria specified by all attributes. 
            %   For each attribute, the test element must satisfy at least one of the options
            %   specified for that attribute.
            %
            %   SUITE = matlab.unittest.TestSuite.fromClass(TESTCLASS, SELECTOR)
            %   creates a TestSuite array for all of the Test methods contained in
            %   TESTCLASS that satisfy the SELECTOR.
            %
            %   SUITE = matlab.unittest.TestSuite.fromClass(__, 'ExternalParameters', PARAM)
            %   allows the suite to use PARAM, an array of matlab.unittest.parameters.Parameter
            %   instances. The framework uses the external parameters in place of
            %   corresponding parameters that are defined within a parameterized test.
            %
            %   This test class must be on the MATLAB path when creating SUITE using
            %   this method as well as when SUITE is run.
            %
            %   Examples:
            %       import matlab.unittest.TestSuite;
            %       import matlab.unittest.selectors.HasParameter;
            %       import matlab.unittest.selectors.HasTag;
            %
            %       suite = TestSuite.fromClass(?mynamespace.MyTestClass);
            %       result = run(suite)
            %
            %       % Create a suite for the Test methods in class
            %       % MyTest whose name starts with "TestFoo".
            %       suite = TestSuite.fromClass(?MyTest, 'Name','TestFoo*');
            %       result = run(suite)
            %
            %       % Create a suite for all parameterized Test methods in MyTest
            %       suite = TestSuite.fromClass(?MyTest, HasParameter);
            %       result = run(suite)
            %
            %       % Create a suite for Test methods in class MyTest that
            %       % have a tag "Unit"
            %       suite = TestSuite.fromClass(?MyTest, HasTag('Unit'));
            %       result = run(suite)
            %
            %   See also: TestRunner, TestSuite.fromMethod, TestSuite.fromNamespace, matlab.unittest.selectors
            %
            
            import matlab.unittest.Test;
            
            narginchk(1,Inf);
            
            parser = parseInputs(varargin{:});
            externalParameters = parser.Results.ExternalParameters;            
            modifier = parsingResultsToModifier(parser);
            
            suite = Test.fromClass(testClass, modifier, externalParameters);
        end
        
        function suite = fromMethod(testClass, testMethod, varargin)
            % fromMethod - Create a suite from a single test method
            %
            %   SUITE = matlab.unittest.TestSuite.fromMethod(TESTCLASS, TESTMETHOD)
            %   creates a TestSuite from the test class described by TESTCLASS and the
            %   test method described by TESTMETHOD and returns it in SUITE. TESTCLASS
            %   is a meta.class instance which describes the desired test class. The
            %   test class described by TESTCLASS must be a subclass of
            %   matlab.unittest.TestCase. Additionally, this test class must be on the
            %   MATLAB path when creating the TestSuite using this method as well as
            %   when the test is run. TESTMETHOD is either the meta.method instance
            %   which describes the desired test method or the name of the desired test
            %   method as a string or a character vector. The method must be defined
            %   with a true Test method attribute.
            %
            %   SUITE = matlab.unittest.TestSuite.fromMethod(TESTCLASS, TESTMETHOD, ATTRIBUTE_1, CONSTRAINT_1, ...)
            %   creates a TestSuite array from the test class described by TESTCLASS
            %   and the test method described by TESTMETHOD that satisfy the specified
            %   conditions. Specify any of the following attributes:
            %
            %       * Name              - Name of the suite element
            %       * ProcedureName     - Name of the test procedure in the test
            %       * Superclass        - Name of a class that the test class derives
            %                             from
            %       * BaseFolder        - Name of the folder that holds the file
            %                             defining the test class or function.
            %       * ParameterProperty - Name of a property that defines a
            %                             Parameter used by the suite element
            %       * ParameterName     - Name of a Parameter used by the suite element
            %       * Tag               - Name of a tag defined on the suite element. 
            %
            %   The value of each attribute is specified as a string array, character vector, 
            %   or cell array of character vectors. For all attributes except Superclass, the 
            %   value can contain wildcard characters "*" (matches any number of characters, 
            %   including zero) and "?" (matches exactly one character). A test is included 
            %   in the suite only if it satisfies the criteria specified by all attributes. 
            %   For each attribute, the test element must satisfy at least one of the options
            %   specified for that attribute.
            %
            %   SUITE = matlab.unittest.TestSuite.fromMethod(TESTCLASS, TESTMETHOD, SELECTOR)
            %   creates a TestSuite array from the test class described by
            %   TESTCLASS and the test method described by TESTMETHOD that
            %   satisfy the SELECTOR.
            %
            %   SUITE = matlab.unittest.TestSuite.fromMethod(__, 'ExternalParameters', PARAM)
            %   allows the suite to use PARAM, an array of matlab.unittest.parameters.Parameter
            %   instances. The framework uses the external parameters in place of
            %   corresponding parameters that are defined within a parameterized test.
            %
            %   Examples:
            %       import matlab.unittest.TestSuite;
            %       import matlab.unittest.selectors.HasParameter;
            %
            %       cls = ?mynamespace.MyTestClass;
            %
            %       % Create the suite using the method name
            %       suite = TestSuite.fromMethod(cls, 'testMethod');
            %       result = run(suite)
            %
            %       % Create the suite using the meta.method instance
            %       metaMethod = findobj(cls.MethodList, 'Name', 'testMethod');
            %       suite = TestSuite.fromMethod(cls, metaMethod);
            %       result = run(suite)
            %
            %       % Create a suite for only certain parameters
            %       suite = TestSuite.fromMethod(cls, 'testMethod', ...
            %           HasParameter('Name','Param*'));
            %       result = run(suite)
            %
            %   See also: TestRunner, TestSuite.fromClass, TestSuite.fromNamespace, matlab.unittest.selectors
            %
            
            import matlab.unittest.Test;
            
            narginchk(2,Inf);
            
            parser = parseInputs(varargin{:});
            externalParameters = parser.Results.ExternalParameters;
            modifier = parsingResultsToModifier(parser);
            suite = Test.fromMethod(testClass, testMethod, modifier, externalParameters);
        end
        
        function suite = fromNamespace(namespace, varargin)
            % fromNamespace - Create a suite from all tests in a namespace
            %
            %   SUITE = matlab.unittest.TestSuite.fromNamespace(NAMESPACE) creates a
            %   TestSuite array from all of the tests defined in classes, functions,
            %   and scripts contained in NAMESPACE and returns that array in SUITE.
            %   NAMESPACE is a string or a character vector corresponding to the name of
            %   the desired namespace to find tests. The method is not recursive,
            %   returning only those tests directly in the namespace specified.
            %
            %   SUITE = matlab.unittest.TestSuite.fromNamespace(NAMESPACE, "IncludingInnerNamespaces", true)
            %   creates a TestSuite array from all of the tests defined in classes,
            %   functions, and scripts contained in NAMESPACE and any of its inner namespaces.
            %
            %   SUITE = matlab.unittest.TestSuite.fromNamespace(NAMESPACE,'InvalidFileFoundAction','error') 
            %   aborts test suite creation and throws an error if any of the files in 
            %   NAMESPACE contain invalid code. You can specify InvalidFileFoundAction as 
            %   'warn' or 'error'. By default, the method issues a warning for each invalid file, 
            %   and includes the tests from the valid files in the suite.
            %
            %   SUITE = matlab.unittest.TestSuite.fromNamespace(NAMESPACE, ATTRIBUTE_1, CONSTRAINT_1, ...)
            %   creates a TestSuite array from all of the tests defined in classes,
            %   functions, and scripts contained in NAMESPACE that satisfy the specified
            %   conditions. Specify any of the following attributes:
            %
            %       * Name                  - Name of the suite element.
            %       * ProcedureName         - Name of the test procedure in the test.
            %       * Superclass            - Name of a class that the test class derives
            %                                 from.            
            %       * BaseFolder            - Name of the folder that holds the file
            %                                 defining the test class or function.
            %       * ParameterProperty     - Name of a property that defines a
            %                                 Parameter used by the suite element.
            %       * ParameterName         - Name of a Parameter used by the suite element
            %       * Tag                   - Name of a tag defined on the suite element.
            %
            %   The value of each attribute is specified as a string array, character vector, 
            %   or cell array of character vectors. For all attributes except Superclass, the 
            %   value can contain wildcard characters "*" (matches any number of characters, 
            %   including zero) and "?" (matches exactly one character). A test is included 
            %   in the suite only if it satisfies the criteria specified by all attributes. 
            %   For each attribute, the test element must satisfy at least one of the options
            %   specified for that attribute.
            %
            %   SUITE = matlab.unittest.TestSuite.fromNamespace(NAMESPACE, SELECTOR)
            %   creates a TestSuite array from all of the Test methods of
            %   all concrete TestCase classes contained in NAMESPACE that
            %   satisfy the SELECTOR.
            %
            %   SUITE = matlab.unittest.TestSuite.fromNamespace(__, 'ExternalParameters', PARAM)
            %   allows the suite to use PARAM, an array of matlab.unittest.parameters.Parameter
            %   instances. The framework uses the external parameters in place of
            %   corresponding parameters that are defined within parameterized tests.           
            %
            %   The base folder(s) where NAMESPACE is defined must be on the MATLAB path
            %   when creating SUITE using this method as well as when SUITE is run.
            %
            %   Examples:
            %       import matlab.unittest.TestSuite;
            %
            %       suite = TestSuite.fromNamespace('mynamespace.innernamespace');
            %       result = run(suite)
            %
            %       % Create a suite for all parameterized Test methods in mynamespace
            %       suite = TestSuite.fromNamespace('mynamespace', HasParameter);
            %       result = run(suite)
            %                   
            %
            %   See also: TestRunner, TestSuite.fromClass, TestSuite.fromMethod, matlab.unittest.selectors
            %

            import matlab.unittest.Test;
            import matlab.unittest.TestSuite;
            import matlab.unittest.internal.resolveAliasedLogicalParameters;
            import matlab.unittest.internal.mustBeTextScalar;
            import matlab.unittest.internal.mustContainCharacters;
            import matlab.unittest.internal.testSuiteFileExtensionServices;

            narginchk(1,Inf);

            mustBeTextScalar(namespace,'namespace');
            mustContainCharacters(namespace,'namespace');

            parser = matlab.unittest.internal.testSuiteInputParser;
            parser.addParameter("IncludingInnerNamespaces",false, @(x)validateIncludingSub(x,"IncludingInnerNamespaces"));
            parser.addParameter("IncludeInnerNamespaces",false, @(x)validateIncludingSub(x,"IncludeInnerNamespaces")); % supported alias
            parser.addParameter('IncludingSubpackages',false, @(x)validateIncludingSub(x,'IncludingSubpackages')); % supported alias
            parser.addParameter('IncludeSubpackages',false, @(x)validateIncludingSub(x,'IncludeSubpackages')); % supported alias
            parser.addParameter('InvalidFileFoundAction','warn', @validateBehaviorString);
            parser.parse(varargin{:});
            results = parser.Results;
            externalParameters = results.ExternalParameters;
            explicitlySpecifiedResults = rmfield(results, parser.UsingDefaults);
            includeInnerNamespaces = resolveAliasedLogicalParameters(explicitlySpecifiedResults, ...
                ["IncludingInnerNamespaces","IncludeInnerNamespaces","IncludingSubpackages","IncludeSubpackages"]);
            invalidFileFoundAction = {"InvalidFileFoundAction", parser.Results.InvalidFileFoundAction};
            modifier = parsingResultsToModifier(parser);
            rejector = modifier.getRejector;

            namespaceMetadata = meta.package.fromName(namespace);
            if isempty(namespaceMetadata)
                error(message("MATLAB:unittest:TestSuite:InvalidNamespace", namespace));
            end

            suite = TestSuite.fromNamespaceCore_(namespaceMetadata, rejector, externalParameters, includeInnerNamespaces, invalidFileFoundAction{:});
            suite = modifier.apply(suite);
        end
        
        function suite = fromFolder(folder, varargin)
            % fromFolder - Create a suite from all tests in a folder
            %
            %   SUITE = matlab.unittest.TestSuite.fromFolder(FOLDER) creates a
            %   TestSuite array from all of the Test methods of all concrete TestCase
            %   classes contained in FOLDER and returns that array in SUITE. FOLDER is
            %   a string or character vector corresponding to the name of the desired
            %   folder to find tests. FOLDER can either be an absolute or relative path
            %   to the desired folder. FOLDER can contain namespace folders along with 
            %   regular folders.
            %
            %   SUITE = matlab.unittest.TestSuite.fromFolder(FOLDER, 'IncludingSubfolders', true)
            %   creates a TestSuite array from all of the Test methods of all
            %   concrete TestCase classes contained in FOLDER and any of its
            %   subfolders, excluding class and private folders.
            %
            %   SUITE = matlab.unittest.TestSuite.fromFolder(FOLDER,'InvalidFileFoundAction','error') 
            %   aborts test suite creation and throws an error if any of the files in 
            %   FOLDER contain invalid code. You can specify InvalidFileFoundAction as 
            %   'warn' or 'error'. By default, the method issues a warning for each invalid file, 
            %   and includes the tests from the valid files in the suite.
            %
            %   SUITE = matlab.unittest.TestSuite.fromFolder(FOLDER, ATTRIBUTE_1, CONSTRAINT_1, ...)
            %   creates a TestSuite array from all of the Test methods of all concrete
            %   TestCase classes contained in FOLDER that satisfy the specified
            %   conditions. Specify any of the following attributes:
            %
            %       * Name                  - Name of the suite element
            %       * ProcedureName         - Name of the test procedure in the test
            %       * Superclass            - Name of a class that the test class derives
            %                                 from.
            %       * BaseFolder            - Name of the folder that holds the file
            %                                 defining the test class or function.
            %       * ParameterProperty     - Name of a property that defines a
            %                                 Parameter used by the suite element
            %       * ParameterName         - Name of a Parameter used by the suite element
            %       * Tag                   - Name of a tag defined on the suite element.
            %
            %   The value of each attribute is specified as a string array, character vector, 
            %   or cell array of character vectors. For all attributes except Superclass, the 
            %   value can contain wildcard characters "*" (matches any number of characters, 
            %   including zero) and "?" (matches exactly one character). A test is included 
            %   in the suite only if it satisfies the criteria specified by all attributes. 
            %   For each attribute, the test element must satisfy at least one of the options
            %   specified for that attribute.
            %
            %   SUITE = matlab.unittest.TestSuite.fromFolder(FOLDER, SELECTOR) creates
            %   a TestSuite array from all of the Test methods of all concrete TestCase
            %   classes contained in FOLDER that satisfy the SELECTOR.
            %
            %   SUITE = matlab.unittest.TestSuite.fromFolder(__, 'ExternalParameters', PARAM)
            %   allows the suite to use PARAM, an array of matlab.unittest.parameters.Parameter
            %   instances. The framework uses the external parameters in place of
            %   corresponding parameters that are defined within parameterized tests.           
            %
            %   Examples:
            %       import matlab.unittest.TestSuite;
            %
            %       suite = TestSuite.fromFolder(pwd);
            %       result = run(suite)
            %
            %       % Include only select folders
            %       suite = TestSuite.fromFolder(pwd, 'IncludingSubfolders',true, ...
            %           'BaseFolder','TestFeature1');
            %       result = run(suite)
            %           
            %
            %   See also: TestRunner, TestSuite.fromFile, matlab.unittest.selectors
            %
            
            import matlab.unittest.TestSuite;
            import matlab.unittest.internal.folderResolver;
            import matlab.unittest.internal.resolveAliasedLogicalParameters;
            
            narginchk(1,Inf);
            parser = matlab.unittest.internal.testSuiteInputParser;
            parser.addParameter('IncludingSubfolders',false, @(x)validateIncludingSub(x,'IncludingSubfolders'));
            parser.addParameter('IncludeSubfolders',false, @(x)validateIncludingSub(x,'IncludeSubfolders')); % supported alias
            parser.addParameter('InvalidFileFoundAction','warn', @validateBehaviorString);
            parser.parse(varargin{:});
            results = parser.Results;
            externalParameters = results.ExternalParameters;
            explicitlySpecifiedResults = rmfield(results, parser.UsingDefaults);
            includeSubfolders = resolveAliasedLogicalParameters(explicitlySpecifiedResults, ["IncludingSubfolders","IncludeSubfolders"]);
            invalidFileFoundAction = {"InvalidFileFoundAction", results.InvalidFileFoundAction};
            modifier = parsingResultsToModifier(parser);
            rejector = modifier.getRejector;
            fullFolderPath = folderResolver(folder);
            suite = TestSuite.fromFolderCore_(fullFolderPath, rejector, externalParameters, includeSubfolders, invalidFileFoundAction{:});
            suite = modifier.apply(suite);
        end
    end
    
    methods(Sealed)
        function results = run(suite)
            % RUN - Run test suite using default test runner
            %
            %   RESULT = RUN(SUITE) runs the test suite defined by SUITE using a
            %   default runner, which is similar to the runner configured by default
            %   for runtests. RESULT is a matlab.unittest.TestResult array, where each
            %   TestResult object corresponds to an element of SUITE.
            %
            %   Example:
            %       suite = testsuite("mynamespace.MyTestClass");
            %       result = run(suite)
            %
            %   See also: TestRunner, TestCase, TestResult
            %

            runner = testrunner;
            results = runner.run(suite);
        end
        
        function newSuite = selectIf(suite, varargin)
            % SELECTIF - Select suite elements that satisfy one or more constraints
            %
            %   NEWSUITE = SELECTIF(SUITE, ATTRIBUTE_1, CONSTRAINT_1, ..., ATTRIBUTE_N, CONSTRAINT_N)
            %   returns in NEWSUITE the TestSuite elements in SUITE that satisfy the
            %   specified conditions. This method accepts any number of the following
            %   name/value pairs:
            %
            %       * Name              - Name of the suite element
            %       * ProcedureName     - Name of the test procedure in the test
            %       * Superclass        - Name of a class that the test class derives
            %                             from
            %       * BaseFolder        - Name of the folder that holds the file
            %                             defining the test class or function.
            %       * ParameterProperty - Name of a property that defines a
            %                             Parameter used by the suite element
            %       * ParameterName     - Name of a Parameter used by the suite element
            %       * Tag               - Name of a tag defined on the suite element. 
            %
            %   The value of each attribute is specified as a string array, character vector, 
            %   or cell array of character vectors. For all attributes except Superclass, the 
            %   value can contain wildcard characters "*" (matches any number of characters, 
            %   including zero) and "?" (matches exactly one character). A test is included 
            %   in the suite only if it satisfies the criteria specified by all attributes. 
            %   For each attribute, the test element must satisfy at least one of the options
            %   specified for that attribute.
            %
            %   NEWSUITE = SELECTIF(SUITE, SELECTOR) returns in NEWSUITE the TestSuite
            %   elements in SUITE that satisfy the conditions specified by SELECTOR.
            %
            %   Example:
            %       import matlab.unittest.TestSuite;
            %       import matlab.unittest.selectors.HasSharedTestFixture;
            %       import matlab.unittest.selectors.HasParameter;
            %       import matlab.unittest.selectors.HasTag;            
            %       import matlab.unittest.fixtures.PathFixture;
            %       import matlab.unittest.constraints.StartsWithSubstring;
            %
            %       suite = TestSuite.fromClass(?mynamespace.MyTestClass);
            %
            %       % Select TestSuite array elements for test methods whose names end
            %       % with the string "bar".
            %       newSuite = suite.selectIf('Name', '*bar');
            %
            %       % Select TestSuite array elements using a parameter defined by a
            %       % property named "Param1" with parameter name "Foo"
            %       newSuite = suite.selectIf('ParameterProperty','Param1', 'ParameterName','Foo');
            %
            %       % Select TestSuite array elements for classes defined in a folder
            %       % named "testBar".
            %       suite = TestSuite.fromFolder(pwd, 'IncludingSubfolders', true);
            %       newSuite = suite.selectIf('BaseFolder', [filesep, '*testBar']);
            %
            %       % Select TestSuite array elements which use a PathFixture
            %       newSuite = suite.selectIf(HasSharedTestFixture(PathFixture));
            %
            %       % Select TestSuite array elements that are not parameterized and
            %       % whose name begins with "foobar".
            %       newSuite = suite.selectIf(~HasParameter & HasName(StartsWithSubstring('foobar')));
            %
            %       % Select TestSuite array elements that have tag
            %       % "foo"
            %       newSuite = suite.selectIf(HasTag('foo'));
            %   
            %       % Select TestSuite array elements that do not have a
            %       % tag "bar"
            %       newSuite = suite.selectIf(~HasTag('bar'));
            %   
            %   See also: matlab.unittest.constraints, matlab.unittest.selectors
            %

            import matlab.unittest.internal.testSuiteInputParser;
            import matlab.unittest.internal.selectors.getSuiteModifier;

            narginchk(2, Inf);
            nameValueLiaison = testSuiteInputParser(OnlySelectors=true);
            nameValueLiaison.parse(varargin{:});
            results = rmfield(nameValueLiaison.Results, nameValueLiaison.UsingDefaults);
            selector = getSuiteModifier(results, OnlySelectors=true);
            newSuite = suite.selectIfCore_(selector);
        end
        
        function [suite, I] = sortByFixtures(suite)
            %SORTBYFIXTURES - Sort a suite of tests based on its fixtures
            %
            % NEWSUITE = SORTBYFIXTURES(SUITE) returns a TestSuite NEWSUITE
            % that is a permutation of the test elements of SUITE.
            %
            % [NEWSUITE, I] = SORTBYFIXTURES(SUITE) also returns a sort
            % index I that describes how the elements of SUITE are
            % rearranged to obtain NEWSUITE. Specifically, NEWSUITE = SUITE(I).
            %
            % sortByFixtures reorders the suite to reduce shared fixture
            % setup and teardown operations. Do not rely on the order of
            % elements in NEWSUITE as it might change in a future release.
            %
            % Example:
            %
            %   import matlab.unittest.TestSuite;
            %
            %   % Create a suite from 3 different classes
            %   suiteA = TestSuite.fromClass(?MyTestClassA);
            %   suiteB = TestSuite.fromClass(?MyTestClassB);
            %   suiteC = TestSuite.fromClass(?MyTestClassC);
            %   suite = [suiteA suiteB suiteC];
            %
            %   % Sort the suite based on fixtures
            %   newSuite = sortByFixtures(suite);
            
            import matlab.unittest.internal.sortFixtureRequirements;
            
            A = getFixtureRequirementMatrix(suite);
            [~,I] = sortFixtureRequirements(A);
            
            I = reshape(I, size(suite));
            suite = suite(I);
        end
    end

    methods (Hidden, Sealed, Static)
        function varargout = fromPackage(varargin)
            % Undocumented alias; discouraged use.
            [varargout{1:nargout}] = matlab.unittest.TestSuite.fromNamespace(varargin{:});
        end

        function suite = fromFileCore_(testFile, modifier, externalParameters)
            [liaison, supportingService] = fromFileServiceLocation(testFile);
            folderTeardown = temporarilyChangeFolderIfNeeded(liaison.ContainingFolder); %#ok<NASGU>
            suite = supportingService.createSuiteExplicitly(liaison, modifier, externalParameters);
            suite = suite.addInternalPathAndCurrentFolderFixtures(liaison.ContainingFolder);
        end

        function suite = fromFileImplicitly_(testFile, modifier, externalParameters, varargin)
            [liaison, supportingService] = fromFileServiceLocation(testFile);
            folderTeardown = temporarilyChangeFolderIfNeeded(liaison.ContainingFolder); %#ok<NASGU>
            suite = supportingService.createSuiteImplicitly(liaison, modifier, externalParameters, varargin{:});
            suite = suite.addInternalPathAndCurrentFolderFixtures(liaison.ContainingFolder);
        end

        function suite = fromFolderCore_(folder, rejector, externalParameters, includeSubfolders, varargin)
            import matlab.unittest.Test;
            import matlab.unittest.TestSuite;
            import matlab.unittest.internal.selectors.AttributeSet;
            import matlab.unittest.internal.selectors.BaseFolderAttribute;
            import matlab.unittest.internal.testSuiteFileExtensionServices;

            validateNoClassAndPrivateFromFolder(leafFolderGenerator(folder));

            if rejector.uses(?matlab.unittest.internal.selectors.BaseFolderAttribute) && ...
                    rejector.reject(AttributeSet(BaseFolderAttribute(folder), 1))
                % If the selector rejects the folder, we need not examine
                % any content at all inside the folder.
                suite = Test.empty(1,0);
            else
                % Make sure these tests are in the current folder while we construct the suite.
                [cl, baseFolder] = temporarilyChangeFolderIfNeeded(folder); %#ok<ASGLU>

                suite = createSuiteForFilesInFolder(testSuiteFileExtensionServices, folder,...
                    rejector, externalParameters, varargin{:});
                suite = suite.addInternalPathAndCurrentFolderFixtures(baseFolder);
            end

            % Recursively build up suites in subfolders
            if includeSubfolders
                fileAndFolderInfo = dir(folder);
                subfolderNames = {fileAndFolderInfo([fileAndFolderInfo.isdir]).name};
                subfolders = fullfile(folder,string(filterSubfolders(subfolderNames, folder)));
                subSuites = arrayfun(@(fld) TestSuite.fromFolderCore_(fld, rejector, ...
                    externalParameters, true, varargin{:}), subfolders, UniformOutput=false);
                suite = [suite, subSuites{:}];
            end
        end

        function suite = fromNamespaceCore_(namespace, rejector, externalParameters, includeInnerNamespaces, varargin)
            import matlab.unittest.Test;
            import matlab.unittest.TestSuite;
            import matlab.unittest.internal.testSuiteFileExtensionServices;

            folderName = ['+', strrep(namespace.Name, '.', [filesep, '+'])];
            allFolderInfo = what(folderName);
            allFolderInfo = allFolderInfo(endsWith({allFolderInfo.path}, folderName)); % case sensitive match

            services = testSuiteFileExtensionServices;
            services = services([services.IncludedInNamespaces]);

            allSuites = arrayfun(@(folderInfo)createSuiteForFilesInFolder(services, folderInfo.path,...
                rejector, externalParameters, varargin{:}), ...
                allFolderInfo, "UniformOutput",false);
            suite = [Test.empty, allSuites{:}];

            % Recursively build up suites in any inner namespaces.
            if includeInnerNamespaces
                subSuites = arrayfun(@(pk)TestSuite.fromNamespaceCore_(pk, rejector, ...
                    externalParameters, true, varargin{:}), [namespace.PackageList], UniformOutput=false);

                suite = [suite, subSuites{:}];
            end
        end
    end

    methods (Sealed, Hidden)
        function A = getFixtureRequirementMatrix(suite)
            % Returns a logical matrix A where A(i,j) iff Test(i) requires
            % Fixture(j) where Fixture is an array of all unique (and
            % incompatible) fixtures used in the suite. The term "fixture"
            % is used loosely to represent different levels of
            % setup/teardown scopes.
            
            nSuites = numel(suite);
            if nSuites == 0
                A = logical.empty;
                return;
            end
            
            fixtures = {suite.SharedTestFixtures};
            internalFixtures = {suite.InternalSharedTestFixtures};
            fixtures = cellfun(@horzcat, fixtures, internalFixtures, 'UniformOutput', false);
            
            nFixturesPerSuite = cellfun(@numel, fixtures);
            startIdx = cumsum([1 nFixturesPerSuite]);
            
            F = [fixtures{:}];
            [f, ~, J1] = getUniqueFixtureInstances(F);
            
            % remove off-path fixtures from the analysis
            onpathMask = isOnPath(f);
            f = f(onpathMask);
            
            % map back to all instances
            [~,~,P] = unique(J1);
            onpathMask = onpathMask(P);
            
            % update the start indices
            nRemoveFromEach = zeros(1,nSuites);
            for k=1:nSuites
                fixIdx = startIdx(k):startIdx(k+1)-1;
                nRemoveFromEach(k) = nnz(~onpathMask(fixIdx));
            end
            startIdx = startIdx - cumsum([0 nRemoveFromEach]);
            
            % update the index maps
            fInd = find(~onpathMask);
            J1 = J1(onpathMask);
            for k=flip(fInd)
                mask = J1 > k;
                J1(mask) = J1(mask) - 1;
            end
            
            % recalculate unique instances from only on-path fixtures
            [~, I2, J2] = getUniqueTestFixtures(f);
            
            % map back to the superset of distinct fixtures
            [~,~,P] = unique(J1);
            [~,~,Q] = unique(J2);
            fixmap = Q(P);
            
            A = false(nSuites, length(I2));
            for k=1:nSuites
                % Walk through each suite's fixtures and analyze that section on the
                % flattened array
                fixIdx = startIdx(k):startIdx(k+1)-1;
                
                % back map down to unique list
                fixIdx = fixmap(fixIdx);
                A(k,fixIdx) = true;
            end
            
            % Append this with a matrix for Class boundaries
            markers = [suite.ClassBoundaryMarker];
            [~,uniqMarkerInd,markerSeq] = unique(markers,'stable');
            classMarkerMatrix = false(nSuites, length(uniqMarkerInd));
            markerInd = sub2ind(size(classMarkerMatrix), (1:nSuites).', markerSeq);
            classMarkerMatrix(markerInd) = true;
            
            A = [A classMarkerMatrix];
        end

        function newSuite = selectIfCore_(suite, selector)
            attributeUsage = evaluateAttributeUsage(selector);
            attributeSet = matlab.unittest.internal.selectors.AttributeSet.fromTestSuite(suite, attributeUsage);
            suiteIsSelected = selector.select(attributeSet);
            newSuite = suite(suiteIsSelected);
        end
    end
    
    methods(Hidden, Access = protected)
        function suite = TestSuite
        end
    end
end

function parser = parseInputs(varargin)
parser = matlab.unittest.internal.testSuiteInputParser;
parser.parse(varargin{:});
end
          
function modifier = parsingResultsToModifier(parser)
import matlab.unittest.internal.selectors.getSuiteModifier;

results = rmfield(parser.Results, parser.UsingDefaults);
modifier = getSuiteModifier(results);
end

function [restore, newFolderPath] = temporarilyChangeFolderIfNeeded(folder)
[folderRoot,folderPart] = fileparts(folder);

while(startsWith(folderPart,"+"))
    folder = folderRoot;
    [folderRoot,folderPart] = fileparts(folder);
end

newFolderPath = folder;

restore = matlab.unittest.internal.Teardownable;
restore.addTeardown(@cd, cd(folder));
end

function validateIncludingSub(value,varname)
validateattributes(value,{'logical'},{'scalar'},'',varname);
end

function validateBehaviorString(value)
mustBeMember(value,["error","warn"]);
end

function leafFolder = leafFolderGenerator(folder)
    folders = regexp(folder, filesep, 'split');
    leafFolder = folders{end};
end

function validateNoPrivateFolderFromFile(folder)
    if identifyPrivateFolders(folder)
       error(message('MATLAB:unittest:TestSuite:FilesInPrivateFolderNotAllowed'));
    end
end

function validateNoClassAndPrivateFromFolder(folder)
    if identifyClassFolders(folder)
       error(message('MATLAB:unittest:TestSuite:ClassFolderNotAllowed'));
    elseif identifyPrivateFolders(folder)
       error(message('MATLAB:unittest:TestSuite:PrivateFolderNotAllowed'));
    end
end

function folders = filterSubfolders(folders, fullFolderPath)
validateTheFolderName(fullFolderPath);
folders(strcmp(folders, '.') | strcmp(folders, '..') | ...
    identifyClassFolders(folders) | ...
    identifyPrivateFolders(folders)) = [];
end

function validateTheFolderName(folderPath)
[~, folderPart] = fileparts(folderPath);
if(startsWith(folderPart,"+"))
    % extract "+" which prefixes the folderPart
    folderPart = extractAfter(folderPart,"+");
    if(~isvarname(folderPart) && ~iskeyword(folderPart))
        warning(message("MATLAB:unittest:TestSuite:InvalidNamespaceFolderName", folderPart));
    end
end
end

function mask = identifyClassFolders(folders)
mask = strncmp(folders, '@', 1);
end

function mask = identifyPrivateFolders(folders)
mask = strcmp(folders, 'private');
end

function [liaison, supportingService] = fromFileServiceLocation(testFile)
    import matlab.unittest.internal.services.fileextension.FileExtensionLiaison;

    liaison  = FileExtensionLiaison(testFile);
    validateNoPrivateFolderFromFile(leafFolderGenerator(liaison.ContainingFolder));

    services = matlab.unittest.internal.testSuiteFileExtensionServices;
    fulfill(services, liaison);
    supportingService = services.findServiceThatSupports(liaison.Extension);
end

function suite = createSuiteForFilesInFolder(fileExtensionServices, folder,...
    modifier, externalParameters, varargin)
import matlab.unittest.Test;
import matlab.unittest.internal.services.fileextension.FileExtensionLiaison;

filesInFolder = dir(folder);
filesInClassFolders = dir(fullfile(folder, "@*", "*.*"));
[~, classFolderFiles] = fileparts({filesInClassFolders.name});
[~, classFolders] = fileparts({filesInClassFolders.folder});
classFiles = filesInClassFolders("@" + classFolderFiles == classFolders);
fileAndFolderInfo = [filesInFolder; classFiles];
files = fileAndFolderInfo(~[fileAndFolderInfo.isdir]);
files = fullfile({files.folder}, {files.name});
files = files(isfile(files));
nFiles = numel(files);
testSuites = cell(1, nFiles);
for idx = 1:nFiles
    liaison = FileExtensionLiaison(files{idx});
    supportingService = fileExtensionServices.findServiceThatSupports(liaison.Extension);
    if ~isempty(supportingService)
        testSuites{idx} = supportingService.createSuiteImplicitly(liaison, modifier,...
            externalParameters, varargin{:});
    end
end

% Build the suite from the cell array of individual suites
suite = [Test.empty, testSuites{:}];
end

function attributeUsage = evaluateAttributeUsage(selector)

attributeUsage.UsesBaseFolder = selector.uses(?matlab.unittest.internal.selectors.BaseFolderAttribute);
attributeUsage.UsesName = selector.uses(?matlab.unittest.internal.selectors.NameAttribute);
attributeUsage.UsesParameter = selector.uses(?matlab.unittest.internal.selectors.ParameterAttribute);
attributeUsage.UsesSharedTestFixture = selector.uses(?matlab.unittest.internal.selectors.SharedTestFixtureAttribute);
attributeUsage.UsesTag = selector.uses(?matlab.unittest.internal.selectors.TagAttribute);
attributeUsage.UsesProcedureName = selector.uses(?matlab.unittest.internal.selectors.ProcedureNameAttribute);
attributeUsage.UsesSuperclass = selector.uses(?matlab.unittest.internal.selectors.SuperclassAttribute);
attributeUsage.UsesFilename = selector.uses(?matlab.unittest.internal.selectors.FilenameAttribute);

end

% LocalWords:  TESTCLASS TESTMETHOD cls Subfolders PFile testrunner ASGLU mynamespace innernamespace
% LocalWords:  subfolders mclass SELECTIF abc CDs NEWSUITE isscript isfile Subpackages
% LocalWords:  fld Teardownable mlx mtfind isnull
% LocalWords:  namingconvention Parameterizations fileextension MFile varname
% LocalWords:  mydata subfolder SORTBYFIXTURES onpath fixmap uniq
% LocalWords:  testfolderprovider
