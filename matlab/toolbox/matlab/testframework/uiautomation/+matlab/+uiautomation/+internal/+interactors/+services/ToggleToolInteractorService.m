classdef ToggleToolInteractorService < matlab.uiautomation.internal.interactors.services.InteractorLookupService
    % This class is undocumented and may change in a future release.
    
    % Copyright 2020 The MathWorks, Inc.
    
    methods(Sealed)
        function cls = getComponentClass(~)
            cls = ?matlab.ui.container.toolbar.ToggleTool;
        end
        function cls = getInteractorClass(~)
            cls = ?matlab.uiautomation.internal.interactors.ToggleToolInteractor;
        end
    end
end

