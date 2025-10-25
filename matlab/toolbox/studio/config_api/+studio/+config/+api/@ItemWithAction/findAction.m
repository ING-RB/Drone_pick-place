% Copyright 2024 The MathWorks, Inc.
% The FQN of the method is studio.config.api.ItemWithAction.findAction
% THIS FILE WILL NOT BE REGENERATED
function result = findAction(obj, name)
    arguments(Input)
        obj studio.config.api.ItemWithAction
        name string
    end
    arguments(Output)
        result {mustBeStudioConfigActionOrEmpty}
    end
    result = [];
    if strcmp(obj.Action.Name, name)
        result = obj.Action;
    end
end

function mustBeStudioConfigActionOrEmpty(value)
    if ~isempty(value) && ~isa(value,"studio.config.api.Action")
        error("return value must be a studio.config.api.Action or empty");
    end
end
