classdef (Abstract) FrequencyStabilityMarginData < controllib.chart.internal.data.characteristics.BaseCharacteristicData
    % controllib.chart.internal.data.FrequencyStabilityMarginData
    %   - base class for computing a stability margin data of a response
    %   - inherited from controllib.chart.internal.data.characteristics.BaseCharacteristicData
    %
    % h = FrequencyStabilityMarginData(data)
    %   data   controllib.chart.internal.data.response.BaseResponseDataSource
    %
    % Read-only Properties:
    %   ResponseData            response data object, controllib.chart.internal.data.response.BaseResponseDataSource
    %   Type                    type of characteristics, string scalar
    %   IsDirty                 flag if response needs to be computed, logical scalar
    %   MarginType              type of stability margin, all or minimum
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
    %   <a href="matlab:help controllib.chart.internal.data.characteristics.BaseCharacteristicData">controllib.chart.internal.data.characteristics.BaseCharacteristicData</a>
    
    % Copyright 2024 The MathWorks, Inc.

    %% Properties
    properties (SetAccess = protected)
        MarginType
        Stable
        GainMargin
        PhaseMargin
        DelayMargin
        GMFrequency
        PMFrequency
        DMFrequency
        GMPhase
        PMPhase
        FrequencyFocus
    end

    %% Constructor
    methods
        function this = FrequencyStabilityMarginData(data)
            this@controllib.chart.internal.data.characteristics.BaseCharacteristicData(data);
        end        
    end

    %% Protected methods
    methods (Access = protected)
        function compute_(this)
            data = this.ResponseData;
            frequencyConversionFcn = controllib.chart.internal.utils.getFrequencyUnitConversionFcn(this.ResponseData.FrequencyUnit,'rad/s');
            frequencyConversionFcnInv = controllib.chart.internal.utils.getFrequencyUnitConversionFcn('rad/s',this.ResponseData.FrequencyUnit);
            for ka = 1:data.NResponses
                freq = frequencyConversionFcn(data.Frequency{ka});
                focus = frequencyConversionFcn(data.FrequencyFocus{ka}{1,1});
                try
                    % Get data using allmargin (this errors for sparse)
                    s = getAllStabilityMarginData_(data.ModelValue,freq,ka);
                    % Get minimum margins if needed
                    if this.MarginType == "min"
                        s = utGetMinMargins(s);
                    end

                    this.GainMargin{ka} = s.GainMargin;
                    this.GMFrequency{ka} = s.GMFrequency;
                    this.GMPhase{ka} = s.GMPhase;
                    this.PhaseMargin{ka} = s.PhaseMargin;
                    this.PMFrequency{ka} = s.PMFrequency;
                    this.PMPhase{ka} = s.PMPhase;
                    this.DelayMargin{ka} = s.DelayMargin;
                    this.DMFrequency{ka} = s.DMFrequency;
                    this.Stable{ka} = s.Stable;
                catch
                    % Compute margins from response data (IMARGIN, sparse)
                    % If the response data type is resppack.freqdata, (i.e. Nyquist),
                    % then convert to magnitude and phase.  Otherwise use the magnitude
                    % and phase from the response data.
                    computeUsingFrequencyResponseData(this,data,freq,ka);
                end

                % Extend frequency focus by up to two decades to include margin markers
                marginFrequencies = abs([this.GMFrequency{ka}, this.PMFrequency{ka}, this.DMFrequency{ka}]);
                if isempty(focus) || all(isnan(focus))
                    marginFrequencies = marginFrequencies(marginFrequencies>0 & marginFrequencies<Inf);
                    focus = [min(marginFrequencies)/2, 2*max(marginFrequencies)];
                else
                    w = abs(freq); w = sort(w(w>0));
                    marginFrequencies = marginFrequencies(marginFrequencies >= max(w(1),focus(1)/100) & ...
                        marginFrequencies <= min(w(end),focus(2)*100));
                    focus = [min([focus(1),marginFrequencies]), max([focus(2),marginFrequencies])];
                end
                this.FrequencyFocus{ka} = frequencyConversionFcnInv(focus);
            end
        end
    end

    %% Abstract methods
    methods (Abstract,Access = protected)
        computeUsingFrequencyResponseData(this,data,f,arrayIdx)
    end
end
