function satisfaction = allFolderSpec(folders)
    % This function acts as a folder spec that never filters subfolders. See
    % matlab.unittest.internal.findAllSubfolders for more information.

%   Copyright 2022 The MathWorks, Inc.

    satisfaction = true(size(folders));
end
