function isInstalled = isGUIDEAppMigrationAddonInstalled
    % ISGUIDEAPPMIGRATIONADDONINSTALLED Returns true if app migration tool
    % add-on is installed
    
    %   Copyright 2017-2020 The MathWorks, Inc.
    
    ADDON_NAME = 'GUIDE to App Designer Migration Tool for MATLAB';
    
    isInstalled = false;
    
    installedSupportPackages = matlabshared.supportpkg.getInstalled;
    
    if ~isempty(installedSupportPackages)
        isInstalled = any(strcmpi(ADDON_NAME, ...
            {installedSupportPackages.Name}));
    end
    
    % The add-on is considered "installed" if it was installed by support
    % package installer or the add-on files are on the path.
    isInstalled = isInstalled ||...
        ~isempty(which('appmigration.internal.GUIDEAppConverter'));