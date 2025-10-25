function generatePropertyEditingCode(obj, properties)
% Input aingle object and a cellarray of properties 
% and triggers codegen for each of these properties

% Copyright 2024 The MathWorks, Inc.

if isdeployed
    return
end


hCodeGenerator = matlab.graphics.internal.propertyinspector.PropertyEditingCodeGenerator.getInstance();
ev = internal.matlab.inspector.PropertyEditedEventData;
for k=1:length(properties)
    ev.Property = properties{k};
    ev.Object = obj;
    hCodeGenerator.propertyChanged([],ev);
end
end