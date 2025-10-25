classdef GetDirInteractorService < matlab.uiautomation.internal.interactors.services.InteractorLookupService
    % This class is undocumented and may change in a future release.
    
    % Copyright 2024 The MathWorks, Inc.

    methods(Sealed)
        function cls = getComponentClass(~)
            cls = "uigetdir";
        end
        function cls = getInteractorClass(~)
            cls = ?matlab.uiautomation.internal.interactors.GetDirInteractor;
        end
    end
end
