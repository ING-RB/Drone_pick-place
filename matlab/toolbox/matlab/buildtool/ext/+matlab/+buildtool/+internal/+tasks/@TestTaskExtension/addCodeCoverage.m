function task = addCodeCoverage(task, results, options)
% addCodeCoverage - Enable code coverage collection with TestTask instance
%
%   TASK = addCodeCoverage(TASK,RESULTS) enables a
%   matlab.buildtool.tasks.TestTask instance to produce the specified code
%   coverage results for the source defined in the SourceFiles property of
%   the task. You can produce code coverage results in various formats by
%   specifying RESULTS as a string vector, character vector, cell vector of
%   character vectors, or vector of matlab.buildtool.io.File objects.
%   Specify formats using file extensions:
%
%       * HTML - Produce an HTML coverage report.
%       * XML  - Produce coverage results in Cobertura XML format.
%       * MAT  - Store the matlab.coverage.Result array in a MAT-file.
%
%   Alternatively, you can specify RESULTS as a vector of
%   matlab.unittest.plugins.codecoverage.CoverageFormat objects.
%
%   TASK = addCodeCoverage(TASK,RESULTS,MetricLevel=LEVEL) specifies the
%   code coverage metrics to include in RESULTS. This list shows the
%   possible values of LEVEL and the corresponding metrics in the results:
%
%       * "statement" (default) - Statement and function coverage
%       * "decision" (requires MATLAB Test) - Statement, function, and decision coverage
%       * "condition" (requires MATLAB Test) - Statement, function, decision, and condition coverage
%       * "mcdc" (requires MATLAB Test) - Statement, function, decision, condition, and modified condition/decision coverage (MC/DC)
%
%   Examples:
%
%       % Import the TestTask class
%       import matlab.buildtool.tasks.TestTask
%
%       % Create a task to produce code coverage results in Cobertura XML format
%       % for the specified source code
%       task = TestTask("myTestFolder",SourceFiles="sourceFolder").addCodeCoverage("code-coverage/coverage.xml");
%
%       % Create a task to produce code coverage results in both Cobertura XML
%       % and HTML formats
%       task = TestTask("myTestFolder",SourceFiles="sourceFolder").addCodeCoverage(["code-coverage/coverage.xml" "code-coverage/html/index.html"]);
%
%       % Create a task to save the code coverage results to a MAT-file
%       % for programmatic access
%       task = TestTask("myTestFolder",SourceFiles="sourceFolder").addCodeCoverage("code-coverage/coverage.mat");
%
%       % Create a task to produce code coverage results in Cobertura XML
%       % format, including the statement, function, and decision coverage
%       % metrics (requires MATLAB Test)
%       task = TestTask("myTestFolder",SourceFiles="sourceFolder").addCodeCoverage("code-coverage/coverage.xml",MetricLevel="decision");
%
%       % Create a task to produce code coverage results in HTML format
%       % using the matlab.unittest.plugins.codecoverage.CoverageReport class
%       import matlab.unittest.plugins.codecoverage.CoverageReport
%       reportFolder = "coverageReport";
%       task = TestTask("myTestFolder",SourceFiles="sourceFolder").addCodeCoverage(CoverageReport(reportFolder,MainFile="cov.html"));
%
%   See also: matlab.buildtool.tasks.TestTask
%             matlab.unittest.plugins.CodeCoveragePlugin
%             matlab.unittest.plugins.codecoverage.CoberturaFormat
%             matlab.unittest.plugins.codecoverage.CoverageReport


% Copyright 2023-2024 The MathWorks, Inc.

arguments
    task (1,1) matlab.buildtool.tasks.TestTask
    results (1,:) {mustBeFileOrCoverageFormat(results, "Code")}
    options.MetricLevel (1,1) string {mustBeMember(options.MetricLevel, ["statement" "condition" "decision" "mcdc"])} = "statement"
end

import matlab.buildtool.internal.tasks.codecoverage.CodeCoverageSettings

task.CodeCoverageSettings = [task.CodeCoverageSettings CodeCoverageSettings(results, MetricLevel=options.MetricLevel)];

if ~hasCoverageResultsWithMatchingSettings(task.CodeCoverageSettings)
    error(message("MATLAB:buildtool:TestTask:CoverageResultsWithDisparateSettings"));
end
end

function tf = hasCoverageResultsWithMatchingSettings(codeCovSettings)
tf = isscalar(unique([codeCovSettings.MetricLevel]));
end

function mustBeFileOrCoverageFormat(varargin)
matlab.buildtool.internal.tasks.mustBeFileOrCoverageFormat(varargin{:});
end