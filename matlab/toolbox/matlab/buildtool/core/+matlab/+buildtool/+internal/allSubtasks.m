function subtasks = allSubtasks(task)
% This function is unsupported and might change or be removed without 
% notice in a future version.

% Copyright 2023 The MathWorks, Inc.

arguments
    task (1,1) matlab.buildtool.Task
end

import matlab.buildtool.Task;
import matlab.buildtool.internal.allSubtasks;

subtasks = Task.empty(1,0);
if ~isTaskGroup(task)
    return;
end
for t = task.Tasks
    subtasks = [subtasks t allSubtasks(t)]; %#ok<AGROW>
end
end

function tf = isTaskGroup(obj)
tf = isa(obj, "matlab.buildtool.TaskGroup");
end