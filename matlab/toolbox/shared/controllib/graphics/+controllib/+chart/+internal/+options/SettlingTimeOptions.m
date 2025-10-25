classdef SettlingTimeOptions < controllib.chart.internal.options.BaseCharacteristicOptions

    properties (SetObservable, AbortSet)
        Threshold
    end

    methods
        function this = SettlingTimeOptions(baseOptionalInputs,optionalInputs)
            arguments
                baseOptionalInputs.?controllib.chart.internal.options.BaseCharacteristicOptionsOptionalInputs
                optionalInputs.Threshold = get(cstprefs.tbxprefs,'SettlingTimeThreshold');
            end
            baseOptionalInputs = namedargs2cell(baseOptionalInputs);
            this@controllib.chart.internal.options.BaseCharacteristicOptions(baseOptionalInputs{:});
            this.Threshold = optionalInputs.Threshold;
        end
    end
end