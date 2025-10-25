classdef TimeInputOutputCharacteristicView < controllib.chart.internal.view.characteristic.InputOutputCharacteristicView & ...
        controllib.chart.internal.foundation.MixInTimeUnit

    methods
        function this = TimeInputOutputCharacteristicView(response,data)
            this@controllib.chart.internal.view.characteristic.InputOutputCharacteristicView(response,data);
            this@controllib.chart.internal.foundation.MixInTimeUnit(response.TimeUnit);
        end
    end
end