function plan = addFunctionTasks(plan, localFcns)
% This function is unsupported and might change or be removed without 
% notice in a future version.

% addFunctionTasks - Add new tasks to the plan defined from local functions

% Copyright 2021-2022 The MathWorks, Inc.

arguments
    plan (1,1) matlab.buildtool.Plan
    localFcns (1,:) cell
end

cellfun(@validateScopedFunction, localFcns);

fcnInfo = cellfun(@functionInfo, localFcns);
if isempty(fcnInfo)
    return;
end

fcnInfo(~[fcnInfo.isTaskFunction]) = [];

cellfun(@validateTaskFunction, {fcnInfo.handle});

files = unique([fcnInfo.file]);
fileCode = dictionary();
for i = 1:numel(files)
    fileCode(files(i)) = matlab.internal.getCode(char(files(i)));
end

tasks = matlab.buildtool.Task.empty();
for i = 1:numel(fcnInfo)
    fcnPath = fcnInfo(i).file + filemarker + fcnInfo(i).name;
    helpText = matlab.internal.help.getMFileHelpText(char(fcnPath), @(f)fileCode(f), true);
    description = strip(helpText);
    
    tasks(i) = matlab.buildtool.Task(Actions=fcnInfo(i).handle, Description=description);
end

names = matlab.lang.makeUniqueStrings([fcnInfo.taskName string.empty()]);
plan(names) = tasks;
end

function validateScopedFunction(fcn)
if ~isa(fcn, "function_handle")
    error(message("MATLAB:buildtool:addFunctionTasks:MustBeCellOfLocalFunctions"));
end
info = functions(fcn);
if ~strcmp(info.type, "scopedfunction")
    error(message("MATLAB:buildtool:addFunctionTasks:MustBeCellOfLocalFunctions"));
end
end

function validateTaskFunction(fcn)
if nargin(fcn) == 0 || nargout(fcn) ~= 0
    error(message("MATLAB:buildtool:addFunctionTasks:MustHaveTaskFunctionSignature", func2str(fcn)));
end
end

function info = functionInfo(fcn)
f = functions(fcn);
info.file = string(f.file);
info.name = string(f.function);
info.handle = fcn;
info.isTaskFunction = isTaskFunction(f.function);
info.taskName = functionToTaskName(f.function);
end

function tf = isTaskFunction(fcnName)
tf = endsWith(fcnName, "task", IgnoreCase=true);
end

function taskName = functionToTaskName(fcnName)
arguments
    fcnName (1,1) string
end
if strcmpi(fcnName, "task")
    taskName = fcnName;
    return;
end
taskName = regexprep(fcnName, "([_]?task)$", "", "ignorecase");
end