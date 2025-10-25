function tf = isFile(paths)
    %ISFILE Check each string element is a folder or not.
    %
    %   TF = isFile(PATHS) returns a logical array of size equal to PATHS
    %   indicating whether each of the string element is a file or not.
    %   PATHS must be a cell array of character vector.

    %   Copyright 2018 The MathWorks, Inc.

    import matlab.io.internal.vfs.validators.validatePaths;
    import matlab.io.internal.vfs.validators.isAbsoluteFolder;

    paths = validatePaths(paths);

    fileOrRelativeFolder = isAbsoluteFolder(paths);
    % Column 1 is true for fileOrRelativeFolder, Column is true for folder.
    tf = fileOrRelativeFolder(:,1) & ~fileOrRelativeFolder(:,2);
end
