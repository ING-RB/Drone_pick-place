classdef PointerMixin < handle
    % POINTERMIXIN - mixin class for the Pointer property of
    % UIFigure
    
    % Copyright 2019-2020 The MathWorks, Inc.
    
    properties(SetObservable = true)
        Pointer inspector.internal.datatype.Pointer
    end
    
    methods
        function set.Pointer(obj, inspectorValue)
            for idx = 1:length(obj.OriginalObjects) %#ok<*MCNPN>
                if ~isequal(obj.OriginalObjects(idx).Pointer, char(inspectorValue))
                    obj.OriginalObjects(idx).Pointer = char(inspectorValue); %#ok<*MCNPR>
                end
            end
        end
        
        function value = get.Pointer(obj)
            value = inspector.internal.datatype.Pointer.(obj.OriginalObjects(end).Pointer);
        end
    end
end