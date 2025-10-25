classdef IconAlignmentMixin < handle
    % This class is unsupported and might change or be removed without
    % notice in a future version.
    
    % Copyright 2016-2020 The MathWorks, Inc.
    
    properties(SetObservable = true)
        IconAlignment inspector.internal.datatype.IconAlignment
    end
    
    methods
        function set.IconAlignment(obj, inspectorValue)
            for idx = 1:length(obj.OriginalObjects) %#ok<*MCNPN>
                if ~isequal(obj.OriginalObjects(idx).IconAlignment, char(inspectorValue))
                    obj.OriginalObjects(idx).IconAlignment = char(inspectorValue); %#ok<*MCNPR>
                end
            end
        end
        
        function value = get.IconAlignment(obj)
            value = inspector.internal.datatype.IconAlignment.(obj.OriginalObjects(end).IconAlignment);
        end
    end
end
