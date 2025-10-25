function suite = testsuite(varargin)
% testsuite - Create a suite of tests.
%
%   The testsuite function provides a simple way to create a suite for a
%   collection of tests.
%
%   SUITE = testsuite(TESTS) creates a test suite specified by TESTS. TESTS
%   can be a string scalar or character vector containing the name of a
%   test element, a test class, a test file, a namespace that contains test files, 
%   the root folder of a project that contains test files, or a standard folder 
%   that contains the test files. TESTS can also be a string array or cell array 
%   of character vectors.
%
%   SUITE = testsuite(TESTS, 'IncludeSubfolders', true) also includes all
%   the tests defined in the subfolders of any specified folders.
%
%   SUITE = testsuite(TESTS, 'IncludeInnerNamespaces', true) also includes all
%   the tests defined in the inner namespaces of any specified namespaces.
%
%   SUITE = testsuite(TESTS, 'IncludeReferencedProjects', true) also includes 
%   all the tests defined in the referenced projects of any specified project.
%
%   SUITE = testsuite(TESTS,'InvalidFileFoundAction','error') aborts test suite 
%   creation and throws an error if any of the files in the TESTS folder or 
%   namespace contain invalid code. You can specify InvalidFileFoundAction as 
%   'warn' or 'error'. By default, the function issues a warning for each 
%   invalid file, and includes the tests from the valid files in the suite.
%
%   SUITE = testsuite(TESTS, ATTRIBUTE_1, CONSTRAINT_1, ...) creates a
%   suite for all the tests specified by TESTS that satisfy the specified
%   conditions. Specify any of the following attributes:
%
%       * Name                  - Name of the suite element
%       * ProcedureName         - Name of the test procedure in the test
%       * Superclass            - Name of a class that the test class derives
%                                 from
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
%
%   Examples:
%
%       % Create a suite using a variety of methods.
%       suite = testsuite('mynamespace.MyTestClass')
%       suite = testsuite('SomeTestFile.m')
%       suite = testsuite(pwd)
%       suite = testsuite('mynamespace.innernamespace')
%       suite = testsuite('MyTestClass/MyTestMethod')
%
%       % Create them all in one function call
%       suite = testsuite({'mynamespace.MyTestClass', 'SomeTestFile.m', ...
%            pwd, 'mynamespace.innernamespace', 'MyTestClass/MyTestMethod'})
%
%       % Include all the tests in the current folder and any subfolders, but
%       % require that the name "feature1" appear somewhere in the folder name.
%       suite = testsuite(pwd, 'IncludeSubfolders', true, 'BaseFolder', '*feature1*');
%
%       % Include all the tests in the current folder and any subfolders that
%       % have a tag "featureA".
%       suite = testsuite(pwd, 'IncludeSubfolders', true, 'Tag', 'featureA');
%
%       % Include all the tests in a project, specified by its root folder, and 
%       % any projects that the project references.
%       suite = testsuite('myProjectFolder', 'IncludeReferencedProjects', true);
%
%       % Abort suite creation and throw an error if the current folder 
%       % contains invalid test files.
%       suite = testsuite(pwd, 'InvalidFileFoundAction', 'error');
%
%       % Run the tests using the default test runner:
%       results = run(suite);
%
%       % Run the tests using a custom test runner:
%       runner = matlab.unittest.TestRunner.withNoPlugins;
%       results = run(runner, suite);
% 
%   See also: runtests, matlab.unittest.TestSuite

% Copyright 2015-2024 The MathWorks, Inc.

[tests, options] = matlab.unittest.internal.parseInformalTestSuiteArguments(varargin{:});

suite = matlab.unittest.internal.createTestSuite(tests, options);
end

% LocalWords:  Subfolders subfolders mynamespace innernamespace
