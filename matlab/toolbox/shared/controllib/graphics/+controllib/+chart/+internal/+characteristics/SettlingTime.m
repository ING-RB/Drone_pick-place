classdef SettlingTime < controllib.chart.internal.characteristics.AbstractCharacteristic

    properties (SetObservable, AbortSet)
        Threshold
    end

    methods
        function this = SettlingTime(varargin,optionalInputs)
            arguments(Repeating)
                varargin
            end

            arguments
                optionalInputs.Threshold = get(cstprefs.tbxprefs,'SettlingTimeThreshold');
            end
            
            this@controllib.chart.internal.characteristics.AbstractCharacteristic(varargin{:});
            this.Threshold = optionalInputs.Threshold;
        end
    end

    methods (Access = protected)
        function menuLabelText = getMenuLabelText(this)
            menuLabelText = getString(message('Controllib:plots:strSettlingTime'));
        end

        function tag = getDefaultTag(this)
            tag = "SettlingTime";
        end
    end
end