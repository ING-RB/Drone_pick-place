function obj = loadobj(S)
%LOADOBJ Load SFTP object

% Copyright 2020-2021 The MathWorks, Inc.
    % Reconstruct the object.
    if isfield(S, "EarliestSupportedVersion")
        % Error if we are sure that a version incompatibility is about to occur.
        if S.EarliestSupportedVersion > matlab.io.sftp.SFTP.ClassVersion
            error(message("MATLAB:io:ftp:ftp:UnsupportedVersion"));
        end
    end

    try
        obj = matlab.io.sftp.SFTP(S.Host + ":" + S.Port, S.User, ...
            "ServerLocale", S.ServerLocale, "ServerSystem", S.ServerSystem, ...
            "DatetimeType", S.DatetimeType);
        cd(obj, S.RemoteWorkingDirectory);
        obj.Cleanup = onCleanup(@()close(obj));
    catch
        obj.RemoteWorkingDirectory = missing;
    end

    if ismissing(obj.RemoteWorkingDirectory)
        % failed to load the FTP object
        obj.Host = S.Host;
        obj.User = S.User;
        obj.Port = S.Port;

        obj.ServerSystem = S.ServerSystem;
        obj.DatetimeType = S.DatetimeType;
        obj.ServerLocale = S.ServerLocale;

        obj.Connection = [];
    end
end
