classdef PassiveWorstIndexResponse < controllib.chart.internal.characteristics.AbstractCharacteristic        
    
    methods
        function this = PassiveWorstIndexResponse(optionalInputs)
            arguments
                optionalInputs.Visible = false;
            end
            this.Visible = optionalInputs.Visible;
            this.Tag = "WorstIndexResponse";
        end
    end

    methods (Access = protected)
        function menuLabelText = getMenuLabelText(this)
            menuLabelText = getString(message('Controllib:plots:strWorstIndex'));
        end
    end
end
