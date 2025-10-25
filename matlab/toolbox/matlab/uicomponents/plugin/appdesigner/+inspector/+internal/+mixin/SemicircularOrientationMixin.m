classdef SemicircularOrientationMixin < handle
    % This class is unsupported and might change or be removed without
    % notice in a future version.
    
    % Copyright 2016-2020 The MathWorks, Inc.
    
    properties(SetObservable = true)
		Orientation inspector.internal.datatype.SemicircularOrientation
    end
    
    methods
        function val = get.Orientation(obj)
            val = obj.OriginalObjects.Orientation; %#ok<*MCNPN>
        end
        
        function set.Orientation(obj, val)
            for idx = 1:length(obj.OriginalObjects)
                if ~isequal(obj.OriginalObjects(idx).Orientation, val.getValue)
                    obj.OriginalObjects(idx).Orientation = val.getValue; %#ok<*MCNPR>
                end
            end
        end
    end
end

