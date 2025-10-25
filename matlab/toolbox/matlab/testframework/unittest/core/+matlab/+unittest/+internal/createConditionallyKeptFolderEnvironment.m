function env = createConditionallyKeptFolderEnvironment(folder)
% This function is undocumented and may change in a future release.

% Copyright 2016-2021 The MathWorks, Inc.

import matlab.unittest.internal.CancelableCleanup;

env = [];
folder = char(folder);
if ~isfolder(folder)
    mkdir(folder);
    env = CancelableCleanup(@() deleteFolderIfEmpty(folder));
end
end


function deleteFolderIfEmpty(folder)
output = dir(folder);
if all(ismember({output.name},{'.','..'})) %if folder is empty
    rmdir(folder);
end
end
