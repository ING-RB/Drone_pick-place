classdef DiskMarginResponseDataSource < controllib.chart.internal.data.response.FrequencyResponseDataSource
    % controllib.chart.internal.data.response.DiskMarginResponseDataSource
    %   - manage source and data objects for given disk margin response
    %   - inherited from controllib.chart.internal.data.response.FrequencyResponseDataSource
    %
    % h = DiskMarginResponseDataSource(model)
    %
    % h = DiskMarginResponseDataSource(_____,Name-Value)
    %   Frequency             frequency specification used to generate data, [] (default) auto generates frequency specification
    %   Skew                  skew of uncertainty region used to compute the stability margins, 0 (default)
    %
    % Read-only properties:
    %   Type                        type of response for subclass, string
    %   ArrayDim                    array dimensions of response data, double
    %   NResponses                  number of elements of response data, double
    %   CharacteristicTypes         types of Characteristics, string
    %   Characteristics             characteristics of response data, controllib.chart.internal.data.characteristics.BaseCharacteristicData
    %   NInputs                     number of inputs in Model, double
    %   NOutputs                    number of outputs in Model, double
    %   IsDiscrete                  logical value to specify if Model is discrete
    %   IsReal                      logical array to specify if Model is real
    %   FrequencyInput              frequency specification used to generate data, double or cell
    %   Frequency                   frequency data of response, cell
    %   FrequencyFocus              frequency focus of response, cell
    %   FrequencyUnit               frequency unit of Model, char
    %   GainMargin                  gain margin data of response, cell
    %   PhaseMargin                 phase margin data of response, cell
    %   DiskMargin                  disk margin data of response, cell
    %   Skew                        skew of uncertainty region, double
    %   IsStable                    a priori knowledge of stability, logical
    %   DiskMarginMinimumResponse   minimum response characteristic, controllib.chart.internal.data.characteristics.DiskMarginMinimumResponseData
    %
    % Read-only / Internal properties:
    %   Model                 Dynamic system of response
    %
    % Events:
    %   DataChanged           notified after update is called
    %
    % Public methods:
    %   update(this)
    %       Update the response data with new parameter values.
    %   getCharacteristics(this,characteristicType)
    %       Get characteristics corresponding to types.
    %
    % Public methods (sealed):
    %   getCommonFrequencyFocus(this,frequencyScale,arrayVisible)
    %       Get frequency focus values for an array of response data.
    %   getCommonGainFocus(this,commonFrequencyFocus,gainScale,arrayVisible)
    %       Get magnitude focus values for an array of response data.
    %   getCommonPhaseFocus(this,commonFrequencyFocus,arrayVisible)
    %       Get phase focus values for an array of response data.
    %
    % Protected methods (sealed):
    %   createCharacteristics(this)
    %       Create characteristics based on response data.
    %   updateCharacteristicsData(this,characteristicType)
    %       Update the characteristic data. Call in update().
    %
    % Protected methods (to override in subclass):
    %   createCharacteristics_(this)
    %       Create the characteristic data. Called in createCharacteristics().
    %   updateData(this,Name-Value)
    %       Update the response data. Called in update().
    %   computeGainFocus(this,frequencyFocuses,magnitudeScale)
    %       Compute the gain focus. Called in getCommonGainFocus().
    %   computePhaseFocus(this,frequencyFocuses)
    %       Compute the phase focus. Called in getCommonPhaseFocus().
    %
    % See Also:
    %   <a href="matlab:help controllib.chart.internal.data.response.FrequencyResponseDataSource">controllib.chart.internal.data.response.FrequencyResponseDataSource</a>

    % Copyright 2023-2024 The MathWorks, Inc.

    %% Properties
    properties (SetAccess = protected)
        % "GainMargin": cell vector
        % Gain margin data of response.
        GainMargin
        % "PhaseMargin": cell vector
        % Phase margin data of response.
        PhaseMargin
        % "DiskMargin": cell vector
        % Disk margin data of response.
        DiskMargin
        % "Skew": double scalar
        % Skew of uncertainty region.
        Skew
        % "IsStable": logical array
        % Use a priori knowledge of stability to speed up computation.
        IsStable = []
    end

    properties (Dependent,SetAccess=private)
        % "DiskMarginMinimumResponse": controllib.chart.internal.data.characteristics.DiskMarginMinimumResponseData scalar
        % Minimum response characteristic.
        DiskMarginMinimumResponse
    end

    %% Public methods
    methods
        function this = DiskMarginResponseDataSource(model,diskMarginResponseOptionalInputs,frequencyResponseOptionalInputs)
            arguments
                model
                diskMarginResponseOptionalInputs.Skew = 0;
                frequencyResponseOptionalInputs.Frequency = []
            end
            frequencyResponseOptionalInputs = namedargs2cell(frequencyResponseOptionalInputs);
            this@controllib.chart.internal.data.response.FrequencyResponseDataSource(model,frequencyResponseOptionalInputs{:});
            this.Type = "DiskMarginResponse";
            this.Skew = diskMarginResponseOptionalInputs.Skew;

            % Update response
            update(this);
        end
    end

    %% Get/Set methods
    methods
        % DiskMarginMinimumResponse
        function DiskMarginMinimumResponse = get.DiskMarginMinimumResponse(this)
            arguments
                this (1,1) controllib.chart.internal.data.response.DiskMarginResponseDataSource
            end
            DiskMarginMinimumResponse = getCharacteristics(this,"DiskMarginMinimumResponse");
        end
    end

    %% Sealed methods
    methods (Sealed)
        function [commonFrequencyFocus,frequencyUnit] = getCommonFrequencyFocus(this,frequencyScale,arrayVisible)
            arguments
                this (:,1) controllib.chart.internal.data.response.DiskMarginResponseDataSource
                frequencyScale (1,1) string {mustBeMember(frequencyScale,["linear","log"])}
                arrayVisible (:,1) cell = arrayfun(@(x) {true(x.NResponses,1)},this)
            end
            commonFrequencyFocus = {[NaN,NaN]};
            frequencyUnit = this(1).FrequencyUnit;
            for k = 1:length(this) % loop for number of data objects
                for ka = 1:this(k).NResponses % loop for system array
                    % Frequency Focus
                    if arrayVisible{k}(ka)
                        cf = funitconv(this(k).FrequencyUnit,frequencyUnit);
                        frequencyFocus = cf*this(k).FrequencyFocus{ka};
                        commonFrequencyFocus{1}(1) = ...
                            min(commonFrequencyFocus{1}(1),frequencyFocus(1));
                        commonFrequencyFocus{1}(2) = ...
                            max(commonFrequencyFocus{1}(2),frequencyFocus(2));
                    end
                end
            end
            if frequencyScale=="linear" && any(arrayfun(@(x) ~all(x.IsReal),this))
                commonFrequencyFocus{1}(1) = -commonFrequencyFocus{1}(2); %mirror focus
            end
        end

        function [commonGainFocus,gainUnit] = getCommonGainFocus(this,commonFrequencyFocus,gainScale,arrayVisible)
            arguments
                this (:,1) controllib.chart.internal.data.response.DiskMarginResponseDataSource
                commonFrequencyFocus (1,1) cell
                gainScale (1,1) string {mustBeMember(gainScale,["linear","log"])}
                arrayVisible (:,1) cell = arrayfun(@(x) {true(x.NResponses,1)},this)
            end
            commonGainFocus = {[NaN,NaN]};
            gainUnit = 'abs';
            for k = 1:length(this) % loop for number of data objects
                gainFocuses = computeGainFocus(this(k),commonFrequencyFocus,gainScale);
                for ka = 1:this(k).NResponses % loop for system array
                    % Gain Focus
                    if arrayVisible{k}(ka)
                        gainFocus = gainFocuses{ka};
                        commonGainFocus{1}(1) = ...
                            min(commonGainFocus{1}(1),gainFocus(1));
                        commonGainFocus{1}(2) = ...
                            max(commonGainFocus{1}(2),gainFocus(2));
                    end
                end
            end
        end

        function [commonPhaseFocus,phaseUnit] = getCommonPhaseFocus(this,commonFrequencyFocus,arrayVisible)
            arguments
                this (:,1) controllib.chart.internal.data.response.DiskMarginResponseDataSource
                commonFrequencyFocus (1,1) cell
                arrayVisible (:,1) cell = arrayfun(@(x) {true(x.NResponses,1)},this)
            end
            commonPhaseFocus = {[NaN,NaN]};
            phaseUnit = 'deg';
            for k = 1:length(this) % loop for number of data objects
                phaseFocuses = computePhaseFocus(this(k),commonFrequencyFocus);
                for ka = 1:this(k).NResponses % loop for system array
                    % Phase Focus
                    if arrayVisible{k}(ka)
                        phaseFocus = phaseFocuses{ka};
                        commonPhaseFocus{1}(1) = ...
                            min(commonPhaseFocus{1}(1),phaseFocus(1));
                        commonPhaseFocus{1}(2) = ...
                            max(commonPhaseFocus{1}(2),phaseFocus(2));
                    end
                end
            end
        end
    end

    %% Protected methods
    methods (Access = protected)
        function updateData(this,diskMarginResponseOptionalInputs,frequencyResponseOptionalInputs)
            arguments
                this (1,1) controllib.chart.internal.data.response.DiskMarginResponseDataSource
                diskMarginResponseOptionalInputs.Skew = this.Skew
                diskMarginResponseOptionalInputs.IsStable = this.IsStable
                frequencyResponseOptionalInputs.Frequency = this.FrequencyInput
                frequencyResponseOptionalInputs.Model = this.Model
            end
            try
                sysList.System = frequencyResponseOptionalInputs.Model;
                ParamList = {frequencyResponseOptionalInputs.Frequency};
                [sysList,w] = DynamicSystem.checkDiskMarginInputs(sysList,ParamList);
                frequencyResponseOptionalInputs.Model = sysList.System;
                frequencyResponseOptionalInputs.Frequency = w;
                if isempty(sysList.System)
                    error(message('Controllib:plots:PlotEmptyModel'))
                end
            catch ME
                this.DataException = ME;
            end
            frequencyResponseOptionalInputs = namedargs2cell(frequencyResponseOptionalInputs);
            updateData@controllib.chart.internal.data.response.FrequencyResponseDataSource(this,frequencyResponseOptionalInputs{:});
            this.Skew = diskMarginResponseOptionalInputs.Skew;
            this.IsStable = diskMarginResponseOptionalInputs.IsStable;
            this.DiskMargin = repmat({NaN},this.NResponses,1);
            this.GainMargin = repmat({NaN},this.NResponses,1);
            this.PhaseMargin = repmat({NaN},this.NResponses,1);
            this.Frequency = repmat({NaN},this.NResponses,1);
            this.FrequencyFocus = repmat({[NaN NaN]},this.NResponses,1);
            if ~isempty(this.DataException)
                return;
            end
            try
                for ka = 1:this.NResponses
                    % Compute disk margin as a function of frequency
                    % NOTE: this call requires Robust Control Toolbox
                    [alpha,w,focus] = getDiskMarginData_(this.ModelValue,this.Skew,this.FrequencyInput,this.IsStable,ka);
                    % Compute gain and phase margin data to plot
                    [gainMargin,phaseMargin,alpha] = dm2gmPlot(alpha,this.Skew);
                    this.DiskMargin{ka} = alpha;
                    this.GainMargin{ka} = gainMargin;
                    if all(gainMargin(:)==0)
                        this.PhaseMargin{ka} = NaN(size(phaseMargin));
                    else
                        this.PhaseMargin{ka} = phaseMargin;
                    end
                    this.Frequency{ka} = w;

                    % Round focus if frequency grid is automatically computed
                    roundedFocus = focus.Focus;
                    if isempty(this.FrequencyInput)
                        roundedFocus(1) = 10^floor(log10(roundedFocus(1)));
                        roundedFocus(2) = 10^ceil(log10(roundedFocus(2)));
                    end

                    % Remove NaNs from focus
                    if any(isnan(roundedFocus))
                        % Check if focus contains NaN
                        roundedFocus = [1 10];
                    elseif roundedFocus(1) >= roundedFocus(2)
                        % Check if focus is not monotonically increasing
                        roundedFocus(1) = roundedFocus(1) - 0.1*abs(roundedFocus(1));
                        roundedFocus(2) = roundedFocus(2) + 0.1*abs(roundedFocus(2));
                    end
                    this.FrequencyFocus{ka} = roundedFocus;
                end
            catch ME
                this.DataException = ME;
            end
        end

        function characteristics = createCharacteristics_(this)
            arguments
                this (1,1) controllib.chart.internal.data.response.DiskMarginResponseDataSource
            end
            characteristics = controllib.chart.internal.data.characteristics.DiskMarginMinimumResponseData(this);
        end

        function gainFocus = computeGainFocus(this,frequencyFocus,gainScale)
            arguments
                this (1,1) controllib.chart.internal.data.response.DiskMarginResponseDataSource
                frequencyFocus (1,1) cell
                gainScale (1,1) string {mustBeMember(gainScale,["linear","log"])}
            end
            gainFocus = cell(1,this.NResponses);
            for ka = 1:this.NResponses
                gainFocus{ka} = [NaN, NaN];
                % Get indices of frequencies within the focus (note
                % that these values are not necessarily equal to
                % focus values)
                idx1 = find(this.Frequency{ka} >= frequencyFocus{1}(1),1,'first');
                idx2 = find(this.Frequency{ka} <= frequencyFocus{1}(2),1,'last');

                if isempty(idx1) || isempty(idx2)
                    continue; % data lies outside focus
                end

                if idx1 >= idx2
                    % focus lies between two data points
                    gain_k = this.GainMargin{ka}([idx1 idx2]);
                    gainMin = min(gain_k);
                    gainMax = max(gain_k);
                else
                    % Get min and max of yData
                    gain_k = this.GainMargin{ka}(idx1:idx2);

                    [gainMin, idxMin] = min(gain_k);
                    [gainMax, idxMax] = max(gain_k);

                    % Check if first data point is minimum
                    if idxMin == 1 && idx1>1
                        % Interpolate to get yDataFocus(1) when f = frequencyFocus(1)
                        f = this.Frequency{ka}(idx1-1:idx1);
                        y = this.GainMargin{ka}(idx1-1:idx1);
                        gainMin = interp1(f,y,frequencyFocus{1}(1));
                    end

                    % Check if last data point is maximum
                    if idxMax == length(gain_k) && idx2<length(this.Frequency{ka})
                        % Interpolate to get yDataFocus(2) when f = frequencyFocus(2)
                        f = this.Frequency{ka}(idx2:idx2+1);
                        y = this.GainMargin{ka}(idx2:idx2+1);
                        gainMax = interp1(f,y,frequencyFocus{1}(2));
                    end
                end

                % Check if value close to 0 (which results in error when
                % converting setting axis limits)
                if gainScale == "log"
                    gainMin = max([gainMin, eps]);
                    gainMax = max([gainMax, eps]);
                end

                gainFocus{ka} = [gainMin,gainMax];
                if (gainFocus{ka}(1) == gainFocus{ka}(2)) || any(isnan(gainFocus{ka}))
                    value = gainFocus{ka}(1);
                    if value == 0 || isnan(value)
                        gainFocus{ka}(1) = 0.9;
                        gainFocus{ka}(2) = 1.1;
                    else
                        absValue = abs(value);
                        gainFocus{ka}(1) = value - 0.1*absValue;
                        gainFocus{ka}(2) = value + 0.1*absValue;
                    end
                end
                gainFocus{ka}(1) = 1;
                gainFocus{ka}(2) = min(100,max(gainFocus{ka}(2),5));
            end
        end
        function phaseFocus = computePhaseFocus(this,frequencyFocus)
            arguments
                this (1,1) controllib.chart.internal.data.response.DiskMarginResponseDataSource
                frequencyFocus (1,1) cell
            end
            phaseFocus = cell(1,this.NResponses);
            for ka = 1:this.NResponses
                phaseFocus{ka} = [NaN, NaN];
                % Get indices of frequencies within the focus (note
                % that these values are not necessarily equal to
                % focus values)
                idx1 = find(this.Frequency{ka} >= frequencyFocus{1}(1),1,'first');
                idx2 = find(this.Frequency{ka} <= frequencyFocus{1}(2),1,'last');

                if isempty(idx1) || isempty(idx2)
                    continue; % data lies outside focus
                end

                if idx1 >= idx2
                    % focus lies between two data points
                    phase_k = this.PhaseMargin{ka}([idx1 idx2]);
                    phaseMin = min(phase_k);
                    phaseMax = max(phase_k);
                else
                    % Get min and max of yData
                    phase_k = this.PhaseMargin{ka}(idx1:idx2);

                    [phaseMin, idxMin] = min(phase_k);
                    [phaseMax, idxMax] = max(phase_k);

                    % Check if first data point is minimum
                    if idxMin == 1 && idx1>1
                        % Interpolate to get yDataFocus(1) when f = frequencyFocus(1)
                        f = this.Frequency{ka}(idx1-1:idx1);
                        y = this.PhaseMargin{ka}(idx1-1:idx1);
                        phaseMin = interp1(f,y,frequencyFocus{1}(1));
                    end

                    % Check if last data point is maximum
                    if idxMax == length(phase_k) && idx2<length(this.Frequency{ka})
                        % Interpolate to get yDataFocus(2) when f = frequencyFocus(2)
                        f = this.Frequency{ka}(idx2:idx2+1);
                        y = this.PhaseMargin{ka}(idx2:idx2+1);
                        phaseMax = interp1(f,y,frequencyFocus{1}(2));
                    end
                end

                phaseFocus{ka} = [phaseMin,phaseMax];
                if (phaseFocus{ka}(1) == phaseFocus{ka}(2)) || any(isnan(phaseFocus{ka}))
                    value = phaseFocus{ka}(1);
                    if value == 0 || isnan(value)
                        phaseFocus{ka}(1) = -0.1;
                        phaseFocus{ka}(2) = 0.1;
                    else
                        absValue = abs(value);
                        phaseFocus{ka}(1) = value - 0.1*absValue;
                        phaseFocus{ka}(2) = value + 0.1*absValue;
                    end
                end
                phaseFocus{ka}(1) = max(0,10*floor(phaseFocus{ka}(1)/10));
                phaseFocus{ka}(2) = min(180,10*ceil(phaseFocus{ka}(2)/10));
            end
        end
    end
end


