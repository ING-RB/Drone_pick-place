function folderLayout = validateFolderLayout(ds, folderLayout, folders)
%validateFolderLayout    Validate that the FolderLayout is an acceptable
%   input value

%   Copyright 2023-2024 The MathWorks, Inc.
    % Normalize partially-matched FolderLayout values to "duplicate" or
    % "flatten".
    persistent httpsPattern httpPattern;
    folderLayout = validatestring(folderLayout, ["duplicate", "flatten"], ...
        "writeall", "FolderLayout");
    
    % If the FolderLayout is "duplicate", Folders must be non-empty.
    if folderLayout == "duplicate"
        if isempty(folders)
            if isempty(httpsPattern)
                httpsPattern = regexpPattern("https://");
                httpPattern = regexpPattern("http://");
            end
            if isprop(ds, "Files") && all(startsWith(ds.Files, ...
                    [httpsPattern, httpPattern]))
                error(message("MATLAB:io:datastore:write:write:FolderLayoutFlattenForHttps"));
            else
                error(message("MATLAB:io:datastore:write:write:FoldersPropertyIsEmpty"));
            end
        end
    end
end
