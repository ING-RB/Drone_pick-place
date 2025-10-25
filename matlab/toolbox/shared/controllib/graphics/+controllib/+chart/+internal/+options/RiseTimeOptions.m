classdef RiseTimeOptions < controllib.chart.internal.options.BaseCharacteristicOptions

    properties (SetObservable, AbortSet)
        Limits
    end

    methods
        function this = RiseTimeOptions(baseOptionalInputs,optionalInputs)
             arguments
                baseOptionalInputs.?controllib.chart.internal.options.BaseCharacteristicOptionsOptionalInputs
                optionalInputs.Limits = get(cstprefs.tbxprefs,'RiseTimeLimits');
            end
            baseOptionalInputs = namedargs2cell(baseOptionalInputs);
            this@controllib.chart.internal.options.BaseCharacteristicOptions(baseOptionalInputs{:});
            this.Limits = optionalInputs.Limits;
        end
    end
end