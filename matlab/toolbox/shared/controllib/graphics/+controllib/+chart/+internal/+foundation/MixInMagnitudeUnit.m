classdef MixInMagnitudeUnit < matlab.mixin.SetGet
    properties (Dependent,AbortSet,SetObservable)
        MagnitudeUnit {mustBeValidMagnitudeUnit(MagnitudeUnit)}
    end

    properties (Dependent,AbortSet)
        MagnitudeUnitLabel
    end

    properties (Access = private)
        MagnitudeUnit_I {mustBeValidMagnitudeUnit(MagnitudeUnit_I)} = "abs"
    end
    
    methods
        function this = MixInMagnitudeUnit(value)
            arguments
                value (1,1) string
            end
            this.MagnitudeUnit_I = value;
        end
        
        function set.MagnitudeUnit(this,newUnit)
            arguments
                this (1,1) controllib.chart.internal.foundation.MixInMagnitudeUnit
                newUnit (1,1) string
            end
            currentUnit = this.MagnitudeUnit;
            try
                this.MagnitudeUnit_I = newUnit;
                conversionFcn = controllib.chart.internal.utils.getMagnitudeUnitConversionFcn(...
                    currentUnit,newUnit);
                cbMagnitudeUnitChanged(this,conversionFcn);
            catch ex
                this.MagnitudeUnit_I = currentUnit;
                throw(ex);
            end
        end

        function MagnitudeUnit = get.MagnitudeUnit(this)
            MagnitudeUnit = this.MagnitudeUnit_I;
        end

        function MagnitudeUnitLabel = get.MagnitudeUnitLabel(this)
            switch this.MagnitudeUnit_I
                case "dB"
                    MagnitudeUnitLabel = getString(message('Controllib:gui:strDB'));
                case "abs"
                    MagnitudeUnitLabel = getString(message('Controllib:gui:strAbsolute'));
            end
        end
    end
    
    methods (Access = protected)
        function conversionFcn = getMagnitudeUnitConversionFcn(this,oldUnit,newUnit)
            conversionFcn = controllib.chart.internal.utils.getMagnitudeUnitConversionFcn(oldUnit,newUnit);
        end
        
        function cbMagnitudeUnitChanged(this,conversionFcn)
            % Overload this in subclass
        end
    end
end

function mustBeValidMagnitudeUnit(MagnitudeUnit)
validMagnitudeUnits = {'dB','abs'};
validatestring(MagnitudeUnit,validMagnitudeUnits);
end

