classdef MinimumStabilityMargins < controllib.chart.internal.characteristics.AbstractCharacteristic        
    
    methods
        function this = MinimumStabilityMargins(varargin)
            this@controllib.chart.internal.characteristics.AbstractCharacteristic(varargin{:});
        end
    end

    methods (Access = protected)
        function menuLabelText = getMenuLabelText(this)
            menuLabelText = getString(message('Controllib:plots:strMinimumStabilityMargins'));
        end

        function tag = getDefaultTag(this)
            tag = "MinimumStabilityMargins";
        end
    end
end
