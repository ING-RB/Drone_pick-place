classdef FrequencyPeakResponseData < controllib.chart.internal.data.characteristics.BaseCharacteristicData
    % controllib.chart.internal.data.FrequencyPeakResponseData
    %   - class for computing peak response of frequency plots
    %   - inherited from controllib.chart.internal.data.characteristics.BaseCharacteristicData
    %
    % h = FrequencyPeakResponseData(data)
    %   data   controllib.chart.internal.data.response.BaseResponseDataSource
    %
    % Read-only Properties:
    %   ResponseData            response data object, controllib.chart.internal.data.response.BaseResponseDataSource
    %   Type                    type of characteristics, string scalar
    %   IsDirty                 flag if response needs to be computed, logical scalar
    %   Magnitude               peak magnitude
    %   Phase                   peak phase
    %   Frequency               peak frequency
    %   RealValue               peak real response
    %   ImaginaryValue          peak imaginary response
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
    properties (SetAccess=protected)
        Magnitude
        Phase
        Frequency
    end

    properties (Dependent,SetAccess=private)
        RealValue
        ImaginaryValue
    end

    %% Constructor
    methods
        function this = FrequencyPeakResponseData(data)
            this@controllib.chart.internal.data.characteristics.BaseCharacteristicData(data);
            this.Type = "FrequencyPeakResponse";
        end
    end

    %% Get/Set
    methods
        function RealValue = get.RealValue(this)
            if isempty(this.Magnitude)
                RealValue = this.Magnitude;
                return;
            end
            RealValue = cell(1,length(this.Magnitude));
            for k = 1:length(this.Magnitude)
                RealValue{k} = real(this.Magnitude{k}.*exp(1i*this.Phase{k}));
            end
        end

        function ImaginaryValue = get.ImaginaryValue(this)
            if isempty(this.Magnitude)
                ImaginaryValue = this.Magnitude;
                return;
            end
            ImaginaryValue = cell(1,length(this.Magnitude));
            for k = 1:length(this.Magnitude)
                ImaginaryValue{k} = imag(this.Magnitude{k}.*exp(1i*this.Phase{k}));
            end
        end
    end

    %% Protected methods
    methods (Access = protected)
        function compute_(this)
            data = this.ResponseData;
            
            nrows = data.NOutputs;
            ncols = data.NInputs;

            for ka = 1:data.NResponses
                % Get frequency, magnitude and phase from FrequencyData object
                f = data.Frequency{ka};
                m = data.Magnitude{ka};
                ph = data.Phase{ka};

                % Compute Peak Response
                peakFrequency = NaN(nrows, ncols);
                peakGain = NaN(nrows, ncols);
                peakPhase = NaN(nrows,ncols);

                if ~isempty(m)
                    for ct=1:nrows*ncols
                        m_ct = m(:,ct);
                        % Get max magnitude value
                        indMax = find(m_ct==max(m_ct),1,'last');
                        % Check: indMax is not empty (e.g. Case where m_ct is all NaNs)
                        if ~isempty(indMax)
                            peakFrequency(ct) = f(indMax);
                            peakGain(ct) = m_ct(indMax);
                            if ~isempty(ph)
                                peakPhase(ct) = ph(indMax,ct);
                            end
                        end
                    end
                end
                this.Frequency{ka} = peakFrequency;
                this.Magnitude{ka} = peakGain;
                this.Phase{ka} = peakPhase;
            end
        end
    end
end
