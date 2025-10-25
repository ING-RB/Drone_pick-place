classdef PeakResponse < controllib.chart.internal.characteristics.AbstractCharacteristic        

    methods
        function this = PeakResponse(varargin)
            this@controllib.chart.internal.characteristics.AbstractCharacteristic(varargin{:});
        end
    end

    methods (Access = protected)
        function menuLabelText = getMenuLabelText(this) %#ok<*MANU>
            menuLabelText = getString(message('Controllib:plots:strPeakResponse'));
        end

        function tag = getDefaultTag(this)
            tag = "PeakResponse";
        end
    end
end
