classdef(Hidden) UIControlUnitsStrategy < matlab.ui.control.internal.model.mixin.UnitsStrategyInterface
    methods
        function obj = UIControlUnitsStrategy(val)
            obj.Model = val; 
        end
    end
    
    methods(Hidden)
        function [size, loc] = getFormattedSizeLocForPeerNode(obj, posPropName)
            import matlab.ui.internal.componentframework.services.core.units.UnitsServiceController;
            unformattedValue = obj.getPositionValue(posPropName); 
            
            % Object needs to be formatted as a struct
                [size, loc] = ...
                    UnitsServiceController.getUnitsValueDataForSizeLocationView(obj.Model,... 
                                                                                unformattedValue);
        end
    end
end