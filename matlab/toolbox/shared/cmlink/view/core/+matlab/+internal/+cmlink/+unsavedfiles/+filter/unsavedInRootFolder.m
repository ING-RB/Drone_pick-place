function unsavedFilesInRoot = unsavedInRootFolder(loadedFiles, root)

% Copyright 2024 The MathWorks, Inc.

    import matlab.internal.project.unsavedchanges.Property;
    matches = arrayfun(@(file) file.hasProperty(Property.Unsaved), loadedFiles);
    allUnsavedFiles = loadedFiles(matches);
    if isempty(allUnsavedFiles)
        unsavedFilesInRoot = struct("name",{}, "files", {});
        return;
    end

    function inRoot = nIsInRoot(file)
        inRoot = file.Path.startsWith(root);
    end
    isValid = arrayfun( @nIsInRoot,  allUnsavedFiles);
    unsavedFilesInRoot = allUnsavedFiles(isValid);

end
