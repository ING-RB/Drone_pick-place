function project = getProjectForPlan(planRoot)
% This function is unsupported and might change or be removed without notice
% in a future version.

% Copyright 2024 The MathWorks, Inc.

arguments
    planRoot (1,1) string {mustBeNonmissing}
end

import matlab.project.Project;
import matlab.project.isUnderProjectRoot;
import matlab.internal.project.api.makeProjectAvailable;

[underProject,projectRoot] = isUnderProjectRoot(fullfile(planRoot,"*")); % g3429350
if underProject
    project = makeProjectAvailable(projectRoot);
else
    project = Project.empty();
end
end