% coverageSummary - Retrieve coverage information from coverage results
%
%   coverage = coverageSummary(results,metric) retrieves coverage
%   information from the results about the specified coverage metric.
%   Valid metrics include "statement", "function", "decision", "condition", and "mcdc".
%
%   For N coverage results, the method returns an N-by-2 matrix. For each
%   result, the first column reports the number of executed outcomes, and the
%   second column reports the total number of executable outcomes.
%
%   [coverage,description] = coverageSummary(results,metric) also produces
%   a structured description of the metric within the results. description
%   is a structure containing source location information and the execution
%   count for each outcome within the code.
%
%   Example:
%
%       import matlab.unittest.plugins.CodeCoveragePlugin
%       import matlab.unittest.plugins.codecoverage.CoverageResult
%
%       % Create an instance of the CoverageResult class
%       format = CoverageResult();
%
%       % Create a CodeCoveragePlugin instance using the CoverageResult format
%       plugin = CodeCoveragePlugin.forFile("C:\projects\myproj\foo.m", ...
%            Producing=format);
%
%       % Create a test runner, configure it with the plugin, and run the tests
%       runner = testrunner;
%       runner.addPlugin(plugin)
%       runner.run(testsuite("C:\projects\myproj\tests\testFoo.m"));
%
%       % Access coverage results programmatically
%       results = format.Result
%
%       % Retrieve statement coverage information
%       coverage = coverageSummary(results,"statement")
%
%       % Retrieve statement coverage description
%       [~,description] = coverageSummary(results,"statement")
%
%       % Access description about the second statement
%       description.statement(2)
%
%   See also: matlab.coverage.Result
%

%   Copyright 2022-2024 The MathWorks, Inc.

function varargout = coverageSummary(resObj, metricName)

arguments
    resObj (:,1) matlab.coverage.Result
    metricName (1,1) string
end

try
    [varargout{1:nargout}] = coverageSummaryInternal(resObj, metricName);
catch Me
    throwAsCaller(Me);
end
