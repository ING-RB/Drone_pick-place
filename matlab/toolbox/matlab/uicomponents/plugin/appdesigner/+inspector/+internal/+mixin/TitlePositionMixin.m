classdef TitlePositionMixin < handle
    % This class is unsupported and might change or be removed without
    % notice in a future version.
    
    % Copyright 2016-2020 The MathWorks, Inc.
    
    properties(SetObservable = true)
		TitlePosition inspector.internal.datatype.TitlePosition
    end
    
    methods
        function val = get.TitlePosition(obj)
            val = obj.OriginalObjects.TitlePosition; %#ok<*MCNPN>
        end
        
        function set.TitlePosition(obj, val)
            for idx = 1:length(obj.OriginalObjects)
                if ~isequal(obj.OriginalObjects(idx).TitlePosition, val.getValue)
                    obj.OriginalObjects(idx).TitlePosition = val.getValue; %#ok<*MCNPR>
                end
            end
        end
    end
end
