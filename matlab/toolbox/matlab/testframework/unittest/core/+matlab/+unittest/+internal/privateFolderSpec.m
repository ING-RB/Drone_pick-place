function satisfaction = privateFolderSpec(folders)
    % Given a list of folders this function returns a logical array that
    % denotes if the folder is a private folder or not. See
    % matlab.unittest.internal.findAllSubfolders for more information.

%   Copyright 2022-2023 The MathWorks, Inc.

    satisfaction = folders == "private";
end
