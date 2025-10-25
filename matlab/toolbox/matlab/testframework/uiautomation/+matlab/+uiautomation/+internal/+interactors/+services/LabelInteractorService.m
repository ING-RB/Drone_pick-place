classdef LabelInteractorService < matlab.uiautomation.internal.interactors.services.InteractorLookupService
    % This class is undocumented and may change in a future release.
    
    % Copyright 2022 The MathWorks, Inc.
    
    methods(Sealed)
        function cls = getComponentClass(~)
            cls = ?matlab.ui.control.Label;
        end
        function cls = getInteractorClass(~)
            cls = ?matlab.uiautomation.internal.interactors.LabelInteractor;
        end
    end
end

