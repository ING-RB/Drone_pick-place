function [matchedPropertyNames, modePropertyNames] = getComponentModeProperties(className, includeHiddenProperty)
%GETCOMPONENTMODEPROPERTIES return properties that contain complementary
%mode properties

% Copyright 2018-2020 The MathWorks, Inc.

mlock; % keep variable in memory until MATLAB quits
persistent modePropertyNameMap;
persistent propertyNameMap;
persistent propertyKeys;

if isempty(propertyKeys)
    propertyKeys = "";
    propertyNameMap = struct;
    modePropertyNameMap = struct;
end

% Field names cannot contain '.', replace with '_'
type = className;
type(type=='.') = '_';
type = string(type);

import appdesservices.internal.util.ismemberForStringArrays;
if ismemberForStringArrays(type, propertyKeys)
    matchedPropertyNames = propertyNameMap.(type);
    modePropertyNames = modePropertyNameMap.(type); 
else
    [matchedPropertyNames, modePropertyNames] = appdesservices.internal.interfaces.controller.mixin.ViewPropertiesHandler.parseClassPropertyNamesForMode(className, includeHiddenProperty);
    propertyNameMap.(type) = matchedPropertyNames;
    modePropertyNameMap.(type) = modePropertyNames;  
    
    %Store key
    propertyKeys(end+1) = type;
end

end
