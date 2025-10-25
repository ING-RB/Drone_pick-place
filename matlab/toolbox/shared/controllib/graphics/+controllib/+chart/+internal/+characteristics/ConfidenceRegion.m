classdef ConfidenceRegion < controllib.chart.internal.characteristics.AbstractCharacteristic

    properties (SetObservable, AbortSet)
        NumberOfStandardDeviations
    end

    methods
        function this = ConfidenceRegion(varargin,optionalInputs)
            arguments(Repeating)
                varargin
            end

            arguments
                optionalInputs.NumberOfStandardDeviations = 1
            end
            
            this@controllib.chart.internal.characteristics.AbstractCharacteristic(varargin{:});
            this.NumberOfStandardDeviations = optionalInputs.NumberOfStandardDeviations;
        end
    end

    methods (Access = protected)
        function menuLabelText = getMenuLabelText(this)
            menuLabelText = getString(message('Controllib:plots:strConfidenceRegion'));
        end

        function tag = getDefaultTag(this)
            tag = "ConfidenceRegion";
        end
    end
end