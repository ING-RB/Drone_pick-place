function valid = isValidPackageFolderOnPath(d)
    %ISVALIDPACKAGEFOLDERONPATH Check if package folder can go on search path.
    %   Determine whether a folder belongs to an installed package and is a valid
    %   package folder to be added to the MATLAB Search Path.
    %
    %   Installed package root folders may be added to the Path. Installed
    %   package member folders and root folders of uninstalled packages may
    %   not. All other folders are valid.

    %   Copyright 2023 The MathWorks, Inc.

    valid = true;

    if ~matlab.internal.feature('packages')
        return;
    end

    isinstalledpackage = ~ismissing(matlab.internal.packages.getOwningModularPackage(d));

    ispackagerootfolder = isfile(fullfile(d, 'resources', 'mpackage.json'));

    valid = isinstalledpackage == ispackagerootfolder;
end

