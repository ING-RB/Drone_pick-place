function validatePropertyAttributes(propertiesToCheck, instance, ignoredAttributes)
% This function is undocumented and may change in a future release.

% Validate that INSTANCE's implementation of PROPERTIESTOCHECK respects all method
% attribute values, except for attributes specified by IGNOREDATTRIBUTES.

% Copyright 2017-2018 The MathWorks, Inc.

propertiesToCheck = toRow(propertiesToCheck);

instanceMetaclass = builtin('metaclass', instance);
instanceProperties = instanceMetaclass.PropertyList;

for property = propertiesToCheck
    allPropertyAttributes = toRow(string(properties(property)));
    for attribute = allPropertyAttributes
        if any(attribute == ignoredAttributes)
            continue;
        end
        
        correspondingInstanceProperty = instanceProperties.findobj('Name', property.Name);
        if ~isempty(correspondingInstanceProperty) && ...
                ~isequaln(property.(attribute), correspondingInstanceProperty.(attribute))
            error(message('MATLAB:mock:MockContext:NonDefaultPropertyAttributeValue', ...
                property.Name, attribute));
        end
    end
end
end

function value = toRow(value)
value = reshape(value, 1, []);
end

% LocalWords:  INSTANCE's PROPERTIESTOCHECK IGNOREDATTRIBUTES isequaln
