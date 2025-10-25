function removeFolder(pkg, folders)
    arguments
        pkg (1,1) matlab.mpm.Package
        folders (1,:) matlab.mpm.PackageFolder
    end

    if isempty(folders)
        return
    end

    try
        matlab.mpm.internal.removeFoldersFromPackage(pkg, [folders.Path]);
    catch ex
        throw(ex);
    end

end

%   Copyright 2024 The MathWorks, Inc.
