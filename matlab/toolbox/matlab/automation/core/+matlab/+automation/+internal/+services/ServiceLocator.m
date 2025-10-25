classdef ServiceLocator
    % This class is undocumented and will change in a future release.
    
    % ServiceLocator - Interface that is used to locate services across module
    % boundaries dynamically.
    %
    % See Also: Service, ServiceFactory
    
    % Copyright 2015-2023 The MathWorks, Inc.
   
    methods(Static)
        function locator = forNamespace(namespace)
            % forNamespace - Create an instance which locates services in a namespace.
            %
            %   LOCATOR = matlab.automation.internal.services.ServiceLocator.forNamespace(NAMESPACE)
            %   creates a ServiceLocator that is able to look at all of the classes
            %   that reside in a given namespace and return those that are of a specific
            %   interface type. NAMESPACE is a meta.package instance and LOCATOR is the
            %   ServiceLocator which finds services contained in the NAMESPACE.
            locator = matlab.automation.internal.services.NamespaceServiceLocator(namespace);
        end
    end
    
    methods(Abstract)
        % locate - Locate all the services meeting a certain service interface
        %
        %   SERVICECLASSES = locate(LOCATOR, INTERFACECLASS) use the LOCATOR to
        %   find all of the classes which derive from the INTERFACECLASS and
        %   returns them in the SERVICECLASSES array. INTERFACECLASS is the
        %   matlab.automation.services.Service class or one of its
        %   subclasses.
        serviceClasses = locate(locator, interfaceClass)
    end
end

% LocalWords:  SERVICECLASSES INTERFACECLASS
