function setupMainFile(metadata, workDir)
%

%   Copyright 2020-2023 The MathWorks, Inc.

mainFile = [metadata.main '.' metadata.extension];
target = fullfile(workDir, mainFile);
matlab.internal.examples.copyFile(metadata.componentDir, "main", mainFile, target, false, false);
end
