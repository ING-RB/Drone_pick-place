classdef MixInPhaseUnit < matlab.mixin.SetGet
    properties (Dependent,AbortSet,SetObservable)
        PhaseUnit {mustBeValidPhaseUnit(PhaseUnit)}
    end

    properties (Dependent,AbortSet)
        PhaseUnitLabel
    end

    properties (Access = private)
        PhaseUnit_I {mustBeValidPhaseUnit(PhaseUnit_I)} = "rad"
    end
    
    methods
        function this = MixInPhaseUnit(value)
            arguments
                value (1,1) string
            end
            this.PhaseUnit_I = value;
        end
        
        function set.PhaseUnit(this,newUnit)
            arguments
                this (1,1) controllib.chart.internal.foundation.MixInPhaseUnit
                newUnit (1,1) string
            end
            currentUnit = this.PhaseUnit_I;
            try
                this.PhaseUnit_I = newUnit;
                conversionFcn = getPhaseUnitConversionFcn(this,currentUnit,newUnit);
                cbPhaseUnitChanged(this,conversionFcn);
            catch ex
                this.PhaseUnit_I = currentUnit;
                throw(ex);
            end
        end

        function PhaseUnit = get.PhaseUnit(this)
            PhaseUnit = this.PhaseUnit_I;
        end
        
        function PhaseUnitLabel = get.PhaseUnitLabel(this)
            PhaseUnitLabel = this.PhaseUnit_I;
            switch this.PhaseUnit_I
                case "deg"
                    PhaseUnitLabel = getString(message('Controllib:gui:strDeg'));
                case "rad"
                    PhaseUnitLabel = getString(message('Controllib:gui:strRad'));
            end
        end

    end
    
    methods (Access = protected)
        function conversionFcn = getPhaseUnitConversionFcn(this,oldUnit,newUnit)
            conversionFcn = controllib.chart.internal.utils.getPhaseUnitConversionFcn(oldUnit,newUnit);
        end
        
        function cbPhaseUnitChanged(this,conversionFcn)
            % Overload this in subclass
        end
    end
end

function mustBeValidPhaseUnit(PhaseUnit)
validPhaseUnits = {'deg','rad'};
validatestring(PhaseUnit,validPhaseUnits);
end

