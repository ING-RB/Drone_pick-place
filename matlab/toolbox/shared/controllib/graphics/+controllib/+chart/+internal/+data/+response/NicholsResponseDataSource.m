classdef NicholsResponseDataSource < controllib.chart.internal.data.response.FrequencyResponseDataSource
    % controllib.chart.internal.data.response.NicholsResponseDataSource
    %   - manage source and data objects for given nichols response
    %   - inherited from controllib.chart.internal.data.response.FrequencyResponseDataSource
    %
    % h = NicholsResponseDataSource(model)
    %   model           DynamicSystem
    %
    % h = NicholsResponseDataSource(_____,Name-Value)
    %   Frequency             frequency specification used to generate data, [] (default) auto generates frequency specification
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
    %   Magnitude                   magnitude for response, cell
    %   Phase                       phase for response, cell
    %   NicholsPeakResponse         peak response characteristic, controllib.chart.internal.data.characteristics.FrequencyPeakResponseData
    %   AllStabilityMargin          all stability margin characteristic (only for siso), controllib.chart.internal.data.characteristics.FrequencyAllStabilityMarginData
    %   MinimumStabilityMargin      min stability margin characteristic (only for siso), controllib.chart.internal.data.characteristics.FrequencyMinimumStabilityMarginData
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
    %   getCommonFrequencyFocus(this,arrayVisible)
    %       Get frequency focus values for an array of response data.
    %   getCommonMagnitudeFocus(this,arrayVisible)
    %       Get magnitude focus values for an array of response data.
    %   getCommonPhaseFocus(this,arrayVisible)
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
    %   computeMagnitudeFocus(this)
    %       Compute the magnitude focus. Called in updateData().
    %   computePhaseFocus(this)
    %       Compute the phase focus. Called in updateData().
    %
    % See Also:
    %   <a href="matlab:help controllib.chart.internal.data.response.FrequencyResponseDataSource">controllib.chart.internal.data.response.FrequencyResponseDataSource</a>

    %% Properties
    properties (SetAccess = protected)
        % "Magnitude": cell vector
        % Magnitude for response.
        Magnitude
        % "Phase": cell vector
        % Phase for response.
        Phase
        % "MagnitudeFocus": cell vector
        % Magnitude focus data of response.
        MagnitudeFocus
    end

    properties (Dependent,SetAccess=private)
        % "NicholsPeakResponse": controllib.chart.internal.data.characteristics.FrequencyPeakResponseData scalar
        % Peak response characteristics.
        NicholsPeakResponse
        % "AllStabilityMargin": controllib.chart.internal.data.characteristics.FrequencyAllStabilityMarginData scalar
        % All stability margin characteristic.
        AllStabilityMargin
        % "MinimumStabilityMargin": controllib.chart.internal.data.characteristics.FrequencyMinimumStabilityMarginData scalar
        % Minimum stability margin characteristic.
        MinimumStabilityMargin
        % "WrappedPhase": cell vector
        % Wrapped phase for response.
        WrappedPhase
        % "MatchedPhase": cell vector
        % Matched phase for response.
        MatchedPhase
        % "WrappedAndMatchedPhase": cell vector
        % Wrapped and matched phase for response.
        WrappedAndMatchedPhase
    end

    properties (SetAccess=?controllib.chart.response.NicholsResponse)
        PhaseWrappingBranch
        PhaseMatchingFrequency
        PhaseMatchingValue
    end

    %% Constructor
    methods
        function this = NicholsResponseDataSource(model,nicholsResponseOptionalArguments,frequencyResponseOptionalInputs)
            arguments
                model
                nicholsResponseOptionalArguments.PhaseWrappingBranch = -180
                nicholsResponseOptionalArguments.PhaseMatchingFrequency = 0
                nicholsResponseOptionalArguments.PhaseMatchingValue = 0
                frequencyResponseOptionalInputs.Frequency = []
            end
            frequencyResponseOptionalInputs = namedargs2cell(frequencyResponseOptionalInputs);
            this@controllib.chart.internal.data.response.FrequencyResponseDataSource(model,frequencyResponseOptionalInputs{:});
            this.Type = "NicholsResponse";

            this.PhaseWrappingBranch = nicholsResponseOptionalArguments.PhaseWrappingBranch;
            this.PhaseMatchingFrequency = nicholsResponseOptionalArguments.PhaseMatchingFrequency;
            this.PhaseMatchingValue = nicholsResponseOptionalArguments.PhaseMatchingValue;
            % Update response
            update(this);
        end
    end

    %% Public methods
    methods
        function [commonMagnitudeFocus,magnitudeUnit] = getCommonMagnitudeFocus(this,optionalInputs)
            arguments
                this (:,1) controllib.chart.internal.data.response.NicholsResponseDataSource
                optionalInputs.ArrayVisible (:,1) cell = arrayfun(@(x) {true(x.NResponses,1)},this)
            end
            nInputs = max([this.NInputs]);
            nOutputs = max([this.NOutputs]);
            commonMagnitudeFocus = repmat({[NaN,NaN]},nOutputs,nInputs);
            magnitudeUnit = 'abs';
            for k = 1:length(this) % loop for number of data objects
                for ka = 1:this(k).NResponses % loop for system array
                    if optionalInputs.ArrayVisible{k}(ka)
                        for ko = 1:nOutputs % loop for outputs
                            ko_idx = mapDataToPlotOutputIdx(this(k),ko);
                            for ki = 1:nInputs
                                ki_idx = mapDataToPlotInputIdx(this(k),ki);
                                % Compute focus if plot i/o index is non empty
                                if ~isempty(ko_idx) && ~isempty(ki_idx)
                                    % Magnitude Focus
                                    magnitudeFocus = this(k).MagnitudeFocus{ka}{ko_idx,ki_idx};
                                    commonMagnitudeFocus{ko,ki}(1) = ...
                                        min(commonMagnitudeFocus{ko,ki}(1),magnitudeFocus(1));
                                    commonMagnitudeFocus{ko,ki}(2) = ...
                                        max(commonMagnitudeFocus{ko,ki}(2),magnitudeFocus(2));
                                end
                            end
                        end
                    end
                end
            end
        end

        function [commonPhaseFocus,phaseUnit] = getCommonPhaseFocus(this,optionalInputs)
            arguments
                this (:,1) controllib.chart.internal.data.response.NicholsResponseDataSource
                optionalInputs.ArrayVisible (:,1) cell = arrayfun(@(x) {true(x.NResponses,1)},this)
                optionalInputs.PhaseWrappingEnabled (1,1) logical = false
                optionalInputs.PhaseMatchingEnabled (1,1) logical = false
            end
            nInputs = max([this.NInputs]);
            nOutputs = max([this.NOutputs]);
            commonPhaseFocus = repmat({[NaN,NaN]},nOutputs,nInputs);
            phaseUnit = 'rad';
            for k = 1:length(this) % loop for number of data objects
                phaseFocuses = computePhaseFocus(this(k),optionalInputs.PhaseWrappingEnabled,optionalInputs.PhaseMatchingEnabled);
                for ka = 1:this(k).NResponses % loop for system array
                    if optionalInputs.ArrayVisible{k}(ka)
                        for ko = 1:nOutputs % loop for outputs
                            ko_idx = mapDataToPlotOutputIdx(this(k),ko);
                            for ki = 1:nInputs
                                ki_idx = mapDataToPlotInputIdx(this(k),ki);
                                % Compute focus if plot i/o index is non empty
                                if ~isempty(ko_idx) && ~isempty(ki_idx)
                                    % Magnitude Focus
                                    phaseFocus = phaseFocuses{ka}{ko_idx,ki_idx};
                                    commonPhaseFocus{ko,ki}(1) = ...
                                        min(commonPhaseFocus{ko,ki}(1),phaseFocus(1));
                                    commonPhaseFocus{ko,ki}(2) = ...
                                        max(commonPhaseFocus{ko,ki}(2),phaseFocus(2));
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    %% Get/Set methods
    methods
        % NicholsPeakResponse
        function NicholsPeakResponse = get.NicholsPeakResponse(this)
            arguments
                this (1,1) controllib.chart.internal.data.response.NicholsResponseDataSource
            end
            NicholsPeakResponse = getCharacteristics(this,"FrequencyPeakResponse");
        end

        % AllStabilityMargin
        function AllStabilityMargin = get.AllStabilityMargin(this)
            arguments
                this (1,1) controllib.chart.internal.data.response.NicholsResponseDataSource
            end
            AllStabilityMargin = getCharacteristics(this,"AllStabilityMargins");
        end

        % MinimumStabilityMargin
        function MinimumStabilityMargin = get.MinimumStabilityMargin(this)
            arguments
                this (1,1) controllib.chart.internal.data.response.NicholsResponseDataSource
            end
            MinimumStabilityMargin = getCharacteristics(this,"MinimumStabilityMargins");
        end

        %WrappedPhase
        function WrappedPhase = get.WrappedPhase(this)
            WrappedPhase = computeWrappedPhase(this,this.Phase);
        end

        %MatchedPhase
        function MatchedPhase = get.MatchedPhase(this)
            MatchedPhase = computeMatchedPhase(this,this.Phase);
        end

        %WrappedAndMatchedPhase
        function WrappedAndMatchedPhase = get.WrappedAndMatchedPhase(this)
            wrappedPhase = computeWrappedPhase(this,this.Phase);
            WrappedAndMatchedPhase = computeMatchedPhase(this,wrappedPhase);
        end
    end

    %% Protected methods
    methods (Access = protected)
        function updateData(this,frequencyResponseOptionalInputs)
            arguments
                this (1,1) controllib.chart.internal.data.response.NicholsResponseDataSource
                frequencyResponseOptionalInputs.Model = this.Model
                frequencyResponseOptionalInputs.Frequency = this.FrequencyInput
            end
            try
                sysList.System = frequencyResponseOptionalInputs.Model;
                ParamList = {frequencyResponseOptionalInputs.Frequency};
                [sysList,w] = DynamicSystem.checkBodeInputs(sysList,ParamList);
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
            this.Magnitude = repmat({NaN(this.NOutputs,this.NInputs)},this.NResponses,1);
            this.Phase = repmat({NaN(this.NOutputs,this.NInputs)},this.NResponses,1);
            this.Frequency = repmat({NaN},this.NResponses,1);
            focus = repmat({[NaN NaN]},this.NOutputs,this.NInputs);
            this.FrequencyFocus = repmat({focus},this.NResponses,1);
            this.MagnitudeFocus = repmat({focus},this.NResponses,1);
            if ~isempty(this.DataException)
                return;
            end
            try
                for ka = 1:this.NResponses
                    [mag,phase,w,focus] = getMagPhaseData_(this.ModelValue,...
                                        this.FrequencyInput,"nichols",ka);
                    if size(mag,3) == 0 %idnlmodel idpoly
                        mag = NaN(size(mag,1),size(mag,2),1);
                        phase = NaN(size(phase,1),size(phase,2),1);
                    end
                    this.Magnitude{ka} = mag;
                    if all(mag(:)==0)
                        this.Phase{ka} = NaN(size(phase));
                    else
                        this.Phase{ka} = phase;
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
                    this.FrequencyFocus{ka} = repmat({roundedFocus},this.NOutputs,this.NInputs);
                end
                this.MagnitudeFocus = computeMagnitudeFocus(this);
            catch ME
                this.DataException = ME;
            end
        end

        function characteristics = createCharacteristics_(this)
            arguments
                this (1,1) controllib.chart.internal.data.response.NicholsResponseDataSource
            end
            characteristics(1) = controllib.chart.internal.data.characteristics.FrequencyPeakResponseData(this);
            if this.NInputs == 1 && this.NOutputs == 1
                characteristics(2) = controllib.chart.internal.data.characteristics.FrequencyAllStabilityMarginData(this);
                characteristics(3) = controllib.chart.internal.data.characteristics.FrequencyMinimumStabilityMarginData(this);
            end
        end

        function magFocus = computeMagnitudeFocus(this)
            arguments
                this (1,1) controllib.chart.internal.data.response.NicholsResponseDataSource
            end
            magFocus = cell(1,this.NResponses);
            for ka = 1:this.NResponses
                magFocus{ka} = repmat({[NaN, NaN]},this.NOutputs,this.NInputs);
                for ko = 1:this.NOutputs
                    for ki = 1:this.NInputs
                        % Get indices of frequencies within the focus (note
                        % that these values are not necessarily equal to
                        % focus values)
                        frequencyFocus = this.FrequencyFocus{ka}{ko,ki};

                        idx1 = find(this.Frequency{ka} >= frequencyFocus(1),1,'first');
                        idx2 = find(this.Frequency{ka} <= frequencyFocus(2),1,'last');

                        if ~isempty(idx1) &&  ~isempty(idx2)
                            [magMin,magMax] = computeMagnitudeFocusFromIndices(this,frequencyFocus,idx1,idx2,ko,ki,ka);
                        else
                            magMin = NaN;
                            magMax = NaN;
                        end

                        if ~this.IsReal
                            idx3 = find(this.Frequency{ka} >= -frequencyFocus(2),1,'first');
                            idx4 = find(this.Frequency{ka} <= -frequencyFocus(1),1,'last');

                            if ~isempty(idx3) && ~isempty(idx4)
                                [magMinForNegativeFrequency,magMaxForNegativeFrequency] = ...
                                    computeMagnitudeFocusFromIndices(this,-fliplr(frequencyFocus),idx3,idx4,ko,ki,ka);
                                magMin = min(magMin,magMinForNegativeFrequency);
                                magMax = max(magMax,magMaxForNegativeFrequency);
                            end
                        else
                            idx3 = [];
                            idx4 = [];
                        end

                        if (isempty(idx1) || isempty(idx2)) && (isempty(idx3) || isempty(idx4))
                            continue;
                        end

                        magFocus{ka}{ko,ki} = [magMin,magMax];
                        if (magFocus{ka}{ko,ki}(1) == magFocus{ka}{ko,ki}(2)) || any(isnan(magFocus{ka}{ko,ki}))
                            value = magFocus{ka}{ko,ki}(1);
                            if value == 0 || isnan(value)
                                magFocus{ka}{ko,ki}(1) = 0.9;
                                magFocus{ka}{ko,ki}(2) = 1.1;
                            else
                                absValue = abs(value);
                                magFocus{ka}{ko,ki}(1) = value - 0.1*absValue;
                                magFocus{ka}{ko,ki}(2) = value + 0.1*absValue;
                            end
                        end
                    end
                end
            end
        end

        % function magFocus = computeMagnitudeFocus(this)
        %     arguments
        %         this (1,1) controllib.chart.internal.data.response.NicholsResponseDataSource
        %     end
        %     magFocus = cell(1,this.NResponses);
        %     for ka = 1:this.NResponses
        %         magFocus{ka} = repmat({[NaN, NaN]},this.NOutputs,this.NInputs);
        %         for ko = 1:this.NOutputs
        %             for ki = 1:this.NInputs
        %                 % Get indices of frequencies within the focus (note
        %                 % that these values are not necessarily equal to
        %                 % focus values)
        %                 frequencyFocus = this.FrequencyFocus{ka}{ko,ki};
        %
        %                 idx1 = find(this.Frequency{ka} >= frequencyFocus(1),1,'first');
        %                 idx2 = find(this.Frequency{ka} <= frequencyFocus(2),1,'last');
        %
        %                 if isempty(idx1) || isempty(idx2)
        %                     continue; % data lies outside focus
        %                 end
        %
        %                 if isempty(this.Magnitude{ka})
        %                     magMin = 0;
        %                     magMax = 0;
        %                 elseif idx1 >= idx2
        %                     % focus lies between two data points
        %                     mag_k = this.Magnitude{ka}([idx1 idx2],ko,ki);
        %                     magMin = min(mag_k);
        %                     magMax = max(mag_k);
        %                 else
        %                     % Get min and max of yData
        %                     mag_k = this.Magnitude{ka}(idx1:idx2,ko,ki);
        %
        %                     [magMin, idxMin] = min(mag_k);
        %                     [magMax, idxMax] = max(mag_k);
        %
        %                     % Check if first data point is minimum
        %                     if idxMin == 1 && idx1>1
        %                         % Interpolate to get yDataFocus(1) when f = frequencyFocus(1)
        %                         f = this.Frequency{ka}(idx1-1:idx1);
        %                         y = this.Magnitude{ka}(idx1-1:idx1,ko,ki);
        %                         magMin = interp1(f,y,frequencyFocus(1));
        %                     end
        %
        %                     % Check if last data point is maximum
        %                     if idxMax == length(mag_k) && idx2<length(this.Frequency{ka})
        %                         % Interpolate to get yDataFocus(2) when f = frequencyFocus(2)
        %                         f = this.Frequency{ka}(idx2:idx2+1);
        %                         y = this.Magnitude{ka}(idx2:idx2+1,ko,ki);
        %                         magMax = interp1(f,y,frequencyFocus(2));
        %                     end
        %                 end
        %
        %                 % Check if value close to 0 (which results in error when
        %                 % converting setting axis limits)
        %                 magMin = max([magMin, eps]);
        %                 magMax = max([magMax, eps]);
        %
        %                 magFocus{ka}{ko,ki} = [magMin,magMax];
        %                 if (magFocus{ka}{ko,ki}(1) == magFocus{ka}{ko,ki}(2)) || any(isnan(magFocus{ka}{ko,ki}))
        %                     value = magFocus{ka}{ko,ki}(1);
        %                     if value == 0 || isnan(value)
        %                         magFocus{ka}{ko,ki}(1) = 0.9;
        %                         magFocus{ka}{ko,ki}(2) = 1.1;
        %                     else
        %                         absValue = abs(value);
        %                         magFocus{ka}{ko,ki}(1) = value - 0.1*absValue;
        %                         magFocus{ka}{ko,ki}(2) = value + 0.1*absValue;
        %                     end
        %                 end
        %             end
        %         end
        %     end
        % end

        % function phaseFocus = computePhaseFocus(this,phaseWrapped,phaseMatched)
        %     arguments
        %         this (1,1) controllib.chart.internal.data.response.NicholsResponseDataSource
        %         phaseWrapped (1,1) logical
        %         phaseMatched (1,1) logical
        %     end
        %     phaseFocus = cell(1,this.NResponses);
        %     if phaseWrapped && phaseMatched
        %         phase = this.WrappedAndMatchedPhase;
        %     elseif phaseWrapped
        %         phase = this.WrappedPhase;
        %     elseif phaseMatched
        %         phase = this.MatchedPhase;
        %     else
        %         phase = this.Phase;
        %     end
        %     for ka = 1:this.NResponses
        %         phaseFocus{ka} = repmat({[NaN, NaN]},this.NOutputs,this.NInputs);
        %         for ko = 1:this.NOutputs
        %             for ki = 1:this.NInputs
        %                 % Get indices of frequencies within the focus (note
        %                 % that these values are not necessarily equal to
        %                 % focus values)
        %                 frequencyFocus = this.FrequencyFocus{ka}{ko,ki};
        %
        %                 idx1 = find(this.Frequency{ka} >= frequencyFocus(1),1,'first');
        %                 idx2 = find(this.Frequency{ka} <= frequencyFocus(2),1,'last');
        %
        %                 if isempty(idx1) || isempty(idx2)
        %                     continue; % data lies outside focus
        %                 end
        %
        %                 if idx1 >= idx2
        %                     % focus lies between two data points
        %                     phase_k = phase{ka}([idx1 idx2],ko,ki);
        %                     phaseMin = min(phase_k);
        %                     phaseMax = max(phase_k);
        %                 else
        %                     % Get min and max of yData
        %                     phase_k = phase{ka}(idx1:idx2,ko,ki);
        %
        %                     [phaseMin, idxMin] = min(phase_k);
        %                     [phaseMax, idxMax] = max(phase_k);
        %
        %                     % Check if first data point is minimum
        %                     if idxMin == 1 && idx1>1
        %                         % Interpolate to get yDataFocus(1) when f = frequencyFocus(1)
        %                         f = this.Frequency{ka}(idx1-1:idx1);
        %                         y = phase{ka}(idx1-1:idx1,ko,ki);
        %                         phaseMin = interp1(f,y,frequencyFocus(1));
        %                     end
        %
        %                     % Check if last data point is maximum
        %                     if idxMax == length(phase_k) && idx2<length(this.Frequency{ka})
        %                         % Interpolate to get yDataFocus(2) when f = frequencyFocus(2)
        %                         f = this.Frequency{ka}(idx2:idx2+1);
        %                         y = phase{ka}(idx2:idx2+1,ko,ki);
        %                         phaseMax = interp1(f,y,frequencyFocus(2));
        %                     end
        %                 end
        %
        %                 phaseFocus{ka}{ko,ki} = [phaseMin,phaseMax];
        %                 if (phaseFocus{ka}{ko,ki}(1) == phaseFocus{ka}{ko,ki}(2)) || any(isnan(phaseFocus{ka}{ko,ki}))
        %                     value = phaseFocus{ka}{ko,ki}(1);
        %                     if value == 0 || isnan(value)
        %                         phaseFocus{ka}{ko,ki}(1) = -0.1;
        %                         phaseFocus{ka}{ko,ki}(2) = 0.1;
        %                     else
        %                         absValue = abs(value);
        %                         phaseFocus{ka}{ko,ki}(1) = value - 0.1*absValue;
        %                         phaseFocus{ka}{ko,ki}(2) = value + 0.1*absValue;
        %                     end
        %                 end
        %             end
        %         end
        %     end

        function phaseFocus = computePhaseFocus(this,phaseWrapped,phaseMatched)
            arguments
                this (1,1) controllib.chart.internal.data.response.NicholsResponseDataSource
                phaseWrapped (1,1) logical
                phaseMatched (1,1) logical
            end
            phaseFocus = cell(1,this.NResponses);
            if phaseWrapped && phaseMatched
                phase = this.WrappedAndMatchedPhase;
            elseif phaseWrapped
                phase = this.WrappedPhase;
            elseif phaseMatched
                phase = this.MatchedPhase;
            else
                phase = this.Phase;
            end
            for ka = 1:this.NResponses
                phaseFocus{ka} = repmat({[NaN, NaN]},this.NOutputs,this.NInputs);
                for ko = 1:this.NOutputs
                    for ki = 1:this.NInputs
                        % Get indices of frequencies within the focus (note
                        % that these values are not necessarily equal to
                        % focus values)
                        frequencyFocus = this.FrequencyFocus{ka}{ko,ki};
                        idx1 = find(this.Frequency{ka} >= frequencyFocus(1),1,'first');
                        idx2 = find(this.Frequency{ka} <= frequencyFocus(2),1,'last');

                        if isempty(idx1) || isempty(idx2)
                            continue; % data lies outside focus
                        end

                        [phaseMin,phaseMax] = computePhaseFocusFromIndices(this,phase,frequencyFocus,...
                            idx1,idx2,ko,ki,ka);

                        if ~this.IsReal
                            idx3 = find(this.Frequency{ka} >= -frequencyFocus(2),1,'first');
                            idx4 = find(this.Frequency{ka} <= -frequencyFocus(1),1,'last');
                            [phaseMinForNegativeFrequency,phaseMaxForNegativeFrequency] = ...
                                computePhaseFocusFromIndices(this,phase,-fliplr(frequencyFocus),...
                                idx3,idx4,ko,ki,ka);
                            phaseMin = min(phaseMin,phaseMinForNegativeFrequency);
                            phaseMax = max(phaseMax,phaseMaxForNegativeFrequency);
                        end

                        phaseFocus{ka}{ko,ki} = [phaseMin,phaseMax];
                        if (phaseFocus{ka}{ko,ki}(1) == phaseFocus{ka}{ko,ki}(2)) || any(isnan(phaseFocus{ka}{ko,ki}))
                            value = phaseFocus{ka}{ko,ki}(1);
                            if value == 0 || isnan(value)
                                phaseFocus{ka}{ko,ki}(1) = -0.1;
                                phaseFocus{ka}{ko,ki}(2) = 0.1;
                            else
                                absValue = abs(value);
                                phaseFocus{ka}{ko,ki}(1) = value - 0.1*absValue;
                                phaseFocus{ka}{ko,ki}(2) = value + 0.1*absValue;
                            end
                        end
                    end
                end
            end
        end

        function wrappedPhase = computeWrappedPhase(this,unwrappedPhase)
            arguments
                this (1,1) controllib.chart.internal.data.response.NicholsResponseDataSource
                unwrappedPhase cell
            end
            wrappedPhase = unwrappedPhase;
            for ka = 1:this.NResponses
                for ko = 1:this.NOutputs
                    for ki = 1:this.NInputs
                        wrappedPhase{ka}(:,ko,ki) = mod(unwrappedPhase{ka}(:,ko,ki) - this.PhaseWrappingBranch,2*pi) + this.PhaseWrappingBranch;
                    end
                end
            end
        end

        function matchedPhase = computeMatchedPhase(this,unmatchedPhase)
            arguments
                this (1,1) controllib.chart.internal.data.response.NicholsResponseDataSource
                unmatchedPhase cell
            end
            matchedPhase = unmatchedPhase;
            for ka = 1:this.NResponses
                for ko = 1:this.NOutputs
                    for ki = 1:this.NInputs
                        w = this.Frequency{ka};
                        w(isnan(unmatchedPhase{ka}(:,ko,ki))) = NaN;
                        [~,idx] = min(abs(flipud(w)-this.PhaseMatchingFrequency));  % favor positive match when tie
                        idx = numel(w)+1-idx;
                        if ~isempty(idx)
                            matchedPhase{ka}(:,ko,ki) = unmatchedPhase{ka}(:,ko,ki) - 2*pi*round((unmatchedPhase{ka}(idx,ko,ki) - this.PhaseMatchingValue)/(2*pi));
                        end
                    end
                end
            end
        end
    end

    methods(Access=private)
        function [magMin,magMax] = computeMagnitudeFocusFromIndices(this,frequencyFocus,idx1,idx2,ko,ki,ka)
            if idx1 >= idx2
                % focus lies between two data points
                mag_k = this.Magnitude{ka}([idx1 idx2],ko,ki);
                mag_k(isinf(mag_k)) = NaN;
                magMin = min(mag_k);
                magMax = max(mag_k);
            else
                % Get min and max of yData
                mag_k = this.Magnitude{ka}(idx1:idx2,ko,ki);
                mag_k(isinf(mag_k)) = NaN;
                [magMin, idxMin] = min(mag_k);
                [magMax, idxMax] = max(mag_k);

                % Check if first data point is minimum
                if idxMin == 1 && idx1>1
                    % Interpolate to get yDataFocus(1) when f = frequencyFocus(1)
                    f = this.Frequency{ka}(idx1-1:idx1);
                    y = this.Magnitude{ka}(idx1-1:idx1,ko,ki);
                    magMin = interp1(f,y,frequencyFocus(1));
                end

                % Check if last data point is maximum
                if idxMax == length(mag_k) && idx2<length(this.Frequency{ka})
                    % Interpolate to get yDataFocus(2) when f = frequencyFocus(2)
                    f = this.Frequency{ka}(idx2:idx2+1);
                    f(f==Inf) = realmax;
                    f(f==-Inf) = -realmax;
                    y = this.Magnitude{ka}(idx2:idx2+1,ko,ki);
                    magMax = interp1(f,y,frequencyFocus(2));
                end
            end
        end

        function [phaseMin,phaseMax] = computePhaseFocusFromIndices(this,phase,frequencyFocus,idx1,idx2,ko,ki,ka)
            if idx1 >= idx2
                % focus lies between two data points
                phase_k = phase{ka}([idx1 idx2],ko,ki);
                phaseMin = min(phase_k);
                phaseMax = max(phase_k);
            else
                % Get min and max of yData
                phase_k = phase{ka}(idx1:idx2,ko,ki);

                [phaseMin, idxMin] = min(phase_k);
                [phaseMax, idxMax] = max(phase_k);

                % Check if first data point is minimum
                if idxMin == 1 && idx1>1
                    % Interpolate to get yDataFocus(1) when f = frequencyFocus(1)
                    f = this.Frequency{ka}(idx1-1:idx1);
                    y = phase{ka}(idx1-1:idx1,ko,ki);
                    phaseMin = interp1(f,y,frequencyFocus(1));
                end

                % Check if last data point is maximum
                if idxMax == length(phase_k) && idx2<length(this.Frequency{ka})
                    % Interpolate to get yDataFocus(2) when f = frequencyFocus(2)
                    f = this.Frequency{ka}(idx2:idx2+1);
                    f(f==Inf) = realmax;
                    f(f==-Inf) = -realmax;
                    y = phase{ka}(idx2:idx2+1,ko,ki);
                    phaseMax = interp1(f,y,frequencyFocus(2));
                end
            end
        end
    end
end
