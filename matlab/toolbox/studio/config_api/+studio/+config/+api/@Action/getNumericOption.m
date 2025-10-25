% Copyright 2024 The MathWorks, Inc.
% The FQN of the method is studio.config.api.Action.getNumericOption
% THIS FILE WILL NOT BE REGENERATED
function result = getNumericOption(obj, name)
    arguments(Input)
        obj studio.config.api.Action
        name string
    end
    arguments(Output)
        result double
    end
    options = studio.config.getActionCallbackOptions(obj.Internal);
    if isfield(options, name)
        result = options.(name);
    end
end
