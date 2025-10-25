function rmdir(obj, dirname)
%rmdir Remove a directory on an FTP or SFTP site.
%    RMDIR(FTP,DIRECTORY) removes a directory on an FTP site.

% Copyright 2020 The MathWorks, Inc.

    arguments
        obj (1,1) matlab.io.FTP
        dirname (1,1) string {mustBeNonmissing, mustBeNonempty, ...
                            matlab.io.ftp.mustNotBeEmptyString}
    end

    % Verify that connection was set up correctly
    verifyConnection(obj);

    matlab.io.ftp.internal.matlab.rmdir(obj.Connection, dirname);
end
