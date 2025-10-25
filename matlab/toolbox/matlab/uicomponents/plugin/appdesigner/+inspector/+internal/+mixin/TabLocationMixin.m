classdef TabLocationMixin < handle
    % This class is unsupported and might change or be removed without
    % notice in a future version.
    
    % Copyright 2016-2020 The MathWorks, Inc.
    
    properties(SetObservable = true)
        TabLocation inspector.internal.datatype.TabLocation
    end
    
    methods
        function set.TabLocation(obj, inspectorValue)
            for idx = 1:length(obj.OriginalObjects) %#ok<*MCNPN>
                if ~isequal(obj.OriginalObjects(idx).TabLocation, char(inspectorValue))
                    obj.OriginalObjects(idx).TabLocation = char(inspectorValue); %#ok<*MCNPR>
                end
            end
        end
        
        function value = get.TabLocation(obj)
            value = inspector.internal.datatype.TabLocation.(obj.OriginalObjects(end).TabLocation);
        end
    end
end
