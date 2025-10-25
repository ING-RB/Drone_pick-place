function buildtool(arg)
arguments (Repeating)
    arg (1,1) string
end

import matlab.buildtool.Plan;
import matlab.buildtool.BuildRunner;
import matlab.buildtool.internal.displayTasks;
import matlab.buildtool.internal.initBuildFile;
import matlab.buildtool.internal.parseTaskNames;
import matlab.buildtool.internal.packWorkspace;
import matlab.buildtool.internal.findBuildFile;
import matlab.automation.internal.diagnostics.CommandHyperlinkableString;

[tasks, options] = parseArgs(arg);

if options.global.Init
    initBuildFile();
    return;
end

if isempty(options.global.BuildFileLocation)
    file = findBuildFile();
else
    file = options.global.BuildFileLocation;
end

if isempty(file)
    link = CommandHyperlinkableString("buildtool -init", "internal.matlab.desktop.commandwindow.executeCommandForUser('buildtool -init')");
    error(message("MATLAB:buildtool:buildtool:NoBuildFileFound", link.string()));
end

plan = Plan.load(file);

if options.global.DisplayTasks
    displayTasks(plan.Tasks, IncludeSubtasks=options.global.DisplaySubtasks);
    fprintf("\n");
    return;
end

runner = BuildRunner.withDefaultPlugins(options.runner);
runFcn = matlab.buildtool.internal.getRunFcn(Parallel=options.global.UseParallel);

runArgs = namedargs2cell(options.run);
if isempty(tasks)
    result = runFcn(runner, plan, runArgs{:});
else
    ws = evalin("caller", "packWorkspace();");
    [taskName,taskArgs] = parseTaskNames(tasks, ws);
    result = runFcn(runner, plan, taskName, taskArgs, runArgs{:});
end

if result.Failed
    error(message("MATLAB:buildtool:buildtool:BuildFailed"));
end
end

function [tasks, options] = parseArgs(args)
options.global.BuildFileLocation = string.empty();
options.global.DisplayTasks = false;
options.global.DisplaySubtasks = false;
options.global.Init = false;
options.global.IgnoreUnknownOptions = false;
options.global.UnknownOptions = struct.empty();
options.global.UseParallel = false;
options.runner = struct();
options.run = struct();
skip = string.empty();
prune = string.empty();

numArgs = numel(args);
argsMask = false(1, numArgs);
for i = 1:numArgs
    arg = args{i};
    if startsWith(arg, "-")
        argsMask(i) = true;
        if strcmpi(arg, "-tasks")
            options.global.DisplayTasks = true;
            if i == numArgs || startsWith(args{i+1}, "-")
                options.global.DisplaySubtasks = false;
            elseif strcmpi(args{i+1}, "all")
                options.global.DisplaySubtasks = true;
                argsMask(i+1) = true;
            else
                error(message("MATLAB:buildtool:buildtool:InvalidOptionValue",args{i+1},"-tasks"));
            end
        elseif strcmpi(arg, "-init")
            options.global.Init = true;
        elseif strcmpi(arg, "-verbosity")
            errorWhenUnset(arg, numArgs, i, args);
            value = str2double(args{i+1});
            if isnan(value) % for "detailed" as opposed to number "3"
                value = args{i+1};
            end
            options.run.Verbosity = value;
            options.runner.Verbosity = value;
            argsMask(i+1) = true;
        elseif strcmpi(arg, "-prune")
            errorWhenUnset(arg, numArgs, i, args);
            prune = [prune args{i+1}]; %#ok<AGROW>
            options.run.Prune = prune;
            argsMask(i+1) = true;
        elseif strcmpi(arg, "-skip")
            errorWhenUnset(arg, numArgs, i, args);
            skip = [skip args{i+1}]; %#ok<AGROW>
            options.run.Skip = skip;
            argsMask(i+1) = true;
        elseif strcmpi(arg, "-continueOnFailure")
            options.run.ContinueOnFailure = true;
        elseif strcmpi(arg, "-parallel")
            options.global.UseParallel = true;
        elseif strcmpi(arg, "-buildFile")
            errorWhenUnset(arg, numArgs, i, args);
            options.global.BuildFileLocation = args{i+1};
            argsMask(i+1) = true;
        elseif strcmpi(arg, "-ignoreUnknownOptions")
            options.global.IgnoreUnknownOptions = true;
        elseif strcmpi(arg, "-cacheFolder")
            errorWhenUnset(arg, numArgs, i, args);
            options.run.CacheFolder = args{i+1};
            argsMask(i+1) = true;
        else
            options.global.UnknownOptions(end+1).name = arg;
            if i == numArgs || startsWith(args{i+1}, "-")
                options.global.UnknownOptions(end).arg = string.empty();
            else
                options.global.UnknownOptions(end).arg = args{i+1};
                argsMask(i+1) = true;
            end
        end
    end
end

if ~options.global.IgnoreUnknownOptions && ~isempty(options.global.UnknownOptions)
    error(message("MATLAB:buildtool:buildtool:UnknownOption", options.global.UnknownOptions(1).name));
end

warningState = warning("backtrace","off");
restoreWarningState = onCleanup(@()warning(warningState));
for opt = options.global.UnknownOptions
    if isempty(opt.arg)
        warning(message("MATLAB:buildtool:buildtool:IgnoringUnknownOption", opt.name));
    else
        warning(message("MATLAB:buildtool:buildtool:IgnoringUnknownOptionAndArgument", opt.name, opt.arg));
    end
end
delete(restoreWarningState);

tasks = string(args(~argsMask));
end

function errorWhenUnset(arg, numArgs, i, args)
% If this is the last arg or the next is another flag, error
if i == numArgs || startsWith(args{i+1}, "-")
    error(message("MATLAB:buildtool:buildtool:UnsetOption", arg));
end
end

% Copyright 2021-2024 The MathWorks, Inc.
