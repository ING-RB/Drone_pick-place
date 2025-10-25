function displayTasks(tasks, options)
% This function is unsupported and might change or be removed without 
% notice in a future version.

% Copyright 2021-2023 The MathWorks, Inc.

arguments
    tasks (1,:) matlab.buildtool.Task
    options.Indent (1,1) {mustBeInteger,mustBeNonnegative} = 0;
    options.IncludeSubtasks (1,1) logical = false
end

import matlab.buildtool.Task;
import matlab.buildtool.internal.allSubtasks;

if options.IncludeSubtasks
    t = Task.empty(1,0);
    for task = tasks
        t = [t task allSubtasks(task)]; %#ok<AGROW>
    end
    tasks = t;
end

names = [tasks.Name string.empty()];

[~,idx] = sort(names);
tasks = tasks(idx);

indent = repmat(' ', 1, options.Indent);
maxWidth = max(strlength(names));
for task = tasks
    fprintf(indent + "%-" + maxWidth + "s", task.Name);
    if task.Description ~= ""
        fprintf(" - %s", task.Description);
    end
    fprintf("\n");
end
end