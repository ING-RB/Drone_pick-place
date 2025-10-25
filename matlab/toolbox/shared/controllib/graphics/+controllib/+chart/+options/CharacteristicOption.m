classdef CharacteristicOption < controllib.chart.internal.options.BaseCharacteristicOptions ...
                              & dynamicprops 

    methods (Access = {?controllib.chart.internal.foundation.AbstractPlot})
        function addCharacteristicProperty(this,propertyName,propertyValue)
            arguments
                this (1,1) controllib.chart.options.CharacteristicOption
                propertyName (1,1) string
                propertyValue
            end
            p = addprop(this,propertyName);
            p.SetObservable = true;
            p.AbortSet = true;
            p.Dependent = true;
            p.GetMethod = @(this) getProperty(this,propertyName);
            p.SetMethod = @(this,value) setProperty(this,value,propertyName);
            p2 = addprop(this,propertyName+"_I");
            p2.Hidden = true;
            this.(propertyName) = propertyValue;
        end

        function removeCharacteristicProperty(this,propertyName)
            arguments
                this (1,1) controllib.chart.options.CharacteristicOption
                propertyName (1,1) string
            end
            p = findprop(this,propertyName);
            delete(p);
            p2 = findprop(this,propertyName+"_I");
            delete(p2);
        end
    end

    methods (Access=private)
        function value = getProperty(this,propertyName)
            value = this.(propertyName+"_I");
        end
        
        function setProperty(this,value,propertyName)
            this.(propertyName+"_I") = value;
        end
    end
end