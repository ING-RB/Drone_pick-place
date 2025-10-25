function [testResults,coverageResults] = runtests(varargin)
% runtests - Run a set of tests.
%
%   The runtests function provides a simple way to run a collection of
%   tests.
%
%   TESTRESULTS = runtests(TESTS) creates a test suite specified by TESTS, runs
%   them, and returns the TESTRESULTS. TESTS can be a string scalar or character
%   vector containing the name of a test element, a test class, a test
%   file, a namespace that contains test files, the root folder of a project that
%   contains test files, or a standard folder that contains the test files.
%   TESTS can also be a string array or cell array of character vectors.
%
%   TESTRESULTS = runtests(TESTS, 'UseParallel', true) runs the specified tests
%   using a parallel pool if available.  Testing will occur in parallel if
%   Parallel Computing Toolbox(TM) is installed and a parallel pool is
%   open. If there are no open parallel pools but automatic creation is
%   enabled in the parallel preferences, the default pool will be
%   automatically opened and testing will occur in parallel. If there are
%   no open parallel pools and automatic creation is disabled, or if
%   Parallel Computing Toolbox is not installed, testing will occur in
%   serial. Testing will occur in serial if the value is false or
%   unspecified. Testing in parallel might not be compatible with other
%   options. For example, testing will occur in serial when 'UseParallel'
%   and 'Debug' are both set to true.
%
%   TESTRESULTS = runtests(TESTS,'Debug',true) applies debugging capabilities
%   when running TESTS. For example, the framework pauses test execution to
%   enter debug mode if a test failure is encountered.
%
%   TESTRESULTS = runtests(TESTS,'Strict',true) applies strict checks while
%   running TESTS. For example, the framework generates a qualification
%   failure if a warning is issued during test execution.
%
%   TESTRESULTS = runtests(TESTS,'LoggingLevel',LOGGINGLEVEL) runs the specified
%   tests and reacts to the messages logged by calls to the
%   matlab.unittest.TestCase log method at LOGGINGLEVEL or lower. Specify
%   LOGGINGLEVEL as 'None', 'Terse', 'Concise', 'Detailed', or 'Verbose',
%   or as a numeric value between 0 to 4.
%
%   TESTRESULTS = runtests(TESTS,'OutputDetail',OUTPUTDETAIL) runs the specified
%   tests and displays test run progress and event information with the
%   amount of output detail specified by OUTPUTDETAIL. Specify OUTPUTDETAIL
%   as 'None', 'Terse', 'Concise', 'Detailed', or 'Verbose', or as a
%   numeric value between 0 to 4.
%
%   TESTRESULTS = runtests(TESTS, 'ReportCoverageFor', SOURCE) runs the
%   specified tests and produces a code coverage report for the code files
%   specified by SOURCE. The report shows the parts of SOURCE that were
%   executed by the specified tests. SOURCE can be an absolute or relative
%   path to one or more folders or to files that have a .m, .mlx or .mlapp
%   extension. Specify SOURCE as a string array, character vector, or cell
%   array of character vectors.
%
%   [TESTRESULTS, COVERAGERESULTS] = runtests(TESTS, 'ReportCoverageFor', SOURCE) 
%   runs the specified tests and provides programmatic access to coverage
%   results in addition to producing a code coverage report. The function
%   returns the results of the code coverage analysis, COVERAGERESULTS, as
%   a vector of matlab.coverage.Result objects. Each element of the vector
%   provides information about one of the files in SOURCE that was covered
%   by the tests.
%
%   TESTRESULTS = runtests(TESTS, NAME, VALUE, ...) also supports those
%   name-value arguments of the testsuite function.
%
%
%   Examples:
%
%       % Run tests using a variety of methods.
%       testResults = runtests('mynamespace.MyTestClass')
%       testResults = runtests('SomeTestFile.m')
%       testResults = runtests(pwd)
%       testResults = runtests('mynamespace.innernamespace')
%       testResults = runtests('MyTestClass/MyTestMethod')
%
%       % Run them all in one function call
%       testResults = runtests({'mynamespace.MyTestClass', 'SomeTestFile.m', ...
%            pwd, 'mynamespace.innernamespace', 'MyTestClass/MyTestMethod'})
%
%       % Run all the tests in the current folder and any subfolders, but
%       % require that the name "feature1" appear somewhere in the folder name.
%       testResults = runtests(pwd, 'IncludeSubfolders', true, 'BaseFolder', '*feature1*');
%
%       % Run all the tests in the current folder and any subfolders that
%       % have a tag "featureA".
%       testResults = runtests(pwd, 'IncludeSubfolders', true, 'Tag', 'featureA');
%
%       % Run all the tests in a project, specified by its root folder, and any
%       % projects that the project references.
%       testResults = runtests('myProjectFolder', 'IncludeReferencedProjects', true);
%
%       % Run all tests in the current folder with debugging capabilities and
%       % logging level "Verbose"
%       runtests(pwd,'Debug',true,'LoggingLevel','Verbose');
%
%       % Run all tests in the current folder and return coverage results
%       % for specified source code
%       [testResults, coverageResults] = runtests(pwd,'ReportCoverageFor','SourceFolder');
%
%   See also:
%       testsuite, matlab.unittest.TestSuite,
%       matlab.unittest.TestRunner, matlab.unittest.TestResult,
%       matlab.unittest.Verbosity, matlab.coverage.Result

% Copyright 2013-2023 The MathWorks, Inc.


[parseResults, suite] = matlab.unittest.internal.runtestsParser(@testsuite, varargin{:});
plugins = parseResults.Plugins;
runner = testrunner("minimal");
testOutputHandler = parseResults.Options.TestViewHandler_;

testResults = testOutputHandler.runTests(parseResults.Options, plugins, suite, runner);
coverageResults = parseResults.Options.GetCoverageResults_.Result;
end

% LocalWords:  subfolders isscript LOGGINGLEVEL OUTPUTDETAIL mlx mlapp Distrib COVERAGERESULTS
% LocalWords:  gcp Wrappable strlength testrunner mynamespace innernamespace
