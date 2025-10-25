classdef BodeConfidenceRegionData < controllib.chart.internal.data.characteristics.BaseCharacteristicData
    % controllib.chart.internal.data.BodeConfidenceRegionData
    %   - class for computing confidence region data of a bode response
    %
    % h = BodeConfidenceRegionData(data)
    %   data   controllib.chart.internal.data.response.BaseResponseDataSource
    %
    % Read-only Properties:
    %   ResponseData                response data object, controllib.chart.internal.data.response.BaseResponseDataSource
    %   Type                        type of characteristics, string scalar
    %   IsDirty                     flag if response needs to be computed, logical scalar
    %   Frequency                   frequency data of region
    %   UpperBoundaryMagnitude      upper magnitude data of region
    %   LowerBoundaryMagnitude      lower magnitude data of region
    %   UpperBoundaryPhase          upper phase data of region
    %   LowerBoundaryPhase          lower phase data of region
    %   IsValid                     flag if region is valid
    %   NumberOfStandardDeviations  number of standard deviations for confidence
    %   ConfidenceDisplaySampling   sample spacing for boundary computation
    %
    % Events:
    %   DataChanged             notified in update()
    %
    % Public methods:
    %   update(this,numberOfSD)
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
        IsValid
        NumberOfStandardDeviations
        Frequency
        UpperBoundaryMagnitude
        LowerBoundaryMagnitude
        UpperBoundaryPhase
        LowerBoundaryPhase
    end

    properties (Constant)
        ConfidenceDisplaySampling = 1
    end

    %% Constructor
    methods
        function this = BodeConfidenceRegionData(data,numberOfSD)
            arguments
                data
                numberOfSD = 1
            end
            this@controllib.chart.internal.data.characteristics.BaseCharacteristicData(data);
            this.Type = "ConfidenceRegion";
            this.NumberOfStandardDeviations = numberOfSD;
        end
    end

    %% Public methods
    methods
        function update(this,numberOfSD)
            arguments
                this controllib.chart.internal.data.characteristics.BodeConfidenceRegionData
                numberOfSD (1,1) double = this.NumberOfStandardDeviations
            end
            update@controllib.chart.internal.data.characteristics.BaseCharacteristicData(this);
            this.NumberOfStandardDeviations = numberOfSD;
        end

        function magFocus = computeMagnitudeFocus(this,frequencyFocuses,magnitudeScale)
            arguments
                this (1,1) controllib.chart.internal.data.characteristics.BodeConfidenceRegionData
                frequencyFocuses (:,:) cell
                magnitudeScale (1,1) string {mustBeMember(magnitudeScale,["linear","log"])}
            end
            magFocus = cell(1,this.ResponseData.NResponses);
            for ka = 1:this.ResponseData.NResponses
                magFocus{ka} = repmat({[NaN, NaN]},this.ResponseData.NOutputs,this.ResponseData.NInputs);
                if this.IsValid(ka)
                    for ko = 1:this.ResponseData.NOutputs
                        for ki = 1:this.ResponseData.NInputs
                            frequencyFocus = frequencyFocuses{ko,ki};

                            idx1 = find(this.Frequency{ka} >= frequencyFocus(1),1,'first');
                            idx2 = find(this.Frequency{ka} <= frequencyFocus(2),1,'last');

                            if isempty(idx1) || isempty(idx2)
                                continue; % data lies outside focus
                            end

                            if idx1 >= idx2
                                % focus lies between two data points
                                lower_mag_k = this.LowerBoundaryMagnitude{ka}([idx1 idx2],ko,ki);
                                lower_mag_k(isinf(lower_mag_k)) = NaN;
                                lower_mag_k(lower_mag_k < 0) = NaN;
                                upper_mag_k = this.UpperBoundaryMagnitude{ka}([idx1 idx2],ko,ki);
                                upper_mag_k(isinf(upper_mag_k)) = NaN;
                                upper_mag_k(upper_mag_k < 0) = NaN;
                                
                                magMin = min(lower_mag_k);
                                magMax = max(upper_mag_k);
                            else
                                % Get min and max of yData
                                lower_mag_k = this.LowerBoundaryMagnitude{ka}(idx1:idx2,ko,ki);
                                lower_mag_k(isinf(lower_mag_k)) = NaN;
                                lower_mag_k(lower_mag_k < 0) = NaN;
                                upper_mag_k = this.UpperBoundaryMagnitude{ka}(idx1:idx2,ko,ki);
                                upper_mag_k(isinf(upper_mag_k)) = NaN;
                                upper_mag_k(upper_mag_k < 0) = NaN;

                                [magMin, idxMin] = min(lower_mag_k);
                                [magMax, idxMax] = max(upper_mag_k);

                                % Check if first data point is minimum
                                if idxMin == 1 && idx1>1
                                    % Interpolate to get yDataFocus(1) when f = frequencyFocus(1)
                                    f = this.Frequency{ka}(idx1-1:idx1);
                                    y = this.LowerBoundaryMagnitude{ka}(idx1-1:idx1,ko,ki);
                                    magMin = interp1(f,y,frequencyFocus(1));
                                end

                                % Check if last data point is maximum
                                if idxMax == length(upper_mag_k) && idx2<length(this.Frequency{ka})
                                    % Interpolate to get yDataFocus(2) when f = frequencyFocus(2)
                                    f = this.Frequency{ka}(idx2:idx2+1);
                                    y = this.UpperBoundaryMagnitude{ka}(idx2:idx2+1,ko,ki);
                                    magMax = interp1(f,y,frequencyFocus(2));
                                end
                            end

                            % Check if value close to 0 (which results in error when
                            % converting setting axis limits)
                            if magnitudeScale == "log"
                                magMin = max([magMin, eps]);
                                magMax = max([magMax, eps]);
                            end

                            magFocus{ka}{ko,ki} = real([magMin,magMax]);
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
        end

        function phaseFocus = computePhaseFocus(this,frequencyFocuses,phaseWrapped,phaseMatched)
            arguments
                this (1,1) controllib.chart.internal.data.characteristics.BodeConfidenceRegionData
                frequencyFocuses (:,:) cell
                phaseWrapped (1,1) logical
                phaseMatched (1,1) logical
            end
            phaseFocus = cell(1,this.ResponseData.NResponses);
            for ka = 1:this.ResponseData.NResponses
                phaseFocus{ka} = repmat({[NaN, NaN]},this.ResponseData.NOutputs,this.ResponseData.NInputs);
                if this.IsValid(ka)
                    for ko = 1:this.ResponseData.NOutputs
                        for ki = 1:this.ResponseData.NInputs
                            frequencyFocus = frequencyFocuses{ko,ki};

                            idx1 = find(this.Frequency{ka} >= frequencyFocus(1),1,'first');
                            idx2 = find(this.Frequency{ka} <= frequencyFocus(2),1,'last');

                            if isempty(idx1) || isempty(idx2)
                                continue; % data lies outside focus
                            end

                            lowerPhase = this.LowerBoundaryPhase{ka}(:,ko,ki);
                            lowerPhase(isinf(lowerPhase)) = NaN;
                            upperPhase = this.UpperBoundaryPhase{ka}(:,ko,ki);
                            upperPhase(isinf(upperPhase)) = NaN;

                            phase = this.ResponseData.Phase{ka}(:,ko,ki);
                            if phaseWrapped && phaseMatched
                                phaseValue = this.ResponseData.WrappedAndMatchedPhase{ka}(:,ko,ki);
                            elseif phaseWrapped
                                phaseValue = this.ResponseData.WrappedPhase{ka}(:,ko,ki);
                            elseif phaseMatched
                                phaseValue = this.ResponseData.MatchedPhase{ka}(:,ko,ki);
                            else
                                phaseValue = phase;
                            end
                            for ii = 1:length(lowerPhase)
                                [~,idx] = min(abs(this.ResponseData.Frequency{ka} - this.Frequency{ka}(ii)));
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
                                    f = this.Frequency{ka}(idx1-1:idx1);
                                    y = lowerPhase(idx1-1:idx1);
                                    phaseMin = interp1(f,y,frequencyFocus(1));
                                end

                                % Check if last data point is maximum
                                if idxMax == length(upper_phase_k) && idx2<length(this.Frequency{ka})
                                    % Interpolate to get yDataFocus(2) when f = frequencyFocus(2)
                                    f = this.Frequency{ka}(idx2:idx2+1);
                                    y = upperPhase(idx2:idx2+1);
                                    phaseMax = interp1(f,y,frequencyFocus(2));
                                end
                            end

                            phaseFocus{ka}{ko,ki} = real([phaseMin,phaseMax]);
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
        end
    end

    %% Protected methods
    methods (Access = protected)
        function compute_(this)
            data = this.ResponseData;

            nOutputs = data.NOutputs;
            nInputs = data.NInputs;
            nArray = data.NResponses;

            this.Frequency = cell(1,nArray);
            this.UpperBoundaryMagnitude = cell(1,nArray);
            this.LowerBoundaryMagnitude = cell(1,nArray);
            this.UpperBoundaryPhase = cell(1,nArray);
            this.LowerBoundaryPhase = cell(1,nArray);

            for ka = 1:nArray
                % Get covariance magnitude and phase
                f = data.Frequency{ka}(1:this.ConfidenceDisplaySampling:end);
                [covarianceMagnitude,covariancePhase,frequencyForCovariance] = ...
                    getMagnitudePhaseCovarianceData_(data.ModelValue,f,ka);
                sdMagnitude = sqrt(covarianceMagnitude);
                sdPhase = sqrt(covariancePhase);

                dataMagnitude = this.ResponseData.Magnitude{ka};
                dataPhase = this.ResponseData.Phase{ka};
                
                % Store values
                if isempty(sdMagnitude)
                    this.IsValid(ka) = false;
                else
                    for ko = 1:nOutputs
                        for ki = 1:nInputs
                            thisMag = dataMagnitude(:,ko,ki);
                            thisPhase = dataPhase(:,ko,ki);
                            if ~isequal(frequencyForCovariance,f)
                                % Needs interp
                                thisSDMag = interp1(w0, squeeze(sdMagnitude(ko,ki,:)),f);
                                thisSDPhase = interp1(w0, squeeze(sdPhase(ko,ki,:)),f);
                            else
                                thisSDMag = squeeze(sdMagnitude(ko,ki,:));
                                thisSDPhase = squeeze(sdPhase(ko,ki,:));
                            end
                            
                            % Magnitude
                            magnitudeSD = this.NumberOfStandardDeviations*thisSDMag;
                            this.UpperBoundaryMagnitude{ka}(:,ko,ki) = thisMag + magnitudeSD;
                            this.LowerBoundaryMagnitude{ka}(:,ko,ki) = thisMag - magnitudeSD;
                            % Check for lower bound values less than zero.
                            % Do not include them in focus computation.
                            % zeroIdx = this.LowerBoundaryMagnitude{ka}(:,ko,ki) <= 0;
                            % this.LowerBoundaryMagnitude{ka}(zeroIdx,ko,ki) = NaN;
                            % Phase
                            phaseSD= this.NumberOfStandardDeviations*thisSDPhase;
                            this.UpperBoundaryPhase{ka}(:,ko,ki) = thisPhase + phaseSD;
                            this.LowerBoundaryPhase{ka}(:,ko,ki) = thisPhase - phaseSD;
                            
                            % Frequency
                            this.Frequency{ka} = f;
                        end
                    end
                    this.IsValid(ka) = true;
                end
            end
        end
    end
end
