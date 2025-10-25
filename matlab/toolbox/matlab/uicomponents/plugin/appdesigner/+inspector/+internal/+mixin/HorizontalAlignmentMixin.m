classdef HorizontalAlignmentMixin < handle
    % This class is unsupported and might change or be removed without
    % notice in a future version.
    
    % Copyright 2016-2020 The MathWorks, Inc.
    
    properties(SetObservable = true)
        HorizontalAlignment inspector.internal.datatype.HorizontalAlignment
    end
    
    methods
        function val = get.HorizontalAlignment(obj)
            val = obj.OriginalObjects.HorizontalAlignment; %#ok<*MCNPN>
        end
        
        function set.HorizontalAlignment(obj, val)
            for idx = 1:length(obj.OriginalObjects)
                if ~isequal(obj.OriginalObjects(idx).HorizontalAlignment, val.getValue)
                    obj.OriginalObjects(idx).HorizontalAlignment = val.getValue; %#ok<*MCNPR>
                end
            end
        end
    end
end
