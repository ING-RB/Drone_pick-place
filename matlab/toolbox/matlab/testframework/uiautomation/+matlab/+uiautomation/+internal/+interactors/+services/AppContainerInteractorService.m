classdef AppContainerInteractorService < matlab.uiautomation.internal.interactors.services.InteractorLookupService
    % This class is undocumented and may change in a future release.
    
    % Copyright 2023 The MathWorks, Inc.
    
    methods(Sealed)
        function cls = getComponentClass(~)
            cls = ?matlab.ui.container.internal.AppContainer;
        end
        function cls = getInteractorClass(~)
            cls = ?matlab.uiautomation.internal.interactors.AppContainerInteractor;
        end
    end
end

