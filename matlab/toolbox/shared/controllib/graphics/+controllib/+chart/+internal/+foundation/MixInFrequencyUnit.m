classdef MixInFrequencyUnit < matlab.mixin.SetGet
    properties (Dependent,AbortSet,SetObservable)
        FrequencyUnit {mustBeValidFrequencyUnit(FrequencyUnit)}
    end

    properties (Dependent,AbortSet)
        FrequencyUnitLabel
    end

    properties (Access = private)
        FrequencyUnit_I {mustBeValidFrequencyUnit(FrequencyUnit_I)} = "rad/s"
    end
    
    methods
        function this = MixInFrequencyUnit(value)
            arguments
                value (1,1) string
            end
            this.FrequencyUnit_I = value;
        end
        
        function set.FrequencyUnit(this,newUnit)
            arguments
                this (1,1) controllib.chart.internal.foundation.MixInFrequencyUnit
                newUnit (1,1) string
            end
            currentUnit = this.FrequencyUnit_I;
            try
                this.FrequencyUnit_I = newUnit;
                conversionFcn = getFrequencyUnitConversionFcn(this,currentUnit,newUnit);
                cbFrequencyUnitChanged(this,conversionFcn);
            catch ex
                this.FrequencyUnit_I = currentUnit;
                throw(ex);
            end
        end

        function FrequencyUnit = get.FrequencyUnit(this)
            FrequencyUnit = this.FrequencyUnit_I;
        end

        function FrequencyUnitLabel = get.FrequencyUnitLabel(this)
            validUnits = controllibutils.utGetValidFrequencyUnits;
            unitID = validUnits{strcmp(validUnits(:,1),this.FrequencyUnit),2};
            FrequencyUnitLabel = getString(message(unitID));
        end
    end
    
    methods (Access = protected)
        function conversionFcn = getFrequencyUnitConversionFcn(this,oldUnit,newUnit)
            conversionFcn = controllib.chart.internal.utils.getFrequencyUnitConversionFcn(oldUnit,newUnit);
        end
        
        function cbFrequencyUnitChanged(this,conversionFcn)
            % Overload this in subclass
        end
    end
end

function mustBeValidFrequencyUnit(frequencyUnit)
validFrequencyUnits = controllibutils.utGetValidFrequencyUnits;
validatestring(frequencyUnit,validFrequencyUnits(:,1));
end