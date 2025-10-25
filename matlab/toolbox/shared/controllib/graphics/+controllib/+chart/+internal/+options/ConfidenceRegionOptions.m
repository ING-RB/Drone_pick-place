classdef ConfidenceRegionOptions < controllib.chart.internal.options.BaseCharacteristicOptions

    properties (SetObservable, AbortSet)
        NumberOfStandardDeviations
    end

    methods
        function this = ConfidenceRegionOptions(baseOptionalInputs,optionalInputs)
            arguments
                baseOptionalInputs.?controllib.chart.internal.options.BaseCharacteristicOptionsOptionalInputs
                optionalInputs.NumberOfStandardDeviations = 1;
            end
            baseOptionalInputs = namedargs2cell(baseOptionalInputs);
            this@controllib.chart.internal.options.BaseCharacteristicOptions(baseOptionalInputs{:});
            this.NumberOfStandardDeviations = optionalInputs.NumberOfStandardDeviations;
        end
    end
end