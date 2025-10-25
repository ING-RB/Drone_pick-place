% Copyright 2024 The MathWorks, Inc.
% The FQN of the method is studio.config.api.Action.setStringOption
% THIS FILE WILL NOT BE REGENERATED
function setStringOption(obj, name, option)
    arguments(Input)
        obj studio.config.api.Action
        name string
        option string
    end
    options = studio.config.getActionCallbackOptions(obj.Internal);
    options.(name) = option;
    studio.config.setActionCallbackOptions(obj.Internal, options);
end
