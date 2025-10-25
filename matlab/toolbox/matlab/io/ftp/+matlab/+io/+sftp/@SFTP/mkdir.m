function mkdir(obj, dirname)
%MKDIR Creates a new directory on an SFTP site.
%    MKDIR(SFTP, DIRECTORY) creates a directory on the FTP site.

% Copyright 2020 The MathWorks, Inc.

    arguments
        obj (1,1) matlab.io.sftp.SFTP
        dirname (1,1) string {mustBeNonmissing, mustBeNonempty, ...
            matlab.io.ftp.mustNotBeEmptyString}
    end

    % Verify that connection was set up correctly
    verifyConnection(obj);

    % Verify that folder does not exist
    folderName = matlab.io.ftp.internal.matlab.fullfile(obj.Connection, dirname);
    isInputAFolder = matlab.io.sftp.internal.matlab.isFolder(obj.Connection, folderName);

    if isInputAFolder == true
    	error(message("MATLAB:io:ftp:ftp:FolderExists", dirname));
    else
        matlab.io.sftp.internal.matlab.mkdir(obj.Connection, folderName);
    end
end
