function folders = listParentFolderNames(filenames)
    % listParentFolderNames uses a vectorized fileparts implementation to
    % get the parent folders of every resolved file name.

    %   Copyright 2019 The MathWorks, Inc.

    % Exit early if an empty list is passed as input.
    if isempty(filenames)
        folders = {};
        return
    end

    import matlab.io.datastore.internal.write.utility.vectorizedFileparts
    folders = vectorizedFileparts(filenames);
    
    % Vectorized fileparts seems to only return string arrays. Convert back
    % to cellstr for compatibility with the rest of the Folders property
    % code.
    if strlength(folders) == 0 % Handle "" separately
        folders = {};
    else
        folders = cellstr(folders);
    end
end
