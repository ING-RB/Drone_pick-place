function map = createComponentAdapterMap(metaClasses)
%CREATECOMPONENTADAPTERMAP create a map of component adapters from the
% adapter meta classes

%   Copyright 2015 - 2017 The MathWorks, Inc.

    map = containers.Map;

    % loop over the adapter classes and build the map
    for i = 1:length(metaClasses)
        % get the adapter class name
        adapterClassName = metaClasses{i}.Name;
        
        if(strcmp(adapterClassName, 'appdesigner.internal.componentadapter.uicomponents.adapter.UserComponentAdapter'))
            continue;
        end

        adapterInstance = feval(adapterClassName);
        % Retrieve the adapter's component type.
        type = adapterInstance.ComponentType;

        % add the adapter info to the map.  The key is the
        % component type and value is the adapter class name for that type
        map(type) = adapterClassName;
    end    
end