% Copyright 2024 The MathWorks, Inc.
% Generated using MATLAB external API code generator
% The FQN of the method is studio.config.api.MenuSection.addItem
% THIS FILE WILL NOTE BE REGENERATED
function result = addItem(obj, id, type)
    arguments(Input)
        obj studio.config.api.MenuSection
        id string
        type string
    end
    arguments(Output)
        result studio.config.api.Item
    end

    % TODO: We need better validation because nested names have to be
    % unique it would be nice if id meant last part of FQN and we prepend
    % the parent name to the id for FQN. 
    if any(strcmp({obj.Items.Name}, id))
        error('An item with the same id already exists.');
    end
    fields = struct();
    fields.Model = obj.getModel();
    internalType = strcat('studio.config.',type);
    internalItem = feval(internalType, obj.getModel());
    internalItem.name = id;
    obj.doSetItemsInternalHierarchy(internalItem);
    fields.Internal = internalItem;
    externalType = strcat('studio.config.api.', type);
    result = feval(externalType, fields);
    if isa(result, 'studio.config.api.ItemWithAction' )
        result.initAction();
    end
    obj.Items(end+1) = result;
end
