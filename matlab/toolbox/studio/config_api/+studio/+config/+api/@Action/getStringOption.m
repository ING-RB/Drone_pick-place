% Copyright 2024 The MathWorks, Inc.
% The FQN of the method is studio.config.api.Action.getStringOption
% THIS FILE WILL NOT BE REGENERATED
function result = getStringOption(obj, name)
    arguments(Input)
        obj studio.config.api.Action
        name string
    end
    arguments(Output)
        result string
    end
    options = studio.config.getActionCallbackOptions(obj.Internal);
    if isfield(options, name)
        result = options.(name);
    end
end
