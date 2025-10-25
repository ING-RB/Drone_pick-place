function obj = loadobj(S)
%LOADOBJ Load FTP object

% Copyright 2020 The MathWorks, Inc.
    % Reconstruct the object.
    if isfield(S, "EarliestSupportedVersion")
        % Error if we are sure that a version incompatibility is about to occur.
        if S.EarliestSupportedVersion > matlab.io.ftp.FTP.ClassVersion
            error(message("MATLAB:io:ftp:ftp:UnsupportedVersion"));
        end
    end

    try
        obj = matlab.io.ftp.FTP(S.Host + ":" + S.Port, S.Username, ...
            "LocalDataConnectionMethod", S.LocalDataConnectionMethod, ...
            "System", S.System, "LoadObj", true, "TLSMode", S.TLSMode);
        cd(obj, S.RemoteWorkingDirectory);
    catch
        obj.RemoteWorkingDirectory = missing;
    end

    if ismissing(obj.RemoteWorkingDirectory)
        % failed to load the FTP object
        obj.Host = S.Host;
        obj.Username = S.Username;
        obj.Mode = S.Mode;
        obj.LocalDataConnectionMethod = S.LocalDataConnectionMethod;
        obj.System = S.System;
        obj.Port = S.Port;
        obj.TLSMode = S.TLSMode;
        obj.Connection = [];
    end
end
