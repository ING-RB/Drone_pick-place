classdef BorderTypeMixin < handle
    % This class is unsupported and might change or be removed without
    % notice in a future version.
    
    % Copyright 2016-2020 The MathWorks, Inc.
    
    properties(SetObservable = true)
        BorderType inspector.internal.datatype.BorderType
    end
    
    methods
        function set.BorderType(obj, inspectorValue)
            for idx = 1:length(obj.OriginalObjects) %#ok<*MCNPN>
                if ~isequal(obj.OriginalObjects(idx).BorderType, char(inspectorValue))
                    obj.OriginalObjects(idx).BorderType = char(inspectorValue); %#ok<*MCNPR>
                end
            end
        end
        
        function value = get.BorderType(obj)
            value = inspector.internal.datatype.BorderType.(obj.OriginalObjects(end).BorderType);
        end
    end
end
