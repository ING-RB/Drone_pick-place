classdef ScaleDirectionMixin < handle
    % This class is unsupported and might change or be removed without
    % notice in a future version.
    
    % Copyright 2016-2020 The MathWorks, Inc.
    
    properties(SetObservable = true)
        ScaleDirection inspector.internal.datatype.ScaleDirection
    end
    
    methods
        function val = get.ScaleDirection(obj)
            val = obj.OriginalObjects.ScaleDirection; %#ok<*MCNPN>
        end
        
        function set.ScaleDirection(obj, val)
            for idx = 1:length(obj.OriginalObjects)
                if ~isequal(obj.OriginalObjects(idx).ScaleDirection, val.getValue)
                    obj.OriginalObjects(idx).ScaleDirection = val.getValue; %#ok<*MCNPR>
                end
            end
        end
    end
end
