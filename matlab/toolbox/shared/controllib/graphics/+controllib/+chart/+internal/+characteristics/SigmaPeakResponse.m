classdef SigmaPeakResponse < controllib.chart.internal.characteristics.AbstractCharacteristic        
    
    methods
        function this = SigmaPeakResponse(optionalInputs)
            arguments
                optionalInputs.Visible = false;
            end
            this.Visible = optionalInputs.Visible;
            this.Tag = "PeakResponse";
        end
    end

    methods (Access = protected)
        function menuLabelText = getMenuLabelText(this)
            menuLabelText = getString(message('Controllib:plots:strPeakResponse'));
        end
    end
end
