classdef MixInTimeUnit < matlab.mixin.SetGet
    properties (Dependent,AbortSet)
        TimeUnit {controllib.chart.internal.utils.mustBeValidTimeUnit(TimeUnit)}
    end

    properties (Dependent,AbortSet,Hidden)
        TimeUnitLabel
    end

    properties (Access = private)
        TimeUnit_I {controllib.chart.internal.utils.mustBeValidTimeUnit(TimeUnit_I)} = "seconds"
    end

    methods
        function this = MixInTimeUnit(value)
            arguments
                value (1,1) string
            end
            this.TimeUnit_I = value;
        end

        function set.TimeUnit(this,newUnit)
            arguments
                this (1,1) controllib.chart.internal.foundation.MixInTimeUnit
                newUnit (1,1) string
            end
            currentUnit = this.TimeUnit_I;
            try
                this.TimeUnit_I = newUnit;
                conversionFcn = getTimeUnitConversionFcn(this,currentUnit,newUnit);
                cbTimeUnitChanged(this,conversionFcn);
            catch ex
                this.TimeUnit_I = currentUnit;
                throw(ex);
            end
        end

        function TimeUnit = get.TimeUnit(this)
            TimeUnit = this.TimeUnit_I;
        end
        
        function TimeUnitLabel = get.TimeUnitLabel(this)
            validTimeUnits = controllibutils.utGetValidTimeUnits;
            timeUnitID = validTimeUnits{strcmp(validTimeUnits(:,1),this.TimeUnit),2};
            TimeUnitLabel = getString(message(timeUnitID));
        end
    end

    methods (Access = protected)
        function conversionFcn = getTimeUnitConversionFcn(this,oldUnit,newUnit)
            conversionFcn = controllib.chart.internal.utils.getTimeUnitConversionFcn(oldUnit,newUnit);
        end

        function cbTimeUnitChanged(this,conversionFcn)
            % Overload this in subclass
        end
    end
end

function mustBeValidTimeUnit(timeUnit)
validTimeUnits = controllibutils.utGetValidTimeUnits;
validatestring(timeUnit,validTimeUnits(:,1));
end

