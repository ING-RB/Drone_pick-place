function buildFileDest = initBuildFile()
% This function is unsupported and might change or be removed without
% notice in a future version.

%   Copyright 2023-2025 The MathWorks, Inc.

buildFileDest = fullfile(pwd, "buildfile.m");
if isfile(buildFileDest)
    error(message("MATLAB:buildtool:buildtool:BuildFileAlreadyExists"));
end

buildFileContent = {
    'function plan = buildfile'
    'import matlab.buildtool.tasks.*'
    ''
    'plan = buildplan(localfunctions);'
    ''
    'plan("clean") = CleanTask;'
    'plan("check") = CodeIssuesTask;'
    'plan("test") = TestTask;'
    ''
    'plan.DefaultTasks = ["check" "test"];'
    'end'};

writelines(buildFileContent, buildFileDest);
edit(buildFileDest);
end

% LocalWords:  buildfile buildplan
