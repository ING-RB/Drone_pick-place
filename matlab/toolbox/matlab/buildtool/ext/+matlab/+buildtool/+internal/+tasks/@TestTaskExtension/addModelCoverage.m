function task = addModelCoverage(task, results, options)
% addModelCoverage - Enable model coverage collection with TestTask instance
%
%   TASK = addModelCoverage(TASK,RESULTS) enables a
%   matlab.buildtool.tasks.TestTask instance to produce the specified model
%   coverage results for the models in Simulink(R) Test(TM) and
%   MATLAB-based Simulink tests of the TESTS property of the
%   task. If you have a license for Simulink Test and Simulink Coverage,
%   you can produce model coverage results in various formats by specifying
%   RESULTS as a string vector, character vector, cell vector of character
%   vectors, or vector of matlab.buildtool.io.File objects. Specify formats
%   by using file extensions:
%
%       * HTML - Produce an HTML model coverage report.
%       * XML  - Produce model coverage results in Cobertura XML format.
%
%   Alternatively, you can specify RESULTS as a vector of
%   matlab.unittest.plugins.codecoverage.CoverageFormat objects.
%
%   TASK = addModelCoverage(TASK,RESULTS,Name=Value) specifies options
%   using one or more of the following name-value arguments:
%
%       * CoverageMetrics - Metrics to include in the model coverage
%       analysis, specified as a string vector, character vector, or cell
%       vector of character vectors that correspond to property names of
%       the sltest.plugins.coverage.CoverageMetrics class. By default, the
%       task includes coverage metrics applied to the corresponding
%       Simulink Test and MATLAB-based Simulink tests.
%
%       * IncludeReferencedModels - Whether to include referenced models in
%       the model coverage analysis, specified as a numeric or logical 1
%       (true) or 0 (false). By default, the task includes the referenced
%       models.
%
%   Examples:
%
%       % Import the TestTask class
%       import matlab.buildtool.tasks.TestTask
%
%       % Create a task to produce model coverage results in Cobertura XML format
%       task = TestTask("myTestFolder").addModelCoverage("model-coverage/coverage.xml");
%
%       % Create a task to produce model coverage results in both Cobertura XML
%       % and HTML formats
%       task = TestTask("myTestFolder").addModelCoverage(["model-coverage/coverage.xml" "model-coverage/report.html"]);
%
%       % Create a task to produce a model coverage report with the specified
%       % coverage metrics
%       task = TestTask("myTestFolder").addModelCoverage("model-coverage/report.html",CoverageMetrics=["MCDC" "SignalRange"]);
%
%       % Create a model coverage report that does not include the referenced models
%       task = TestTask("myTestFolder").addModelCoverage("model-coverage/report.html",IncludeReferencedModels=false);
%
%       % Create a task to produce model coverage report in HTML format
%       % using the sltest.plugins.coverage.ModelCoverageReport class
%       import sltest.plugins.coverage.ModelCoverageReport
%       reportFolder = fullfile("results", "model-cov");
%       mkdir(reportFolder);
%       task = TestTask("myTestFolder").addModelCoverage(ModelCoverageReport(reportFolder,ReportName="MyReport"));
%
%
%   See also: matlab.buildtool.tasks.TestTask
%             sltest.plugins.ModelCoveragePlugin
%             sltest.plugins.coverage.CoverageMetrics
%             sltest.plugins.coverage.ModelCoverageReport
%             matlab.unittest.plugins.codecoverage.CoberturaFormat

% Copyright 2023-2024 The MathWorks, Inc.

arguments
    task (1,1) matlab.buildtool.tasks.TestTask
    results (1,:) {mustBeFileOrCoverageFormat(results, "Model")}
    options.CoverageMetrics (1,:) string = string.empty(1,0)
    options.IncludeReferencedModels (1,1) logical = true
end

import matlab.buildtool.internal.tasks.modelcoverage.ModelCoverageSettings

task.ModelCoverageSettings = [task.ModelCoverageSettings ModelCoverageSettings(results, Metrics=options.CoverageMetrics, IncludeReferencedModels=options.IncludeReferencedModels)];
end

function mustBeFileOrCoverageFormat(varargin)
matlab.buildtool.internal.tasks.mustBeFileOrCoverageFormat(varargin{:});
end