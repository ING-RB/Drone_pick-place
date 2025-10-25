% Copyright 2024 The MathWorks, Inc.
% The FQN of the method is studio.config.api.Action.getLogicalOption
% THIS FILE WILL NOT BE REGENERATED
function result = getLogicalOption(obj, name)
    arguments(Input)
        obj studio.config.api.Action
        name string
    end
    arguments(Output)
        result logical
    end
    options = studio.config.getActionCallbackOptions(obj.Internal);
    if isfield(options, name)
        result = options.(name);
    end
end