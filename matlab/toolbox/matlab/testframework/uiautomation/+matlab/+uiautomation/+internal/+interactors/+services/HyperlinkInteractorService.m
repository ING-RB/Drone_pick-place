classdef HyperlinkInteractorService < matlab.uiautomation.internal.interactors.services.InteractorLookupService
    % This class is undocumented and may change in a future release.
    
    % Copyright 2020-2023 The MathWorks, Inc.
    
    methods(Sealed)
        function cls = getComponentClass(~)
            cls = ?matlab.ui.control.Hyperlink;
        end
        function cls = getInteractorClass(~)
            cls = ?matlab.uiautomation.internal.interactors.HyperlinkInteractor;
        end
    end
end

