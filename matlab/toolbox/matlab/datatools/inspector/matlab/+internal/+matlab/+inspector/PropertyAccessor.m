% This class is unsupported and might change or be removed without
% notice in a future version.

% PropertyAccessor is used to access properties of objects which require friend
% object access of the AbstractControllerMixin.  The other classes which use
% this, like InspectorProxyMixin, cannot extend AbstractControllerMixin
% directly, because it causes circular dependencies during the inspector
% registration build.

% Copyright 2015-2020 The MathWorks, Inc.

classdef PropertyAccessor < appdesservices.internal.interfaces.controller.AbstractControllerMixin
    methods(Static)
        function v = getValue(obj, propName)
            v = obj.(propName);
        end
        
        function setValue(obj, propName, value)
            obj.(propName) = value;
        end
    end
end