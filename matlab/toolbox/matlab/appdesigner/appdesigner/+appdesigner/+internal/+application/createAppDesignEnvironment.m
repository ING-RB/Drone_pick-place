function [appDesignEnvironment, appDesignerModel] = createAppDesignEnvironment(componentAdapterMap, appDesignerModelAlreadyCreated)
    %CREATEAPPDESIGNENVIRONMENT Internal function to create
    % AppDesignEnvironment, and AppDesignerModel
    
    % Copyright 2021 The MathWorks, Inc.
    
    narginchk(1, 2);
    
    if nargin == 1
        appDesignerModelAlreadyCreated = [];
    end
    
    % create AppDesignerModel
    if isempty(appDesignerModelAlreadyCreated)
        appDesignerModel = appdesigner.internal.model.AppDesignerModel(componentAdapterMap);
    else
        appDesignerModel = appDesignerModelAlreadyCreated;
    end

    % hide AD folders from call stack by default
    appdesigner.internal.debug.AppDebugUtilities.hideInternalFoldersFromCallstack();
    
    % the AppDesignEnvironment
    appDesignEnvironment = appdesigner.internal.application.AppDesignEnvironment(appDesignerModel);
    addlistener(appDesignEnvironment,'ObjectBeingDestroyed', ...
        @(source, event) cleanup(appDesignerModel));
end

function cleanup(appDesignerModel)    
    delete(appDesignerModel)
    % To reset global unhide flag as false (default) and to hide app designer internal folders from call stacks
    % in order to clean up unhide folders when launching from appdesigner_debug
    appdesigner.internal.debug.AppDebugUtilities.resetToDefault();
end