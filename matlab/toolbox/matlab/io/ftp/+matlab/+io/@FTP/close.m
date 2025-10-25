function close(obj)
%CLOSE Close the connection with the server.
%    CLOSE(FTP) closes the connection with the server.
%    CLOSE(SFTP) closes the connection with the server.

% Copyright 2020 The MathWorks, Inc.

    try
        obj.Connection = [];
    catch
        % Do nothing.  The error was probably that we were already disconnected.
    end
end
