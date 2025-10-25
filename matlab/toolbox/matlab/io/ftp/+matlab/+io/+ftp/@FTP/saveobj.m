function S = saveobj(obj)
% SAVEOBJ Save FTP object

%   Copyright 2020 The MathWorks, Inc.
    % Public properties
    S = struct("EarliestSupportedVersion", 1);
    S.Host = obj.Host;
    S.Username = obj.Username;
    S.RemoteWorkingDirectory = obj.RemoteWorkingDirectory;
    S.Mode = obj.Mode;
    S.TLSMode = obj.TLSMode;
    S.LocalDataConnectionMethod = obj.LocalDataConnectionMethod;

    % Private properties
    S.RemotePath = obj.RemotePath;
    S.Port = obj.Port;
    S.System = obj.System;

    if obj.PasswordSupplied
        warning(message("MATLAB:io:ftp:ftp:CannotSerialize"));
    end
end
