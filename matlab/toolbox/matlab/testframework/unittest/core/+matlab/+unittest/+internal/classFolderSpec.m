function satisfaction = classFolderSpec(folders)
    % Given a list of folders this function returns a logical array that
    % denotes if the folder is a class folder or not. See
    % matlab.unittest.internal.findAllSubfolders for more information.

%   Copyright 2022 The MathWorks, Inc.

    satisfaction = startsWith(folders, "@");
end
