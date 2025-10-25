function [isOnPath, isCWD] = isDirectoryOnMatlabSearchPath(directoryPath)
%

% Copyright 2020 The MathWorks, Inc.
 isOnPath = contains(path, directoryPath);
 isCWD = strcmp(pwd, directoryPath);
end
