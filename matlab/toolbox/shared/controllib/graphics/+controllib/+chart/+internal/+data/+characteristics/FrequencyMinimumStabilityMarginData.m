classdef FrequencyMinimumStabilityMarginData < controllib.chart.internal.data.characteristics.FrequencyStabilityMarginData
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
    %   MarginType              type of stability margin, "min"
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

    methods
        function this = FrequencyMinimumStabilityMarginData(data)
            this@controllib.chart.internal.data.characteristics.FrequencyStabilityMarginData(data);
            this.Type = "MinimumStabilityMargins";
            this.MarginType = "min";
        end
    end

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

            % Compute gain and phase margins for k-th model
            if isempty(magnitude)
                Gm = Inf;  Pm = 180;  Wcg = NaN;  Wcp = NaN;
            else
                [Gm,Pm,Wcg,Wcp] = imargin(magnitude,phase,freq);
            end

            % Compute gain and phase margins
            Dm = utComputeDelayMargins(Pm*(pi/180),Wcp,data.ModelValue.Ts,0);
            [Gm,Pm,Wcg,Wcp,Dm] = utMarginPlotData(Gm,Pm,Wcg,Wcp,Dm);
            this.GainMargin{arrayIdx}  = Gm;
            this.GMFrequency{arrayIdx} = Wcg;
            this.GMPhase{arrayIdx} = 180 * round(utInterp1(freq,phase,Wcg)/180);
            this.PhaseMargin{arrayIdx} = Pm;
            this.PMFrequency{arrayIdx} = Wcp;
            this.PMPhase{arrayIdx} = utInterp1(freq,phase,Wcp);
            this.DMFrequency{arrayIdx} = Wcp;
            this.DelayMargin{arrayIdx} = Dm;
            this.Stable{arrayIdx} = NaN;
        end
    end
end
