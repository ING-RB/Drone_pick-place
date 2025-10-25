classdef TimeOutputCharacteristicView < controllib.chart.internal.view.characteristic.OutputCharacteristicView & ...
        controllib.chart.internal.foundation.MixInTimeUnit

    methods
        function this = TimeOutputCharacteristicView(response,data)
            this@controllib.chart.internal.view.characteristic.OutputCharacteristicView(response,data);
            this@controllib.chart.internal.foundation.MixInTimeUnit(response.TimeUnit);
        end
    end
end