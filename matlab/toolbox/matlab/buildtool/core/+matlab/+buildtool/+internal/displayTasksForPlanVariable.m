function displayTasksForPlanVariable(varname, plan)
%

%   Copyright 2023 The MathWorks, Inc.

import matlab.buildtool.internal.displayTasks;
narginchk(1, 2);
if nargin == 1
    throwAsCaller(MException(message("MATLAB:buildtool:Plan:PlanNoLongerExists",varname)));
else
    if ~isa(plan, "matlab.buildtool.Plan")
        throwAsCaller(MException(message("MATLAB:buildtool:Plan:PlanNoLongerPlan",varname)));
    end
    displayTasks(plan.Tasks, Indent=4, IncludeSubtasks=true);
    fprintf("\n");
end
end
