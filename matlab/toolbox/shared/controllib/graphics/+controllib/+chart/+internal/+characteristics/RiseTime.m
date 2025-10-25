classdef RiseTime< controllib.chart.internal.characteristics.AbstractCharacteristic

    properties (SetObservable, AbortSet)
        Limits
    end

    methods
        function this = RiseTime(varargin,optionalInputs)
            arguments(Repeating)
                varargin
            end

            arguments
                optionalInputs.Limits = get(cstprefs.tbxprefs,'RiseTimeLimits');
            end
            
            this@controllib.chart.internal.characteristics.AbstractCharacteristic(varargin{:});
            this.Limits = optionalInputs.Limits;
        end
    end

    methods (Access = protected)
        function menuLabelText = getMenuLabelText(this)
            menuLabelText = getString(message('Controllib:plots:strRiseTime'));
        end

        function tag = getDefaultTag(this)
            tag = "RiseTime";
        end
    end
end