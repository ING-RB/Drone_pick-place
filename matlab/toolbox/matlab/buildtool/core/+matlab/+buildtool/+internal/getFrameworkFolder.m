function folder = getFrameworkFolder()
% This function is unsupported and might change or be removed without 
% notice in a future version.

% Copyright 2021-2022 The MathWorks, Inc.

persistent FRAMEWORK_FOLDER;
if isempty(FRAMEWORK_FOLDER)
    FRAMEWORK_FOLDER = fullfile(toolboxdir("matlab"), "buildtool");
end

folder = FRAMEWORK_FOLDER;
end

