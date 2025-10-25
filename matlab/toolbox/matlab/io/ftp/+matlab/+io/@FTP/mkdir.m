function mkdir(obj, dirname)
%MKDIR Creates a new directory on an FTP site.
%    MKDIR(FTP, DIRECTORY) creates a directory on the FTP site.

% Copyright 2020 The MathWorks, Inc.

    arguments
        obj (1,1) matlab.io.FTP
        dirname (1,1) string {mustBeNonmissing, mustBeNonempty, ...
                            matlab.io.ftp.mustNotBeEmptyString}
    end

    % Verify that connection was set up correctly
    verifyConnection(obj);

    % Verify that folder does not exist
    if matlab.io.ftp.internal.matlab.isFolder(obj.Connection, dirname) == true
        error(message("MATLAB:io:ftp:ftp:FolderExists", dirname));
    else
        matlab.io.ftp.internal.matlab.mkdir(obj.Connection, dirname);
    end
end
