classdef PositionMixin < handle & ...
        matlab.graphics.mixin.internal.GraphicsDataTypeContainer
    % This class is unsupported and might change or be removed without
    % notice in a future version.
    
    % Copyright 2016-2020 The MathWorks, Inc.
    
    properties(SetObservable = true)
        Position matlab.internal.datatype.matlab.graphics.datatype.Position
    end
    
    methods
        function set.Position(obj, newPosition)
            for idx = 1:length(obj.OriginalObjects)
                if ~isequal(obj.OriginalObjects(idx).Position, newPosition)
                    obj.OriginalObjects(idx).Position = newPosition; %#ok<*MCNPR>
                end
            end
        end
        
        function pos = get.Position(obj)
            pos = obj.OriginalObjects.Position;
        end
    end
end
