classdef SectorWorstIndexData < controllib.chart.internal.data.characteristics.SigmaPeakResponseData
    % controllib.chart.internal.data.SectorWorstIndexData
    %   - class for computing peak response of sector plot
    %   - inherited from controllib.chart.internal.data.characteristics.SigmaPeakResponseData
    %
    % h = SectorWorstIndexData(data)
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
    %   <a href="matlab:help controllib.chart.internal.data.characteristics.SigmaPeakResponseData">controllib.chart.internal.data.characteristics.SigmaPeakResponseData</a>
    
    % Copyright 2023-2024 The MathWorks, Inc.
    
    %% Public methods
    methods
        function this = SectorWorstIndexData(data)
            this@controllib.chart.internal.data.characteristics.SigmaPeakResponseData(data);
            this.Type = "SectorWorstIndexResponse";
        end
    end
    
    %% Protected methods
    methods (Access = protected)
        function compute_(this)
            data = this.ResponseData;

            for ka = 1:data.NResponses
                % Get frequency, magnitude and phase from FrequencyData object
                f = data.Frequency{ka};
                relInd = data.RelativeIndex{ka};

                % Compute Peak Response
                peakFrequency = NaN;
                peakRelativeIndex = NaN;

                if ~isempty(relInd)
                    for ct = 1:size(relInd,1)
                        ind_ct = relInd(ct,:);
                        % Get max magnitude value
                        indMax = find(ind_ct==max(ind_ct),1,'last');
                        % Check: indMax is not empty (e.g. Case where m_ct is all NaNs)
                        if ~isempty(indMax)
                            peakFrequency(ct) = f(indMax);
                            peakRelativeIndex(ct) = ind_ct(indMax);
                        end
                    end
                end
                [~,idx] = max(peakRelativeIndex);
                this.Frequency{ka} = peakFrequency(idx);
                this.Value{ka} = peakRelativeIndex(idx);
                this.IdxForPeakValue = idx;
            end
        end
    end
end
