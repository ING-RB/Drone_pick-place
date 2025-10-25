function location = mget(obj, str, targetDirectory)
%MGET Download from an FTP or SFTP site.
%    MGET(FTP, FILENAME) downloads a file from an FTP site.
%
%    MGET(SFTP, FILENAME) downloads a file from an SFTP site.
%
%    MGET(FTP, DIRECTORY) downloads a directory and its contents from an
%    FTP site.
%
%    MGET(SFTP, DIRECTORY) downloads a directory and its contents from an
%    SFTP site.
%
%    MGET(FTP, WILDCARD) downloads a set of files or directories specified
%    by a wildcard.
%
%    MGET(..., TARGETDIRECTORY) specifies the local target directory, rather
%    than the current directory.

% Copyright 2020 The MathWorks, Inc.

% TODO: Make a connection in case it was lost

    arguments
        obj (1,1) matlab.io.FTP
        str (1,1) string {mustBeNonmissing, mustBeNonempty}
        targetDirectory (1,1) string = pwd
    end

    currentLocalPath = targetDirectory;
    fullRemoteDirPath = "";

    % Verify that connection was set up correctly
    verifyConnection(obj);

    if str == "" || ismissing(str)
        error(message("MATLAB:io:ftp:ftp:FileUnavailable", str));
    else
        % file or folder case
        [dirStruct, folderOrFile] = dir(obj, str);
        % does str match any of the entries returned by dir
        if folderOrFile == 0
            currentLocalPath = fullfile(currentLocalPath, str);
            if ~exist(currentLocalPath, "dir")
                mkdir(currentLocalPath);
            end
            fullRemoteDirPath = str;
        end

        if startsWith(str, "/")
            % this is an absolute path
            tf = isFolder(obj, str);
            if tf && ~endsWith(str, "/")
                str = str + "/";
            end
            fullRemoteDirPath = fileparts(str);
        end

        if contains(str, "/") && folderOrFile == 1
            % local path needs creation of folders, create relative remote
            % path
            tmp = fileparts(str);
            currentLocalPath = currentLocalPath + "/" + tmp;
            fullRemoteDirPath = tmp;
        end

        if isempty(dirStruct) && folderOrFile == -1
            error(message("MATLAB:io:ftp:ftp:FileUnavailable", str));
        end
    end

    % use recursive lookup to download files
    location = cellstr(recursiveDownload(obj, dirStruct, fullRemoteDirPath, ...
        currentLocalPath));
end

function location = recursiveDownload(obj, dirStruct, fullRemoteDirPath, ...
    currentLocalPath)
    location = string.empty(0,1);
    for ii = 1 : numel(dirStruct)
        if dirStruct(ii).name == "." || dirStruct(ii).name == ".."
            continue;
        end

        if isempty(dirStruct(ii).isdir)
            % check if this is a folder or file
            inputPath = matlab.io.ftp.internal.matlab.fullfile(obj.Connection, ...
                fullRemoteDirPath + "/" + string(dirStruct(ii).name));
            tf = isFolder(obj, inputPath);
            if tf
                dirStruct(ii).isdir = true;
            else
                dirStruct(ii).isdir = false;
            end
        end

        if ~dirStruct(ii).isdir
            % file case, download the file
            % first check that the path being written to, exists.
            if ~exist(currentLocalPath, "dir")
                mkdir(currentLocalPath);
            end

            if contains(dirStruct(ii).name, "/")
                % QNX servers contain full path in name
                filename = reverse(extractBefore(reverse(dirStruct(ii).name), "/"));
            else
                filename = dirStruct(ii).name;
            end

            options = struct("RelativePathToRemoteFile", ...
                ftp_fullfile(fullRemoteDirPath, filename), ...
                "RelativePathToLocalFile", fullfile(currentLocalPath, filename), ...
                "Mode", obj.Mode);
            matlab.io.ftp.internal.matlab.mget(obj.Connection, options);
            location(end+1,1) = string(fullfile(currentLocalPath, filename));
        else
            % folder case, create the folder locally
            nextLocalPath = fullfile(currentLocalPath, dirStruct(ii).name);
            if ~exist(nextLocalPath, "dir")
                mkdir(nextLocalPath);
            end

            % get contents of folder on the remote server
            nextRemoteDirPath = ftp_fullfile(fullRemoteDirPath, dirStruct(ii).name);
            dirStructSecondLevel = dir(obj, nextRemoteDirPath);

            % recursively get contents
            location = [location; recursiveDownload(obj, dirStructSecondLevel, ...
                nextRemoteDirPath, nextLocalPath)];
        end
    end
end

% Add a custom fullfile here since normal MATLAB fullfile will insert backslash on Windows,
% which will break FTP calls.
function s = ftp_fullfile(path, name)
    % If a file relative to CWD is passed in, avoid adding a slash.
    if strlength(path) == 0
        s = string(name);
    elseif endsWith(path, "/")
        s = string(path) + name;
    else
        s = string(path) + "/" + name;
    end
end