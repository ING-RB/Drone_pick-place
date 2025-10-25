function location = mput(obj, str)
%MPUT Upload to an SFTP site.
%    MPUT(SFTP, FILENAME) uploads a file.
%
%    MPUT(SFTP, DIRECTORY) uploads a directory and its contents.
%
%    MPUT(SFTP, WILDCARD) uploads a set of files or directories specified
%    by a wildcard.
%
%    All of these calling forms return a cell array listing the full path to the
%    uploaded files on the server.

% Copyright 2020-2021 The MathWorks, Inc.

    arguments
        obj (1,1) matlab.io.sftp.SFTP
        str (1,1) string {mustBeNonmissing, mustBeNonempty} = "";
    end

    % Verify that connection was set up correctly
    verifyConnection(obj);

    % Figure out where the files live.
    [localDir, file, ext] = fileparts(str);
    filename = file + ext;
    if localDir == ""
        localDir = pwd;
    end

    if str == ""
        % Error early for incorrect inputs
        error(message("MATLAB:io:ftp:ftp:BadFilename", str));
    end

    if contains(filename, "*")
        % Upload any files and directories that match the wildcard.
        contentsWithWildcard = dir(fullfile(localDir,filename));
        contentsWithRecursiveWildcard = dir(fullfile(localDir, filename, "**"));
        if isempty(contentsWithWildcard) && isempty(contentsWithRecursiveWildcard)
            error(message("MATLAB:io:ftp:ftp:NotFound", str));
        end
        listing = [contentsWithWildcard; contentsWithRecursiveWildcard];
        remoteRelativeFolder = localDir;
    else
        if isfile(str)
            % upload file
            listing = dir(str);
            % no remote folder
            remoteRelativeFolder = missing;
        elseif isfolder(str)
            % upload folder
            listing = dir(fullfile(str, "**"));
            if ~isempty(listing)
                [~, localDir] = fileparts(listing(1).folder);
                isFolderPresent = matlab.io.sftp.internal.matlab.isFolder(...
                    obj.Connection, localDir);
                if ~isFolderPresent
                    % make parent folder
                    folderName = matlab.io.ftp.internal.matlab.fullfile(...
                        obj.Connection, localDir);
                    mkdir(obj, folderName);
                end
                % remote folder is parent folder
                remoteRelativeFolder = localDir;
            else
                return;
            end
        else
            error(message("MATLAB:io:ftp:ftp:NotFound", str));
        end
    end

    location = recursiveUpload(obj, listing, remoteRelativeFolder);
end

function location = recursiveUpload(obj, listing, remoteRelativeFolder)

    location = strings(numel(listing), 1);
    skipThis = zeros(numel(listing), 1);

    for ii = 1 : numel(listing)
        if listing(ii).name == "." || listing(ii).name == ".."
            % skip . and ..
            skipThis(ii) = 1;
            continue;
        end

        % get the relative path to the file or folder
        if ismissing(remoteRelativeFolder)
            % uploading file to pwd
            relativePath = listing(ii).name;
            remoteRelativePath = relativePath;
        else
            % uploading file to folder created on FTP server
            revInput = reverse(remoteRelativeFolder);
            fullPathToFile = fullfile(listing(ii).folder, listing(ii).name);
            revFullPathToFile = reverse(fullPathToFile);
            relativePath = reverse(extractBefore(revFullPathToFile, revInput));
            if startsWith(relativePath, filesep)
                relativePath = relativePath(2:end);
            end
            if ispc
                relativePath = strrep(relativePath, "\", "/");
            end

            if matlab.io.internal.common.isAbsolutePath(remoteRelativeFolder)
                % this is a relative path
                remoteRelativePath = relativePath;
            else
                remoteRelativePath = remoteRelativeFolder + "/" + relativePath;
            end
        end

        if listing(ii).isdir
            % create the folder
            isFolderPresent = matlab.io.sftp.internal.matlab.isFolder( ...
                obj.Connection, remoteRelativePath);
            if ~isFolderPresent
                folderName = matlab.io.ftp.internal.matlab.fullfile( ...
                    obj.Connection, remoteRelativePath);
                mkdir(obj, folderName);
            end
            skipThis(ii) = 1;
        else
            % call mput built-in for uploading this file
            remoteRelativePath = matlab.io.ftp.internal.matlab.fullfile( ...
                obj.Connection, remoteRelativePath);
            options = struct("LocalFullPath", [listing(ii).folder, filesep], ...
                             "Filename", listing(ii).name, ...
                             "RelativeRemotePath", remoteRelativePath, ...
                             "Mode", "binary");
            matlab.io.ftp.internal.matlab.mput(obj.Connection, options);
            location(ii) = string(remoteRelativePath);
        end
    end

    % only uploaded files are counted in final result
    location(skipThis == 1) = [];
    location = cellstr(location);
end
