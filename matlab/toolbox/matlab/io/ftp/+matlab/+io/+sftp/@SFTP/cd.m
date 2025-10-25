function newDir = cd(obj, folderName)
%CD Change current working directory.
%   CD(SFTP, DIRECTORY) sets the current directory to the one specified.
%
%   CD(SFTP,'..') moves to the directory above the current one.

% Copyright 2020-2023 The MathWorks, Inc.

    arguments
        obj (1,1) matlab.io.sftp.SFTP
        folderName (1,1) string {mustBeNonmissing} = "";
    end

    if isempty(obj.Connection)
        % Connection was not set up correctly, error
        error(message("MATLAB:io:ftp:ftp:NoConnection", obj.Host, obj.Port));
    end

    if ~ismissing(obj.StartingFolder) && startsWith(folderName, "~")
        remText = extractAfter(folderName, "~");
        if strlength(remText) > 0
            % cd to folder below login folder
            trailFilesep = endsWith(obj.StartingFolder, "/");
            leadFilesep = startsWith(remText, "/");
            % checks to add correct number of path separators since // gets
            % interpreted as start of the path
            if ~trailFilesep && ~leadFilesep
                % add a path separator
                folderName = obj.StartingFolder + "/" + remText;
            elseif trailFilesep && leadFilesep
                % remove a path separator to avoid //
                folderName = obj.StartingFolder + extractAfter(remText, "/");
            else
                folderName = obj.StartingFolder + remText;
            end
        else
            % cd to login folder
            folderName = obj.StartingFolder;
        end
    end

    if nargin > 1
        fullpath = matlab.io.ftp.internal.matlab.fullurl(obj.Connection, folderName);

        % check whether path exists
        folderExists = matlab.io.sftp.internal.matlab.isFolder(obj.Connection, folderName);
        if ~folderExists
            error(message("MATLAB:io:ftp:ftp:NoSuchDirectory", folderName));
        end

        % cd to the remote path
        obj.RemoteWorkingDirectory = matlab.io.ftp.internal.matlab.cd(...
            obj.Connection, fullpath);
        obj.RemotePath = matlab.io.ftp.internal.matlab.current_remote_url(...
            obj.Connection);
    end
    newDir = char(obj.RemoteWorkingDirectory);
end
