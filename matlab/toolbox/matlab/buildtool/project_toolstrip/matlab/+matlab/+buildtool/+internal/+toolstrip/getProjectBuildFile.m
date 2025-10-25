function filepath = getProjectBuildFile()
% This function is unsupported and might change or be removed without
% notice in a future version.

% Copyright 2024 The MathWorks, Inc.

if isempty(matlab.project.rootProject)
    error(message("MATLAB:buildtool_toolstrip:getProjectBuildFile:NoProject"));
end

proj = currentProject();
filepath = fullfile(proj.RootFolder, "buildfile.m");
end
