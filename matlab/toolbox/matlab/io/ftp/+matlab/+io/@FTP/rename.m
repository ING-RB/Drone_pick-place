function rename(obj, oldname, newname)
%RENAME Rename a file on an FTP site.
%    RENAME(FTP,OLDNAME,NEWNAME) renames a file on an FTP site.

% Copyright 2020 The MathWorks, Inc.

    arguments
        obj (1,1) matlab.io.FTP
        oldname (1,1) string {mustBeNonmissing, mustBeNonempty, ...
                            matlab.io.ftp.mustNotBeEmptyString}
        newname (1,1) string {mustBeNonmissing, mustBeNonempty, ...
                            matlab.io.ftp.mustNotBeEmptyString}
    end

    % Verify that connection was set up correctly
    verifyConnection(obj);

    ftpFileExists(obj, oldname, newname);
    matlab.io.ftp.internal.matlab.rename(obj.Connection, ...
                                         oldname, newname);
end

function ftpFileExists(obj, oldname, newname)
% call dir to verify that filename being written does not exist, and
% file being renamed does exist
    details1 = callDirWithOptions(obj, oldname, true);
    details1 = splitlines(details1);
    if isempty(details1{end})
        details1(end) = [];
    end
    details2 = callDirWithOptions(obj, newname, true);
    details2 = splitlines(details2);
    if isempty(details2{end})
        details2(end) = [];
    end

    if isempty(details1)
        error(message("MATLAB:io:ftp:ftp:FileUnavailable", oldname));
    elseif ~isempty(details2)
        error(message("MATLAB:io:ftp:ftp:RenameExistingFile", newname));
    end
end
