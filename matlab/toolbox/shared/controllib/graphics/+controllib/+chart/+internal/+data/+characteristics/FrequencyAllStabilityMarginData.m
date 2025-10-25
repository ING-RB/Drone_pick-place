classdef FrequencyAllStabilityMarginData < controllib.chart.internal.data.characteristics.FrequencyStabilityMarginData
    % controllib.chart.internal.data.FrequencyAllStabilityMarginData
    %   - class for computing all stability margin data of a response
    %   - inherited from controllib.chart.internal.data.characteristics.FrequencyStabilityMarginData
    %
    % h = FrequencyAllStabilityMarginData(data)
    %   data   controllib.chart.internal.data.response.BaseResponseDataSource
    %
    % Read-only Properties:
    %   ResponseData            response data object, controllib.chart.internal.data.response.BaseResponseDataSource
    %   Type                    type of characteristics, string scalar
    %   IsDirty                 flag if response needs to be computed, logical scalar
    %   MarginType              type of stability margin, "all"
    %   Stable                  stability of system
    %   GainMargin              gain margin value
    %   PhaseMargin             phase margin value
    %   DelayMargin             delay margin value
    %   GMFrequency             gain margin frequency
    %   PMFrequency             phase margin frequency
    %   DMFrequency             delay margin frequency
    %   GMPhase                 gain margin phase
    %   PMPhase                 phase margin phase
    %   FrequencyFocus          frequency focus of margins
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
    %   postUpdate(this)
    %       Called after updating the data. Implement in subclass if needed.
    %
    % Abstract methods
    %   compute_(this)
    %       Compute the characteristic data. Called in compute(). Implement in subclass.
    %
    % See Also:
    %   <a href="matlab:help controllib.chart.internal.data.characteristics.FrequencyStabilityMarginData">controllib.chart.internal.data.characteristics.FrequencyStabilityMarginData</a>
    
    % Copyright 2024 The MathWorks, Inc.

    %% Constructor
    methods
        function this = FrequencyAllStabilityMarginData(data)
            this@controllib.chart.internal.data.characteristics.FrequencyStabilityMarginData(data);
            this.Type = "AllStabilityMargins";
            this.MarginType = "all";
        end
    end

    %% Protected methods
    methods (Access = protected)
        function computeUsingFrequencyResponseData(this,data,freq,arrayIdx)
            % Compute margins from response data (IMARGIN, sparse)
            % If the response data type is resppack.freqdata, (i.e. Nyquist),
            % then convert to magnitude and phase.  Otherwise use the magnitude
            % and phase from the response data.
            % Use magnitude as is, in abs
            magnitude = data.Magnitude{arrayIdx};
            % Convert phase from radians to degrees
            phase = rad2deg(data.Phase{arrayIdx});
            
            % Compute gain and phase margins
            s = allmargin(magnitude,phase,freq,data.ModelValue.Ts,0);
            this.GainMargin{arrayIdx} = s.GainMargin;
            this.GMFrequency{arrayIdx} = s.GMFrequency;
            this.GMPhase{arrayIdx} = 180*round(utInterp1(freq,phase,s.GMFrequency)/180);
            this.PhaseMargin{arrayIdx} = s.PhaseMargin;
            this.PMFrequency{arrayIdx} = s.PMFrequency;
            this.PMPhase{arrayIdx} = utInterp1(freq,phase,s.PMFrequency);
            this.DelayMargin{arrayIdx} = s.DelayMargin;
            this.DMFrequency{arrayIdx} = s.DMFrequency;
            this.Stable{arrayIdx} = NaN;
        end
    end
end
