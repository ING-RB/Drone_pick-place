function results = runperf(varargin)
% runperf - Run a set of tests as a performance experiment.
%
%   The runperf function provides a simple way to run a collection of
%   tests as a performance experiment.
%
%   RESULT = runperf(TESTS) creates a test suite specified by TESTS, runs
%   them using a variable sample time experiment, and returns the RESULT.
%   TESTS can be a string scalar or character vector containing the name of
%   a test element, a test class, a test file, a namespace that contains the
%   tests, or a folder that contains the test files. TESTS can also be a
%   string array or cell array of character vectors.
%
%   RESULT = runperf(TESTS, NAME, VALUE, ...) supports those name-value
%   pairs of the testsuite function.
%   
%
%   Examples:
%
%       % Run tests using a variety of methods.
%       results = runperf('mynamespace.MyTestClass')
%       results = runperf('SomeTestFile.m')
%       results = runperf(pwd)
%       results = runperf('mynamespace.innernamespace')
%       results = runperf('MyTestClass/MyTestMethod')
%
%       % Run them all in one function call
%       result = runperf({'mynamespace.MyTestClass', 'SomeTestFile.m', ...
%            pwd, 'mynamespace.innernamespace', 'MyTestClass/MyTestMethod'})
%
%       % Run all the tests in the current folder and any subfolders, but
%       % require that the name "feature1" appear somewhere in the folder name.
%       result = runperf(pwd, 'IncludeSubfolders', true, 'BaseFolder', '*feature1*');
%
%       % Run all the tests in the current folder and any subfolders that
%       % have a tag "featureA".
%       result = runperf(pwd, 'IncludeSubfolders', true, 'Tag', 'featureA');
% 
%   See also: runtests, testsuite, matlab.unittest.TestSuite, matlab.perftest.TimeExperiment, matlab.unittest.measurement.MeasurementResult

% Copyright 2015-2023 The MathWorks, Inc.

import matlab.perftest.TimeExperiment;

suites = testsuite(varargin{:});
experiment = TimeExperiment.limitingSamplingError;

results = experiment.run(suites);

end

% LocalWords:  mynamespace innernamespace perftest
