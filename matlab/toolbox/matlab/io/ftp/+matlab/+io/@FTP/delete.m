function delete(obj, filename)
%DELETE Delete a file on an FTP server.
%    DELETE(FTP,FILENAME) deletes a file on the server.

% Copyright 2020 The MathWorks, Inc.

    arguments
        obj (1,1) matlab.io.FTP
        filename (1,1) string {mustBeNonmissing, mustBeNonempty, ...
            matlab.io.ftp.mustNotBeEmptyString}
    end

    % Verify that connection was set up correctly
    verifyConnection(obj);

    if contains(filename, '*')
        % call dir to get list of files and then delete files one at a time
        listing = callDirWithOptions(obj, filename, true);
        listing = splitlines(listing);
        if isempty(listing{end})
            listing(end) = [];
        end
        
        for ii = 1 : numel(listing)
            matlab.io.ftp.matlab.deleteFile(obj.Connection, string(listing{ii}));
        end
    else
        % TODO: do we need to absolutize the path, or not?
        % Uncomment the next line if we need to.
        % filename = matlab.io.ftp.matlab.fullfile(h.Connection, filename);
        matlab.io.ftp.matlab.deleteFile(obj.Connection, filename);
    end
end
