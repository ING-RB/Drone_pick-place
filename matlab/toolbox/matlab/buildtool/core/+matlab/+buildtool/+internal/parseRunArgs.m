function [taskName, taskArgs, options] = parseRunArgs(plan, varargin)
% This function is unsupported and might change or be removed without 
% notice in a future version.

%   Copyright 2023-2024 The MathWorks, Inc.

import matlab.buildtool.internal.cacheRoot;
import matlab.automation.Verbosity;

if nargin == 1
    args = {plan.DefaultTasks};
else
    args = varargin;
end

taskParser = inputParser();
taskParser.addRequired("taskName", @mustBeTextVector);
taskParser.parse(args{1});
taskName = string(taskParser.Results.taskName(:)');

nvParser = inputParser();
nvParser.addParameter("Prune", string.empty(), @mustBeTextVector);
nvParser.addParameter("Skip", string.empty(), @mustBeTextVector);
nvParser.addParameter("ContinueOnFailure", false, @mustBeLogicalScalar);
nvParser.addParameter("Parallel", false, @mustBeLogicalScalar);
nvParser.addParameter("CacheFolder", cacheRoot(plan.RootFolder), @mustBeNonzeroLengthTextScalar);
nvParser.addParameter("Verbosity", Verbosity.empty(), @mustBeConvertibleToVerbosityScalarOrEmpty);

if isscalar(taskName) && any(startsWith(nvParser.Parameters, taskName, IgnoreCase=true)) ...
        && ~plan.isTask(taskName)
    taskName = plan.DefaultTasks;
else
    args = args(2:end);
end

nvParser.addOptional("taskArgs", {{}}, @(x)mustBeValidTaskArgs(x, taskName));
nvParser.parse(args{:});

taskArgs = nvParser.Results.taskArgs(:)';
options = rmfield(nvParser.Results, "taskArgs");
options = convertFieldCharsToStrings(options);
options = convertFieldVecsToRowVecs(options);
options.Verbosity = Verbosity(options.Verbosity);
end

function s = convertFieldCharsToStrings(s)
for n = string(fieldnames(s))'
    s.(n) = convertCharsToStrings(s.(n));
end
end

function v = convertFieldVecsToRowVecs(v)
for n = string(fieldnames(v))'
    if iscolumn(v.(n))
        v.(n) = v.(n)';
    end
end
end

function mustBeLogicalScalar(x)
validateattributes(x, "logical", "scalar");
end

function mustBeTextVector(x)
mustBeText(x);
mustBeVector(x, "allow-all-empties");
end

function mustBeNonzeroLengthTextScalar(x)
mustBeTextScalar(x);
mustBeNonzeroLengthText(x);
end

function mustBeConvertibleToVerbosityScalarOrEmpty(x)
mustBeScalarOrEmpty(x);
try
    matlab.automation.Verbosity(x);
catch x
    error(message("MATLAB:buildtool:BuildRunner:UnableToConvertToVerbosity"));
end
end

function mustBeValidTaskArgs(taskArgs, taskName)
mustBeA(taskArgs, "cell");
mustBeVector(taskArgs, "allow-all-empties");
if ~all(cellfun(@iscell, taskArgs))
    taskArgs = {taskArgs};
end
cellfun(@mustBeCellVector, taskArgs);
mustBeEqualSizeOrScalar(taskArgs, taskName);
end

function mustBeCellVector(taskArg)
if ~isvector(taskArg) && ~isempty(taskArg)
    error(message("MATLAB:buildtool:BuildRunner:TaskArgGroupsMustBeCellVecs"));
end
end

function taskArgs = mustBeEqualSizeOrScalar(taskArgs, taskName)
if ~isscalar(taskArgs) && numel(taskName) ~= numel(taskArgs)
    error(message("MATLAB:buildtool:BuildRunner:NumNamesAndArgsMismatch"));
end
end
