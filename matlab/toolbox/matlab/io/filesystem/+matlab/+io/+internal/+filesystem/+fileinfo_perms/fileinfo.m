function F = fileinfo(locations)
%

%   Copyright 2024 The MathWorks, Inc.

    arguments
        locations (:, :) string
    end
    import matlab.io.internal.filesystem.fileinfo_perms.*
    S = matlab.io.internal.filesystem.resolvePathWithAttributes(locations, ...
        ResolveSymbolicLinks=false);
    F = FileSystemEntryInformation();
    for ii = 1 : numel(S)
        if S(ii).Type == "File"
            F(ii) = FileInformation(S(ii).ResolvedPath, LocationResolved=true);
        elseif S(ii).Type == "Folder"
            F(ii) = FolderInformation(S(ii).ResolvedPath, LocationResolved=true);
        elseif S(ii).Type == "SymbolicLink"
            F(ii) = SymbolicLinkInformation(S(ii).ResolvedPath, LocationResolved=true);
        else
            error("Could not resolve location");
        end
    end
    F = reshape(F, size(S));
end
