function newDir = cd(obj, folderName)
%CD Change current working directory.
%   CD(FTP, DIRECTORY) sets the current directory to the one specified.
%
%   CD(FTP,'..') moves to the directory above the current one.

% Copyright 2020 The MathWorks, Inc.

    arguments
        obj (1,1) matlab.io.FTP
        folderName (1,1) string {mustBeNonmissing} = "";
    end

    if isempty(obj.Connection)
        % Connection was not set up correctly, error
        error(message("MATLAB:io:ftp:ftp:NoConnection", obj.Host, port));
    end

    if nargin > 1
        fullpath = matlab.io.ftp.internal.matlab.fullurl(obj.Connection, ...
            folderName);
        obj.RemoteWorkingDirectory = matlab.io.ftp.internal.matlab.cd(...
            obj.Connection, fullpath);
        obj.RemotePath = matlab.io.ftp.internal.matlab.current_remote_url(...
            obj.Connection);
    end
    newDir = char(obj.RemoteWorkingDirectory);
end
