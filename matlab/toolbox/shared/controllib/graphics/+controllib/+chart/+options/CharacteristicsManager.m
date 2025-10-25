classdef CharacteristicsManager < dynamicprops 

    methods (Access = {?controllib.chart.internal.foundation.AbstractPlot})
        function addCharacteristicOption(this,characteristicType,characteristicOptions)
            arguments
                this
                characteristicType      (1,1) string
                characteristicOptions   (1,1)
            end
            addprop(this,characteristicType);
            this.(characteristicType) = characteristicOptions;
        end

        function removeCharacteristicOption(this,characteristicType)
            p = findprop(this,characteristicType);
            if ~isempty(p)
                delete(p);
            end
        end

        function out = struct(this)
            propertyNames = fields(this);
            for k = 1:length(propertyNames)
                out.(propertyNames{k}) = struct(this.(propertyNames{k}));
            end
        end
    end
end