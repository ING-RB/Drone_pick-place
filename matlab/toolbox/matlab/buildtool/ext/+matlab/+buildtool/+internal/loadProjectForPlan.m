function project = loadProjectForPlan(planRoot)
% This function is unsupported and might change or be removed without notice
% in a future version.

% Copyright 2024 The MathWorks, Inc.

arguments
    planRoot (1,1) string {mustBeNonmissing}
end

import matlab.project.Project;
import matlab.project.isUnderProjectRoot;

project = Project.empty();

[underProject,projectRoot] = isUnderProjectRoot(fullfile(planRoot,"*")); % g3429350
if ~underProject
    return;
end

rootProject = matlab.project.rootProject();
if ~isempty(rootProject)
    loadedProjects = rootProject;
    if ~strcmp(projectRoot, loadedProjects.RootFolder)
        projectRefs = listAllProjectReferences(rootProject);
        loadedProjects = [loadedProjects, projectRefs.Project];
    end
    project = loadedProjects(strcmp(projectRoot,[loadedProjects.RootFolder]));
end

if isempty(project)
    project = openProject(projectRoot);
    if project.HasStartupErrors
        error(message("MATLAB:buildtool:Plan:ProjectHasStartupErrors", project.Name));
    end
end
end