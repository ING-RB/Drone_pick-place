classdef (Hidden) IconIDableComponent < appdesservices.internal.interfaces.model.AbstractModelMixin

    % Copyright 2022 The MathWorks, Inc.
    
    properties(Hidden, SetAccess = 'private', AbortSet, Transient = true)
        IconID(1,:) struct = struct();
    end
    methods (Hidden)
        function specifyIconID(obj, newValue)
            obj.IconID =  newValue;
            markPropertiesDirty(obj, {'IconID'});
        end
    end
end
