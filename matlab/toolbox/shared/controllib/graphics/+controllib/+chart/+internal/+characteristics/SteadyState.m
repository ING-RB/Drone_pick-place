classdef SteadyState < controllib.chart.internal.characteristics.AbstractCharacteristic

    methods
        function this = SteadyState(varargin)
            this@controllib.chart.internal.characteristics.AbstractCharacteristic(varargin{:});
        end
    end

    methods (Access = protected)
        function menuLabelText = getMenuLabelText(this)
            menuLabelText = getString(message('Controllib:plots:strSteadyState'));
        end

        function tag = getDefaultTag(this)
            tag = "SteadyState";
        end
    end
end
