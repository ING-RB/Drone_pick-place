% Copyright 2024 The MathWorks, Inc.
% The FQN of the method is studio.config.api.Config.findAction
% THIS FILE WILL NOT BE REGENERATED
function result = findAction(obj, name)
    arguments(Input)
        obj studio.config.api.Config
        name string
    end
    arguments(Output)
        result {mustBeStudioConfigActionOrEmpty}
    end
    result = [];
    for element = obj.Elements
        action = element.findAction(name);
        if ~isempty(action) && strcmp(action.Name, name)
            result = action;
            break;
        end
    end
end

function mustBeStudioConfigActionOrEmpty(value)
    if ~isempty(value) && ~isa(value,"studio.config.api.Action")
        error("return value must be a studio.config.api.Action or empty");
    end
end
