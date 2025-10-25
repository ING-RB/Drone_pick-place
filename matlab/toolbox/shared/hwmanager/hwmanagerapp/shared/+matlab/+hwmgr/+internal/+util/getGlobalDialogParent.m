function parent = getGlobalDialogParent()
    % This utility function gets a global parent for all Hardware Manager
    % dialogs
    
    % Copyright 2019-2020 The MathWorks, Inc.
      
    parent = [];
    hwmgr = matlab.hwmgr.internal.HardwareManagerFramework.getInstance('CreateInstance', false);
    if isempty(hwmgr)
       return; 
    end
    appContainer = hwmgr.DisplayManager.Window.AppContainer;
    parent = appContainer;
end
