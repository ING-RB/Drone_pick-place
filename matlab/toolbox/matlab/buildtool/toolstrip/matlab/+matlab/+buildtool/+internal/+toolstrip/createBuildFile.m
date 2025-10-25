function createBuildFile()
% This function is unsupported and might change or be removed without 
% notice in a future version.

% Copyright 2024-2025 The MathWorks, Inc.

% Move to project root if project is open
proj = matlab.project.currentProject;
if ~isempty(proj)
    original = pwd();
    cleanup = onCleanup(@()cd(original));

    cd(proj.RootFolder);
end

bf = matlab.buildtool.internal.initBuildFile();

if ~isempty(proj)
    proj.addFile(bf);
end
end
