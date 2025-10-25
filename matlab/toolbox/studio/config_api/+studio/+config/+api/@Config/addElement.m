% Copyright 2024 The MathWorks, Inc.
% Generated using MATLAB external API code generator
% The FQN of the method is studio.config.api.Config.addElement
% THIS FILE WILL NOTE BE REGENERATED
function result = addElement(obj, id, type)
    arguments(Input)
        obj studio.config.api.Config
        id string
        type string = 'studio.config.api.Menu'
    end
    arguments(Output)
        result studio.config.api.ConfigElement
    end

    if any(strcmp({obj.Elements.Name}, id))
        error('An element with the same id already exists.');
    end
    fields = struct();
    fields.Model = obj.getModel();
    internalType = strcat('studio.config.',type);
    internalElement = feval(internalType, obj.getModel());
    internalElement.name = id;
    obj.doSetElementsInternalHierarchy(internalElement);
    fields.Internal = internalElement;
    externalType = strcat('studio.config.api.', type);
    result = feval(externalType, fields);
    obj.Elements(end+1) = result;
end
