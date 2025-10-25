% Copyright 2024 The MathWorks, Inc.
% Generated using MATLAB external API code generator
% The FQN of the method is studio.config.api.Menu.addSection
% THIS FILE WILL NOTE BE REGENERATED
function result = addSection(obj, id)
    arguments(Input)
        obj studio.config.api.Menu
        id string
    end
    arguments(Output)
        result studio.config.api.MenuSection
    end

    % TODO: We need better validation because nested names have to be
    % unique it would be nice if id meant last part of FQN and we prepend
    % the parent name to the id for FQN. 
    if any(strcmp({obj.Sections.Name}, id))
        error('An item with the same id already exists.');
    end
    fields = struct();
    fields.Model = obj.getModel();
    internalType = 'studio.config.MenuSection';
    internalSection = feval(internalType, obj.getModel());
    internalSection.name = id;
    obj.doSetSectionsInternalHierarchy(internalSection);
    fields.Internal = internalSection;
    externalType = 'studio.config.api.MenuSection';
    result = feval(externalType, fields);
    obj.Sections(end+1) = result;
end
