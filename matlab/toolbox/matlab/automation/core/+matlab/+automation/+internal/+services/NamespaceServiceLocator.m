classdef NamespaceServiceLocator < matlab.automation.internal.services.ServiceLocator
    % This class is undocumented and will change in a future release.

    % NamespaceServiceLocator - ServiceLocator which finds classes in namespaces.
    %
    % See Also: ServiceLocator, Service, ServiceFactory

    % Copyright 2015-2023 The MathWorks, Inc.

    properties(Access=private)
        Namespace meta.package;
    end

    methods
        function serviceClasses = locate(locator, interfaceClass)
            arguments
                locator
                interfaceClass (1,1) meta.class {mustBeValidInterfaceClass};
            end

            namespaces = locator.Namespace;
            serviceClassCell = cell(1, numel(namespaces));
            for idx = 1:numel(namespaces)
                classes = namespaces(idx).ClassList;
                classes = classes(classes < interfaceClass);
                classes = classes(~[classes.Abstract]);
                serviceClassCell{idx} = classes(:);
            end
            serviceClasses = vertcat(interfaceClass(1:0,1), serviceClassCell{:});

        end
    end

    methods(Access=?matlab.automation.internal.services.ServiceLocator)
        function locator = NamespaceServiceLocator(namespace)
            locator.Namespace = namespace;
        end
    end
end

function mustBeValidInterfaceClass(interfaceClass)
if ~(interfaceClass <= ?matlab.automation.internal.services.Service)
    error(message("MATLAB:automation:ServiceLocator:InvalidInterfaceClass"));
end
end
