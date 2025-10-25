% Copyright 2024 The MathWorks, Inc.
% Generated using MATLAB external API code generator
% The FQN of the method is studio.config.api.ItemWithAction.initAction
% THIS FILE WILL NOTE BE REGENERATED
function result = initAction(obj)
    arguments(Output)
        result studio.config.api.Action
    end
    fields = struct();
    fields.Model = obj.getModel();
    internalInternal = studio.config.Action(obj.getModel());
    fields.Internal = internalInternal;
    fields.Name = strcat(obj.Name, '.action');
    obj.doSetActionInternalHierarchy(internalInternal);
    result = studio.config.api.Action(fields);
    oldObj = obj.Action;
    obj.Action = result;
    delete(oldObj);
end
