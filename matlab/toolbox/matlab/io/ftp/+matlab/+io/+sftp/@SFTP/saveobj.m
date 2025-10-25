function S = saveobj(obj)
% SAVEOBJ Save SFTP object

%   Copyright 2020-2021 The MathWorks, Inc.
    % Public properties
    S = struct("EarliestSupportedVersion", 1);
    S.Host = obj.Host;
    S.User = obj.User;
    S.Port = obj.Port;
    S.ServerSystem = obj.ServerSystem;
    S.DatetimeType = obj.DatetimeType;
    S.ServerLocale = obj.ServerLocale;

    if isempty(dir(fullfile(string(getenv("HOME")), ".ssh")))
        % cannot save this object since it was either constructed using
        % password authentication or SSH keys authentication
        warning(message("MATLAB:io:ftp:ftp:CannotSerialize"));
    end

    % Protected properties
    S.RemotePath = obj.RemotePath;
    S.RemoteWorkingDirectory = obj.RemoteWorkingDirectory;
end
