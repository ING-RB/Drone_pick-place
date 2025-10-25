function delete(obj, filename)
%DELETE Delete a file on an SFTP server.
%    DELETE(SFTP,FILENAME) deletes a file on the server.

% Copyright 2020 The MathWorks, Inc.

% TODO: Make a connection in case it was lost

    arguments
        obj (1,1) matlab.io.sftp.SFTP
        filename (1,1) string {mustBeNonmissing, mustBeNonempty, ...
            matlab.io.ftp.mustNotBeEmptyString}
    end

    % Verify that connection was set up correctly
    verifyConnection(obj);

    if contains(filename, '*')
        % call dir to get list of files and then delete files one at a time
        listing = dir(obj, filename);

        % get the full path to the files
        path = fileparts(filename);
        if path == ""
            path = obj.RemoteWorkingDirectory;
        elseif ~endsWith(path, "/")
            path = path + "/";
        end
        path = matlab.io.ftp.internal.matlab.fullfile(obj.Connection, path);

        for ii = 1 : numel(listing)
            if listing(ii).name == "." || listing(ii).name == ".."
                continue;
            end
            matlab.io.sftp.internal.matlab.deleteFile(obj.Connection, ...
                path + string(listing(ii).name));
        end
    else
        matlab.io.sftp.internal.matlab.deleteFile(obj.Connection, filename);
    end
end
