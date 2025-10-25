function rename(obj, oldname, newname)
%RENAME Rename a file on an SFTP site.
%    RENAME(SFTP,OLDNAME,NEWNAME) renames a file on an SFTP site.

% Copyright 2020 The MathWorks, Inc.

    arguments
        obj (1,1) matlab.io.sftp.SFTP
        oldname (1,1) string {mustBeNonmissing, mustBeNonempty, ...
            matlab.io.ftp.mustNotBeEmptyString}
        newname (1,1) string {mustBeNonmissing, mustBeNonempty, ...
            matlab.io.ftp.mustNotBeEmptyString}
    end

    % Verify that connection was set up correctly
    verifyConnection(obj);

    sftpFileExists(obj, oldname, newname);
    matlab.io.sftp.internal.matlab.rename(obj.Connection, ...
        oldname, newname);
end

function sftpFileExists(obj, oldname, newname)
    % call dir to verify that filename being written does not exist, and
    % file being renamed does exist
    oldname = matlab.io.ftp.internal.matlab.fullfile(obj.Connection, oldname);
    [~, exists1] = dir(obj, oldname);

    newname = matlab.io.ftp.internal.matlab.fullfile(obj.Connection, newname);
    [~, exists2] = dir(obj, newname);

    if exists1 == -1
        error(message("MATLAB:io:ftp:ftp:FileUnavailable", oldname));
    elseif exists2 ~= -1
        error(message("MATLAB:io:ftp:ftp:RenameExistingFile", newname));
    end
end