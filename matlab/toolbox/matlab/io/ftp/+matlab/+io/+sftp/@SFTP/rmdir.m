function rmdir(obj, dirname)
%rmdir Remove a directory on an SFTP site.
%    RMDIR(SFTP,DIRECTORY) removes a directory on an SFTP site.

% Copyright 2020 The MathWorks, Inc.

    arguments
        obj (1,1) matlab.io.sftp.SFTP
        dirname (1,1) string {mustBeNonmissing, mustBeNonempty, ...
            matlab.io.ftp.mustNotBeEmptyString}
    end

    % Verify that connection was set up correctly
    verifyConnection(obj);

    folderName = matlab.io.ftp.internal.matlab.fullfile(obj.Connection, dirname);
    folderExists = matlab.io.sftp.internal.matlab.isFolder(obj.Connection, folderName);
    folderContents = matlab.io.sftp.internal.matlab.dir(obj.Connection, ...
        folderName, struct("NamesOnly", true));
    if folderExists
        contents = splitlines(folderContents);
        if isempty(contents{end})
            contents = contents(1:end-1);
        end
        if ~all(cellfun(@(str) str == "." || str == "..", contents))
            % folder is not empty
            error(message("MATLAB:io:ftp:ftp:FolderNotEmpty", dirname));
        end
        matlab.io.sftp.internal.matlab.rmdir(obj.Connection, folderName);
    else
        % folder does not exist
        error(message("MATLAB:io:ftp:ftp:RemoveFolderFailed", dirname));
    end
end