function result = hasUnsavedFiles(root)

% Copyright 2024 The MathWorks, Inc.

    provider = matlab.internal.project.unsavedchanges.TrackingLoadedFileProvider;
    files = matlab.internal.project.unsavedchanges.getLoadedFiles("Unsaved", provider);

    unsavedFiles = matlab.internal.cmlink.unsavedfiles.filter.unsavedInRootFolder(files, root);
    result = ~isempty(unsavedFiles);

end
