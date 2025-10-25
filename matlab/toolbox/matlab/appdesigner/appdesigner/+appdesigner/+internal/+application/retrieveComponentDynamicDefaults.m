function componentDynamicDefaults = retrieveComponentDynamicDefaults(hardReload)

% A function called by the AppDesigner when it is being initialized.
% It is to retrieve a components dynamic default values

% Copyright 2018 The MathWorks, Inc.

% hardReload means to reload the componentDynamicDefaults even though they
% may have already been cached.  This method gets called with this inputArg
% each time AppDesigner is started so AppDesigner has the latest component
% dynamic defaults
persistent componentDynamicDefaultsCache;

if isempty(componentDynamicDefaultsCache) || nargin == 1
    
    componentDynamicDefaultsCache = {};
    
    % get the adapter map
    adapterMap = appdesigner.internal.application.getComponentAdapterMap();
    
    % the keys of the adapter map are the component types
    componentTypes = keys(adapterMap);
    
    % loop over the componentTypes and build up the array of dynamic
    % component defaults
    for i = 1:length(componentTypes)
        componentType = componentTypes{i};
        adapterClassName = adapterMap(componentType);
        % get the dynamic properties via the adapters static method
        dynamicProps = eval( [adapterClassName '.getDynamicProperties()']);
        
        if ( ~isempty(dynamicProps))
            componentDynamicDefaultsCache{end+1} = struct('Type',componentType,...
                'DynamicProps', dynamicProps);
        end
    end
end

componentDynamicDefaults = componentDynamicDefaultsCache;

end
