function perms = filePermissions(locations)
%

%   Copyright 2024 The MathWorks, Inc.

    arguments
        locations (:, :) string
    end
    S = matlab.io.internal.filesystem.resolvePath(locations, ...
        ResolveSymbolicLinks=false);
    perms = matlab.io.FileSystemEntryPermissions();

    for ii = 1 : numel(S)
        if S(ii).ResolvedPath == ""
            error(message("MATLAB:io:filesystem:filePermissions:CannotFindLocation", ...
                locations(ii)));
        end
        validURL = matlab.io.internal.vfs.validators.isIRI(char(S(ii).ResolvedPath));
        if validURL && matlab.io.internal.vfs.validators.GetScheme(S(ii).ResolvedPath) ~= "file"
            perms(ii) = matlab.io.CloudPermissions(S(ii).ResolvedPath);
        else
            if isunix
                perms(ii) = matlab.io.UnixPermissions(S(ii).ResolvedPath);
            else
                perms(ii) = matlab.io.WindowsPermissions(S(ii).ResolvedPath);
            end
        end
    end
    perms = reshape(perms, size(S));
end
