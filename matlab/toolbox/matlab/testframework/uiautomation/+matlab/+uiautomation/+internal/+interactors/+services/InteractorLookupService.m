classdef (Abstract) InteractorLookupService < matlab.unittest.internal.services.Service
    % This class is undocumented and may change in a future release.
    
    % Copyright 2019 The MathWorks, Inc.
    
    methods(Abstract)
        %Abstract methods that the concrete interactor service classes must implement
        getComponentClass(~);
        getInteractorClass(~);
    end
    
    methods(Sealed)   
        function fulfill(services, liaison)
            for k=1:numel(services)
                service = services(k);
                if service.supportsComponent(liaison.ComponentClass)
                    liaison.InteractorClass = service.getInteractorClass();
                    return
                end
            end
            liaison.InteractorClass = ?matlab.uiautomation.internal.interactors.InvalidInteractor;
        end
    end
    
    methods(Access = private)
        function bool = supportsComponent(service, cls)
            componentClass = service.getComponentClass();
            bool = (componentClass == cls);
        end
    end
end

