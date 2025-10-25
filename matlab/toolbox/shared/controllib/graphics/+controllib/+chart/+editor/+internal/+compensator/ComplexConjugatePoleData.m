classdef ComplexConjugatePoleData < controllib.chart.internal.data.characteristics.BaseCharacteristicData
    % controllib.editor.internal.compensator.ComplexConjugatePoleData

    % Copyright 2024 The MathWorks, Inc.

    %% Properties
    properties (Dependent,SetAccess = private)
        Locations
        Frequencies
        Dampings
        PairIdx
    end

    %% Constructor
    methods
        function this = ComplexConjugatePoleData(data)
            this@controllib.chart.internal.data.characteristics.BaseCharacteristicData(data);
            this.Type = "CompensatorComplexConjugatePoles";
        end
    end

    %% Get/Set
    methods
        % Locations
        function Locations = get.Locations(this)
            Locations = cell(size(this.ResponseData.CompensatorPoles));
            for ii = 1:numel(Locations)
                p = this.ResponseData.CompensatorPoles{ii};
                Locations{ii} = p(p~=real(p)); %assume all complex values have conjugates
            end
        end

        % Frequencies
        function Frequencies = get.Frequencies(this)
            Frequencies = cell(size(this.Locations));
            for ii = 1:numel(this.Locations)
                locations = this.Locations{ii};
                if this.ResponseData.IsDiscrete
                    Ts = abs(this.ResponseData.ModelValue.Ts);
                    locations = log(locations)/Ts;
                end
                Frequencies{ii} = abs(locations);
            end
        end

        % Dampings
        function Dampings = get.Dampings(this)
            Dampings = cell(size(this.Locations));
            for ii = 1:numel(this.Locations)
                locations = this.Locations{ii};
                if this.ResponseData.IsDiscrete
                    Ts = abs(this.ResponseData.ModelValue.Ts);
                    locations = log(locations)/Ts;
                end
                Dampings{ii} = -cos(angle(locations));
            end
        end

        % PairIdx
        function PairIdx = get.PairIdx(this)
            PairIdx = cell(size(this.Locations));
            for ii = 1:numel(this.Locations)
                indices = zeros(size(this.Locations{ii}));
                for jj = 1:length(this.Locations{ii})
                    if indices(jj) ~= 0 % pair already found
                        continue;
                    end
                    % Match with first conjugate after current index
                    idx = find(abs(this.Locations{ii}(jj+1:end)-conj(this.Locations{ii}(jj))) < 100*eps(abs(this.Locations{ii}(jj))),1)+jj;
                    indices(jj) = idx;
                    indices(idx) = jj;
                end
                PairIdx{ii} = indices;
            end
        end
    end

    %% Public methods
    methods (Access=protected)
        function compute_(~)
            % No-op
        end
    end
end
