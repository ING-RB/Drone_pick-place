function addFolder(pkg, folders, opts)
    arguments
        pkg (1,1) matlab.mpm.Package
        folders (1,:) {mustBeTextOrPackageFolder}
        opts.Languages (1,:) matlab.mpm.PackageFolderLanguage = ...
            matlab.mpm.PackageFolderLanguage.matlab
    end

    if isempty(folders)
        return
    end
    
    if(matlab.mpm.internal.istext(folders))
        folders = matlab.mpm.PackageFolder(folders, Languages=opts.Languages);
    end

    try
        matlab.mpm.internal.addFoldersToPackage(pkg, folders);
    catch ex
        throw(ex);
    end

end

function mustBeTextOrPackageFolder(folders)
if ~isa(folders, "matlab.mpm.PackageFolder") && ~matlab.mpm.internal.istext(folders)
    error("mpm:arguments:InvalidArgumentType", ...
              message("mpm:arguments:InvalidArgumentTypeOneOf", ...
                      "folders", ...
                      message("mpm:arguments:InvalidArgumentTwoTypes", ...
                              "string", ...
                              "matlab.mpm.PackageFolder").string()).string());
end
end

%   Copyright 2024 The MathWorks, Inc.
