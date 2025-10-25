function [propertiesToPopulateView, propertiesToExclude] = getControllerPropertiesForViewPopulation(controller, model)
%GETCONTROLLERPROPERTIESFORVIEWPOPULATION return appropriate properties to 
% both send to view and exclude from view

% Copyright 2018-2020 The MathWorks, Inc.

mlock; % keep variable in memory until MATLAB quits
persistent propertiesToProcessMap;
persistent propertiesToExcludeMap;
persistent propertyKeys;

if isempty(propertyKeys)
    propertyKeys = "";
    propertiesToProcessMap = struct;
    propertiesToExcludeMap = struct;
end

% Field names cannot contain '.', replace with '_'
className = class(model);
className(className=='.') = '_';
type = string(className);

import appdesservices.internal.util.ismemberForStringArrays;
if ismemberForStringArrays(type, propertyKeys)
    propertiesToPopulateView = propertiesToProcessMap.(type);
    propertiesToExclude = propertiesToExcludeMap.(type);
else
    % Get properties that the controller should process
    % The propertiesToPopulateView is of type string
    propertiesToPopulateView = controller.getPropertyNamesToProcessAtRuntime();
    propertiesToProcessMap.(type) = propertiesToPopulateView;
    
    % Get properties that are filtered out from sending to view after the
    % processing
    propertiesToExclude = string(controller.getExcludedPropertyNamesToProcessAtRuntime());
    propertiesToExcludeMap.(type) = propertiesToExclude;
    
    %Store key
    propertyKeys(end+1) = type;
end
end
