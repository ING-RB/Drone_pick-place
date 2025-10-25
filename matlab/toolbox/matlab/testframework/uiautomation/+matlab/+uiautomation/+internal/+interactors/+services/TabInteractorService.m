classdef TabInteractorService < matlab.uiautomation.internal.interactors.services.InteractorLookupService
    % This class is undocumented and may change in a future release.
    
    % Copyright 2019 The MathWorks, Inc.
    
    methods(Sealed)
        function cls = getComponentClass(~)
            cls = ?matlab.ui.container.Tab;
        end
        function cls = getInteractorClass(~)
            cls = ?matlab.uiautomation.internal.interactors.TabInteractor;
        end
    end
end

