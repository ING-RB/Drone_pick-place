function validateMethodAttributes(methodsToCheck, instance, ignoredAttributes)
% This function is undocumented and may change in a future release.

% Validate that INSTANCE's implementation of METHODSTOCHECK respects all method
% attribute values, except for attributes specified by IGNOREDATTRIBUTES.

% Copyright 2017-2018 The MathWorks, Inc.

methodsToCheck = toRow(methodsToCheck);

instanceMetaclass = builtin('metaclass', instance);
instanceMethods = instanceMetaclass.MethodList;

for method = methodsToCheck
    allMethodAttributes = toRow(string(properties(method)));
    for attribute = allMethodAttributes
        if any(attribute == ignoredAttributes)
            continue;
        end
        
        correspondingInstanceMethod = instanceMethods.findobj('Name', method.Name);
        if ~isempty(correspondingInstanceMethod) && ...
                ~isequaln(method.(attribute), correspondingInstanceMethod.(attribute))
            error(message('MATLAB:mock:MockContext:NonDefaultMethodAttributeValue', ...
                method.Name, attribute));
        end
    end
end
end

function value = toRow(value)
value = reshape(value, 1, []);
end

% LocalWords:  INSTANCE's IGNOREDATTRIBUTES METHODSTOCHECK isequaln
