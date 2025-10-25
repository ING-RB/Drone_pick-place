classdef SliderInteractorService < matlab.uiautomation.internal.interactors.services.InteractorLookupService
    % This class is undocumented and may change in a future release.
    
    % Copyright 2019 The MathWorks, Inc.
    
    methods(Sealed)
        function cls = getComponentClass(~)
            cls = ?matlab.ui.control.Slider;
        end
        function cls = getInteractorClass(~)
            cls = ?matlab.uiautomation.internal.interactors.SliderInteractor;
        end
    end
end

