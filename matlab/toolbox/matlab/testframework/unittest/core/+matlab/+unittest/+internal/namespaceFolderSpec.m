function satisfaction = namespaceFolderSpec(folders)
    % Given a list of folders this function returns a logical array that
    % denotes if the folder is a namespace folder or not. See
    % matlab.unittest.internal.findAllSubfolders for more information.

%   Copyright 2022-2023 The MathWorks, Inc.

    satisfaction = startsWith(folders, "+");
end
