classdef DiskMarginMinimumResponseData < controllib.chart.internal.data.characteristics.BaseCharacteristicData
    % controllib.chart.internal.data.DiskMarginMinimumResponseData
    %   - class for computing minimum response of disk margin plot
    %   - inherited from controllib.chart.internal.data.characteristics.BaseCharacteristicData
    %
    % h = DiskMarginMinimumResponseData(data)
    %   data   controllib.chart.internal.data.response.BaseResponseDataSource
    %
    % Read-only Properties:
    %   ResponseData            response data object, controllib.chart.internal.data.response.BaseResponseDataSource
    %   Type                    type of characteristics, string scalar
    %   IsDirty                 flag if response needs to be computed, logical scalar
    %   GainMargin              gain at min frequency
    %   PhaseMargin             phase at min frequency
    %   DiskMargin              min value
    %   Frequency               min frequency
    %
    % Events:
    %   DataChanged             notified in update()
    %
    % Public methods:
    %   update(this)
    %       Update the the characteristic data using ResponseData. Marks IsDirty as true.
    %   compute(this)
    %       Computes the characteristic data with stored Data. Marks IsDirty as false.
    %
    % Protected methods (override in subclass):
    %   compute_(this)
    %       Compute the characteristic data. Called in compute(). Implement in subclass.
    %   postUpdate(this)
    %       Called after updating the data. Implement in subclass if needed.
    %
    % See Also:
    %   <a href="matlab:help controllib.chart.internal.data.characteristics.BaseCharacteristicData">controllib.chart.internal.data.characteristics.BaseCharacteristicData</a>
    
    % Copyright 2023-2024 The MathWorks, Inc.

    properties (SetAccess=protected)
        GainMargin
        PhaseMargin
        DiskMargin
        Frequency
    end

    methods
        function this = DiskMarginMinimumResponseData(data)
            this@controllib.chart.internal.data.characteristics.BaseCharacteristicData(data);
            this.Type = "DiskMarginMinimumResponse";
        end
    end

    methods (Access = protected)
        function compute_(this)
            data = this.ResponseData;
            nArray = prod(data.ArrayDim);
            for ka = 1:nArray
                % Get frequency, magnitude and phase from FrequencyData object
                f = data.Frequency{ka};
                gm = data.GainMargin{ka};
                pm = data.PhaseMargin{ka};
                dm = data.DiskMargin{ka};

                % Compute Minimum Response
                minFrequency = NaN;
                minGainMargin = NaN;
                minPhaseMargin = NaN;
                minDiskMargin = NaN;

                if ~isempty(dm)
                    % Get max magnitude value
                    indMax = find(dm==min(dm),1,'last');
                    % Check: indMax is not empty (e.g. Case where dm_ct is all NaNs)
                    if ~isempty(indMax)
                        minFrequency = f(indMax);
                        minDiskMargin = dm(indMax);
                        minGainMargin = gm(indMax);
                        minPhaseMargin = pm(indMax);
                    end
                end
                this.Frequency{ka} = minFrequency;
                this.GainMargin{ka} = minGainMargin;
                this.PhaseMargin{ka} = minPhaseMargin;
                this.DiskMargin{ka} = minDiskMargin;
            end
        end
    end
end
