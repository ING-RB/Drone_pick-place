classdef FrequencyCharacteristicView < controllib.chart.internal.view.characteristic.InputOutputCharacteristicView & ...
        controllib.chart.internal.foundation.MixInFrequencyUnit

    methods
        function this = FrequencyCharacteristicView(response,data)
            this@controllib.chart.internal.view.characteristic.InputOutputCharacteristicView(response,data);
            this@controllib.chart.internal.foundation.MixInFrequencyUnit(response.FrequencyUnit);
        end
    end
end