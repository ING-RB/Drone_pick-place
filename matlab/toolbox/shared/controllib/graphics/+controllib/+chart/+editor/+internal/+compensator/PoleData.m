classdef PoleData < controllib.chart.internal.data.characteristics.BaseCharacteristicData
    % controllib.editor.internal.compensator.PoleData

    % Copyright 2024 The MathWorks, Inc.

    %% Properties
    properties (Dependent,SetAccess = private)
        Locations
        Frequencies
        Dampings
    end

    %% Constructor
    methods
        function this = PoleData(data)
            this@controllib.chart.internal.data.characteristics.BaseCharacteristicData(data);
            this.Type = "CompensatorPoles";
        end
    end

    %% Get/Set
    methods
        % Locations
        function Locations = get.Locations(this)
            Locations = cell(size(this.ResponseData.CompensatorPoles));
            for ii = 1:numel(Locations)
                p = this.ResponseData.CompensatorPoles{ii};
                Locations{ii} = p(p==real(p));
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
    end

    %% Public methods
    methods (Access=protected)
        function compute_(~)
            % No-op
        end
    end
end
