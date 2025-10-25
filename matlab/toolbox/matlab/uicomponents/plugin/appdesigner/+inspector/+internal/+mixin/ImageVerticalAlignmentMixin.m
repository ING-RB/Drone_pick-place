classdef ImageVerticalAlignmentMixin < handle
    % This class is unsupported and might change or be removed without
    % notice in a future version.
    
    % Copyright 2016-2020 The MathWorks, Inc.

    properties(SetObservable = true)
        VerticalAlignment inspector.internal.datatype.ImageVerticalAlignment
    end
    
    methods
        function val = get.VerticalAlignment(obj)
            val = obj.OriginalObjects.VerticalAlignment; %#ok<*MCNPN>
        end
        
        function set.VerticalAlignment(obj, val)
            for idx = 1:length(obj.OriginalObjects)
                if ~isequal(obj.OriginalObjects(idx).VerticalAlignment, val.getValue)
                    obj.OriginalObjects(idx).VerticalAlignment = val.getValue; %#ok<*MCNPR>
                end
            end
        end
    end
end