function folder = getFrameworkFolder
% This function is undocumented.

%  Copyright 2013-2020 The MathWorks, Inc.

persistent FRAMEWORK_FOLDER;

if isempty(FRAMEWORK_FOLDER)
    FRAMEWORK_FOLDER = fullfile(toolboxdir("matlab"), "testframework");
end

folder = FRAMEWORK_FOLDER;

% LocalWords:  testframework
