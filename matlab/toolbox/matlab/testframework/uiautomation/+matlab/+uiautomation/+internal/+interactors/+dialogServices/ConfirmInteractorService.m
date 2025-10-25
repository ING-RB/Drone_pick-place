classdef ConfirmInteractorService < matlab.uiautomation.internal.interactors.services.InteractorLookupService
    % This class is undocumented and may change in a future release.
    
    % Copyright 2023 The MathWorks, Inc.
    
    methods(Sealed)
        function cls = getComponentClass(~)
            cls = "uiconfirm";
        end
        function cls = getInteractorClass(~)
            cls = ?matlab.uiautomation.internal.interactors.ConfirmInteractor;
        end
    end
end
