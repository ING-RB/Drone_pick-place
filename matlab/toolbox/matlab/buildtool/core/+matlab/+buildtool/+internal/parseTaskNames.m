function [taskNames,taskArgs] = parseTaskNames(tasks, workspace)
% This function is unsupported and might change or be removed without
% notice in a future version.

% Copyright 2022 The MathWorks, Inc.

taskArgs = cell(1, numel(tasks));
for i = 1:numel(tasks)
    parts = regexp(tasks{i}, "(", "split", "once");
    name = parts{1};
    if numel(parts) > 1
        try
            args = parseTaskArgsPart(parts{2}, workspace);
        catch e
            causeException = MException(e.identifier, e.message);
            exception = MException(message("MATLAB:buildtool:buildtool:UnableToParseTaskArgs", name));
            exception = addCause(exception, causeException);
            throwAsCaller(exception);
        end
    else
        args = {};
    end
    taskNames(i) = string(name); %#ok<AGROW>
    taskArgs{i} = args;
end
end

function args = parseTaskArgsPart(part, workspace) %#ok<STOUT>
wsName = matlab.lang.makeUniqueStrings("workspace", fieldnames(workspace));
feval(@()assignin("caller", wsName, workspace)); %#ok<FVAL>
eval( ...
    "clearvars -except " + wsName + ";" + ...
    "unpackWorkspace(" + wsName + ");" + ...
    "clearvars " + wsName + ";" + ...
    "args = matlab.buildtool.internal.getInputArguments(" + part + ";");
end

function unpackWorkspace(workspace)
fn = fieldnames(workspace);
for i = 1:numel(fn)
    assignin("caller", fn{i}, workspace.(fn{i}));
end
end
