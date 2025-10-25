classdef GainData < controllib.chart.internal.data.characteristics.BaseCharacteristicData
    % controllib.editor.internal.compensator.ZeroData

    % Copyright 2024 The MathWorks, Inc.

    %% Properties
    properties (Dependent,SetAccess = private)
        Value
    end

    %% Constructor
    methods
        function this = GainData(data)
            this@controllib.chart.internal.data.characteristics.BaseCharacteristicData(data);
            this.Type = "CompensatorGain";
        end
    end

    %% Get/Set
    methods
        % Value
        function Value = get.Value(this)
            Value = this.ResponseData.CompensatorGain;
        end
    end

    %% Public methods
    methods (Access=protected)
        function compute_(~)
            % No-op
        end
    end
end
