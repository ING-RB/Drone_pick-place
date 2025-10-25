function folders = validateFolders(folders)
%validateFolders    Validate that folder names are strings

%   Copyright 2023 The MathWorks, Inc.
    % Use the value of the underlying datastore's Folders property.
    folders = convertCharsToStrings(folders);
    if ~isstring(folders)
        error(message("MATLAB:io:datastore:write:write:FoldersString"));
    end
end
