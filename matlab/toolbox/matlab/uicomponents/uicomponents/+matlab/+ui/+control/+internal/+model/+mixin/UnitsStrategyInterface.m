classdef (Hidden) UnitsStrategyInterface < appdesservices.internal.interfaces.model.AbstractModelMixin
    properties(Access = 'protected', Transient, NonCopyable)
        Model
    end
    
    methods(Abstract, Hidden)
        [size, loc] = getFormattedSizeLocForPeerNode(obj, posPropName);
    end
    
    methods(Access = 'protected')
        function val = getPositionValue(obj, posPropName)
            val = obj.Model.(posPropName);
        end
    end
end