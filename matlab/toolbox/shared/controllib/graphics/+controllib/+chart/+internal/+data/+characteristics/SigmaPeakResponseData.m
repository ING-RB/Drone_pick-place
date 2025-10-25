classdef SigmaPeakResponseData < controllib.chart.internal.data.characteristics.BaseCharacteristicData
    % controllib.chart.internal.data.SigmaPeakResponseData
    %   - class for computing peak response of singular value plot
    %   - inherited from controllib.chart.internal.data.characteristics.BaseCharacteristicData
    %
    % h = SigmaPeakResponseData(data)
    %   data   controllib.chart.internal.data.response.BaseResponseDataSource
    %
    % Read-only Properties:
    %   ResponseData            response data object, controllib.chart.internal.data.response.BaseResponseDataSource
    %   Type                    type of characteristics, string scalar
    %   IsDirty                 flag if response needs to be computed, logical scalar
    %   IdxForPeakValue         line index for peak value
    %   Value                   peak value
    %   Frequency               peak frequency
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
    
    % Copyright 2022-2024 The MathWorks, Inc.

    %% Properties
    properties (SetAccess = protected)
        IdxForPeakValue
        Value
        Frequency
    end
    
    %% Public methods
    methods
        function this = SigmaPeakResponseData(data)
            this@controllib.chart.internal.data.characteristics.BaseCharacteristicData(data);
            this.Type = "SigmaPeakResponse";
        end
    end
    
    %% Protected methods
    methods (Access = protected)
        function compute_(this)
            data = this.ResponseData;

            for ka = 1:data.NResponses
                % Get frequency, magnitude and phase from FrequencyData object
                f = data.Frequency{ka};
                sv = data.SingularValue{ka};

                % Compute Peak Response
                peakFrequency = NaN;
                peakSingularValue = NaN;

                if ~isempty(sv)
                    for ct = 1:size(sv,1)
                        sv_ct = sv(ct,:);
                        % Get max magnitude value
                        indMax = find(sv_ct==max(sv_ct),1,'last');
                        % Check: indMax is not empty (e.g. Case where m_ct is all NaNs)
                        if ~isempty(indMax)
                            peakFrequency(ct) = f(indMax);
                            peakSingularValue(ct) = sv_ct(indMax);
                        end
                    end
                end
                [~,idx] = max(peakSingularValue);
                this.Frequency{ka} = peakFrequency(idx);
                this.Value{ka} = peakSingularValue(idx);
                this.IdxForPeakValue = idx;
            end
        end
    end
end
