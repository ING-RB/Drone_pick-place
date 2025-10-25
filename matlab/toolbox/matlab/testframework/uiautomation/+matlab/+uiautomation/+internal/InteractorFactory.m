classdef (Abstract) InteractorFactory
    % This class is undocumented and subject to change in a future release
    
    % Copyright 2016-2023 The MathWorks, Inc.
    
    methods (Static)
        
        function actor = getInteractorForHandle(H, dispatcher)
            import matlab.uiautomation.internal.dispatchers.WarnInHGCallbacks;
            import matlab.uiautomation.internal.dispatchers.ThrowableDispatchDecorator;
            import matlab.uiautomation.internal.UIDispatcher;
            import matlab.unittest.internal.services.ServiceFactory;
            import matlab.automation.internal.services.ServiceLocator;
            
            if nargin < 2
                dispatcher = UIDispatcher.forComponent(H);
                dispatcher = WarnInHGCallbacks(dispatcher);
                dispatcher = ThrowableDispatchDecorator(dispatcher);
            end
            
            liaison = matlab.uiautomation.internal.InteractorLookupLiaison;
            liaison.ComponentClass = metaclass(H);
            namespace = "matlab.uiautomation.internal.interactors.services";
            locator = ServiceLocator.forNamespace(matlab.metadata.Namespace.fromName(namespace));
            serviceClass = ?matlab.uiautomation.internal.interactors.services.InteractorLookupService;
            locatedServiceClasses = locator.locate(serviceClass);
            locatedServices = ServiceFactory.create(locatedServiceClasses);
            fulfill(locatedServices, liaison);
            
            %Construct Interactor
            cls = liaison.InteractorClass;
            actor = feval(str2func(cls.Name), H, dispatcher);
        end
        
    end  
end

% LocalWords:  Interactor interactors cls func
