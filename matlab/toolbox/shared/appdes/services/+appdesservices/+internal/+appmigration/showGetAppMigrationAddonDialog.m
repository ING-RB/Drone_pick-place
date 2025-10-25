function showGetAppMigrationAddonDialog(title)    
    % SHOWGETAPPMIGRATIONADDONDIALOG Shows a MATLAB dialog prompting the
    % user to install the GUIDE to App Designer Migration Tool add-on
    
    %   Copyright 2017 The MathWorks, Inc.
    
    msg = getString(message('shared_appdes:AppMigration:getAppMigrationAddonText'));
    getAddOnButton = getString(message('shared_appdes:AppMigration:getAppMigrationAddonButton'));
    cancelButton = getString(message('shared_appdes:AppMigration:cancelButton'));
    
    choice = questdlg(msg, title, getAddOnButton, cancelButton, getAddOnButton);
    
    switch choice
        case getAddOnButton
            % User selected to get the add-on. Show the add-on in the
            % add-on explorer.
            appdesservices.internal.appmigration.showAppMigrationAddon();
        case cancelButton
            % User slected cancel. Do nothing.
    end