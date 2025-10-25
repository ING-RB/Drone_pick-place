function verifyConnection(obj)
%VERIFYCONNECTION Verify that connection can be established to FTP server

% Copyright 2020 The MathWorks, Inc.
    if isempty(obj.Connection)
        % Connection was not set up correctly, error
        error(message("MATLAB:io:ftp:ftp:NoConnection", obj.Host, obj.Port));
    end

    % cd to the correct folder if a connection was lost.
    cd(obj, obj.RemoteWorkingDirectory);
end
