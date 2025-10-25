function [dirStruct, folderOrFile] = callDirWithOptions(obj, str, namesOnly)
%CALLDIRWITHOPTIONS Set up options and call FTP dir

% Copyright 2020 The MathWorks, Inc.
    if contains(str, "*")
        % wild card characters were passed in
        fullpath = str;
    else
        fullpath = matlab.io.ftp.internal.matlab.fullfile(obj.Connection, str);
    end

    options = struct("FullPath", fullpath, "NamesOnly", namesOnly);
    % call builtin to get remote dir contents
    % if fileFoundAt == 1, file
    % if fileFoundAt == 0, folder
    % if fileFoundAt == -1, non-existent entry
    [dirStruct, folderOrFile] = matlab.io.ftp.internal.matlab.dir(obj.Connection, options);
end