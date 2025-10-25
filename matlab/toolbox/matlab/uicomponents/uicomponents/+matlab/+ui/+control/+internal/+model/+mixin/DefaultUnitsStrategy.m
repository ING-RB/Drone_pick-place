classdef(Hidden) DefaultUnitsStrategy < matlab.ui.control.internal.model.mixin.UnitsStrategyInterface
    methods(Hidden)
        function [size, loc] = getFormattedSizeLocForPeerNode(obj, posPropName)
            unformattedValue = obj.getPositionValue(posPropName);
            size = unformattedValue(3:4); 
            loc = unformattedValue(1:2);
        end
    end
    
    methods
        function obj = DefaultUnitsStrategy(val)
            obj.Model = val; 
        end
    end
end