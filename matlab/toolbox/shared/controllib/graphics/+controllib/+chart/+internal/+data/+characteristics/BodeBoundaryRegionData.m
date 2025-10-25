classdef BodeBoundaryRegionData < controllib.chart.internal.data.characteristics.BaseCharacteristicData
    % controllib.chart.internal.data.BodeBoundaryRegionData
    %   - class for computing boundary data of a bode response
    %
    % h = BodeBoundaryRegionData(data)
    %   data   controllib.chart.internal.data.response.BaseResponseDataSource
    %
    % Read-only Properties:
    %   ResponseData            response data object, controllib.chart.internal.data.response.BaseResponseDataSource
    %   Type                    type of characteristics, string scalar
    %   IsDirty                 flag if response needs to be computed, logical scalar
    %   Frequency               frequency data of boundary
    %   UpperBoundaryMagnitude  upper magnitude data of boundary
    %   LowerBoundaryMagnitude  lower magnitude data of boundary
    %   UpperBoundaryPhase      upper phase data of boundary
    %   LowerBoundaryPhase      lower phase data of boundary
    %
    % Events:
    %   DataChanged             notified in update()
    %
    % Public methods:
    %   update(this)
    %       Update the the characteristic data using ResponseData. Marks IsDirty as true.
    %   compute(this)
    %       Computes the characteristic data with stored Data. Marks IsDirty as false.
    %   computeMagnitudeFocus(this,frequencyFocuses,magnitudeScale)
    %       Compute the magnitude focus. Called in getCommonMagnitudeFocus().
    %   computePhaseFocus(this,frequencyFocuses)
    %       Compute the phase focus. Called in getCommonPhaseFocus().
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
    
    % Copyright 2022-2024 The MathWorks, Inc.

    %% Properties
    properties (SetAccess = protected)
        Frequency
        UpperBoundaryMagnitude
        LowerBoundaryMagnitude
        UpperBoundaryPhase
        LowerBoundaryPhase
    end

    %% Constructor
    methods
        function this = BodeBoundaryRegionData(data)
            this@controllib.chart.internal.data.characteristics.BaseCharacteristicData(data);
            this.Type = "BoundaryRegion";
        end
    end

    %% Public methods
    methods
        function magFocus = computeMagnitudeFocus(this,frequencyFocuses,magnitudeScale)
            arguments
                this (1,1) controllib.chart.internal.data.characteristics.BodeBoundaryRegionData
                frequencyFocuses (:,:) cell
                magnitudeScale (1,1) string {mustBeMember(magnitudeScale,["linear","log"])}
            end
            magFocus = repmat({[NaN, NaN]},this.ResponseData.NOutputs,this.ResponseData.NInputs);
            for ko = 1:this.ResponseData.NOutputs
                for ki = 1:this.ResponseData.NInputs
                    frequencyFocus = frequencyFocuses{ko,ki};

                    idx1 = find(this.Frequency >= frequencyFocus(1),1,'first');
                    idx2 = find(this.Frequency <= frequencyFocus(2),1,'last');

                    if isempty(idx1) || isempty(idx2)
                        continue; % data lies outside focus
                    end

                    if idx1 >= idx2
                        % focus lies between two data points
                        lower_mag_k = this.LowerBoundaryMagnitude([idx1 idx2],ko,ki);
                        upper_mag_k = this.UpperBoundaryMagnitude([idx1 idx2],ko,ki);
                        magMin = min(lower_mag_k);
                        magMax = max(upper_mag_k);
                    else
                        % Get min and max of yData
                        lower_mag_k = this.LowerBoundaryMagnitude(idx1:idx2,ko,ki);
                        upper_mag_k = this.UpperBoundaryMagnitude(idx1:idx2,ko,ki);

                        [magMin, idxMin] = min(lower_mag_k);
                        [magMax, idxMax] = max(upper_mag_k);

                        % Check if first data point is minimum
                        if idxMin == 1 && idx1>1
                            % Interpolate to get yDataFocus(1) when f = frequencyFocus(1)
                            f = this.Frequency(idx1-1:idx1);
                            y = this.LowerBoundaryMagnitude(idx1-1:idx1,ko,ki);
                            magMin = interp1(f,y,frequencyFocus(1));
                        end

                        % Check if last data point is maximum
                        if idxMax == length(upper_mag_k) && idx2<length(this.Frequency)
                            % Interpolate to get yDataFocus(2) when f = frequencyFocus(2)
                            f = this.Frequency(idx2:idx2+1);
                            y = this.UpperBoundaryMagnitude(idx2:idx2+1,ko,ki);
                            magMax = interp1(f,y,frequencyFocus(2));
                        end
                    end

                    % Check if value close to 0 (which results in error when
                    % converting setting axis limits)
                    if magnitudeScale == "log"
                        magMin = max([magMin, eps]);
                        magMax = max([magMax, eps]);
                    end

                    magFocus{ko,ki} = [magMin,magMax];
                    if (magFocus{ko,ki}(1) == magFocus{ko,ki}(2)) || any(isnan(magFocus{ko,ki}))
                        value = magFocus{ko,ki}(1);
                        if value == 0 || isnan(value)
                            magFocus{ko,ki}(1) = 0.9;
                            magFocus{ko,ki}(2) = 1.1;
                        else
                            absValue = abs(value);
                            magFocus{ko,ki}(1) = value - 0.1*absValue;
                            magFocus{ko,ki}(2) = value + 0.1*absValue;
                        end
                    end
                end
            end
        end

        function phaseFocus = computePhaseFocus(this,frequencyFocuses,phaseWrapped,phaseMatched)
            arguments
                this (1,1) controllib.chart.internal.data.characteristics.BodeBoundaryRegionData
                frequencyFocuses (:,:) cell
                phaseWrapped (1,1) logical
                phaseMatched (1,1) logical
            end
            phaseFocus = repmat({[NaN, NaN]},this.ResponseData.NOutputs,this.ResponseData.NInputs);
            for ko = 1:this.ResponseData.NOutputs
                for ki = 1:this.ResponseData.NInputs
                    frequencyFocus = frequencyFocuses{ko,ki};

                    idx1 = find(this.Frequency >= frequencyFocus(1),1,'first');
                    idx2 = find(this.Frequency <= frequencyFocus(2),1,'last');

                    if isempty(idx1) || isempty(idx2)
                        continue; % data lies outside focus
                    end

                    lowerPhase = this.LowerBoundaryPhase(:,ko,ki);
                    upperPhase = this.UpperBoundaryPhase(:,ko,ki);

                    phase = this.ResponseData.Phase{1}(:,ko,ki);
                    if phaseWrapped && phaseMatched
                        phaseValue = this.ResponseData.WrappedAndMatchedPhase{1}(:,ko,ki);
                    elseif phaseWrapped
                        phaseValue = this.ResponseData.WrappedPhase{1}(:,ko,ki);
                    elseif phaseMatched
                        phaseValue = this.ResponseData.MatchedPhase{1}(:,ko,ki);
                    else
                        phaseValue = phase;
                    end
                    for ii = 1:length(lowerPhase)
                        [~,idx] = min(abs(this.ResponseData.Frequency{1} - this.Frequency(ii)));
                        m = round((phaseValue(idx) - phase(idx))/(2*pi));
                        offset = 2*pi*m;
                        lowerPhase(ii) = lowerPhase(ii)+offset;
                        upperPhase(ii) = upperPhase(ii)+offset;
                    end

                    if idx1 >= idx2
                        % focus lies between two data points
                        lower_phase_k = lowerPhase([idx1 idx2]);
                        upper_phase_k = upperPhase([idx1 idx2]);
                        phaseMin = min(lower_phase_k);
                        phaseMax = max(upper_phase_k);
                    else
                        % Get min and max of yData
                        lower_phase_k = lowerPhase(idx1:idx2);
                        upper_phase_k = upperPhase(idx1:idx2);

                        [phaseMin, idxMin] = min(lower_phase_k);
                        [phaseMax, idxMax] = max(upper_phase_k);

                        % Check if first data point is minimum
                        if idxMin == 1 && idx1>1
                            % Interpolate to get yDataFocus(1) when f = frequencyFocus(1)
                            f = this.Frequency(idx1-1:idx1);
                            y = lowerPhase(idx1-1:idx1);
                            phaseMin = interp1(f,y,frequencyFocus(1));
                        end

                        % Check if last data point is maximum
                        if idxMax == length(upper_phase_k) && idx2<length(this.Frequency)
                            % Interpolate to get yDataFocus(2) when f = frequencyFocus(2)
                            f = this.Frequency(idx2:idx2+1);
                            y = upperPhase(idx2:idx2+1);
                            phaseMax = interp1(f,y,frequencyFocus(2));
                        end
                    end

                    phaseFocus{ko,ki} = [phaseMin,phaseMax];
                    if (phaseFocus{ko,ki}(1) == phaseFocus{ko,ki}(2)) || any(isnan(phaseFocus{ko,ki}))
                        value = phaseFocus{ko,ki}(1);
                        if value == 0 || isnan(value)
                            phaseFocus{ko,ki}(1) = -0.1;
                            phaseFocus{ko,ki}(2) = 0.1;
                        else
                            absValue = abs(value);
                            phaseFocus{ko,ki}(1) = value - 0.1*absValue;
                            phaseFocus{ko,ki}(2) = value + 0.1*absValue;
                        end
                    end
                end
            end
        end
    end

    %% Protected methods
    methods (Access = protected)
        function compute_(this)
            data = this.ResponseData;
            nRows = data.NOutputs;
            nColumns = data.NInputs;
            nArray = data.NResponses;

            N = 0;
            for ct = 1:nArray
                N = N + numel(data.Frequency{ct});
            end
            f = zeros(N,1);
            ctr = 1;
            for ct = 1:nArray
                freq = data.Frequency{ct}(:);
                N = length(freq);
                f(ctr:ctr+N-1) = freq;
                ctr = ctr + N;
            end
            this.Frequency = unique(f);

            Magnitude = zeros(length(this.Frequency),nRows,nColumns,nArray);
            Phase = zeros(length(this.Frequency),nRows,nColumns,nArray);
            for ct = 1:nArray
                for kr = 1:nRows
                    for kc = 1:nColumns
                        Magnitude(:,kr,kc,ct) = ...
                            utInterp1(data.Frequency{ct}(:),...
                            data.Magnitude{ct}(:,kr,kc),this.Frequency);
                        Phase(:,kr,kc,ct) = ...
                            utInterp1(data.Frequency{ct}(:),...
                            data.Phase{ct}(:,kr,kc),this.Frequency);
                    end
                end
            end

            this.UpperBoundaryMagnitude = max(Magnitude,[],4);
            this.LowerBoundaryMagnitude = min(Magnitude,[],4);

            this.UpperBoundaryPhase = max(Phase,[],4);
            this.LowerBoundaryPhase = min(Phase,[],4);
        end
    end
end
