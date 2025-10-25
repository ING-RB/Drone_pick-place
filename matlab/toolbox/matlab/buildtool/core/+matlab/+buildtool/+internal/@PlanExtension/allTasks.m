function tasks = allTasks(plan)
% This function is unsupported and might change or be removed without 
% notice in a future version.

% Copyright 2023 The MathWorks, Inc.

arguments
    plan (1,1) matlab.buildtool.Plan
end

import matlab.buildtool.Task;
import matlab.buildtool.internal.allSubtasks;

tasks = Task.empty(1,0);
for t = plan.Tasks
    tasks = [tasks t allSubtasks(t)]; %#ok<AGROW>
end
end