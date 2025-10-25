function files = resolveFolderToSourceFiles(folder, optionalArgs)
% This function is undocumented and may change in a future release.

% Resolve folder to valid source files.

%  Copyright 2022 The MathWorks, Inc.

arguments
    folder
    optionalArgs.IncludeSubfolders = true;
end
import matlab.unittest.internal.coverage.folderParser;

folderObj = folderParser(folder,optionalArgs.IncludeSubfolders);
filesCell = arrayfun(@getFiles,folderObj,'UniformOutput',false);
files = string([filesCell{:}]);
end