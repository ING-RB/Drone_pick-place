classdef AllStabilityMargins < controllib.chart.internal.characteristics.AbstractCharacteristic        
    
    methods
        function this = AllStabilityMargins(varargin)
            this@controllib.chart.internal.characteristics.AbstractCharacteristic(varargin{:});
        end
    end

    methods (Access = protected)
        function menuLabelText = getMenuLabelText(this)
            menuLabelText = getString(message('Controllib:plots:strAllStabilityMargins'));
        end

        function tag = getDefaultTag(this)
            tag = "AllStabilityMargins";
        end
    end
end
