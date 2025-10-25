classdef NyquistResponseDataSource < controllib.chart.internal.data.response.FrequencyResponseDataSource
    % controllib.chart.internal.data.response.NyquistResponseDataSource
    %   - manage source and data objects for given nyquist response
    %   - inherited from controllib.chart.internal.data.response.FrequencyResponseDataSource
    %
    % h = NyquistResponseDataSource(model)
    %   model           DynamicSystem
    %
    % h = NyquistResponseDataSource(_____,Name-Value)
    %   Frequency             frequency specification used to generate data, [] (default) auto generates frequency specification
    %   NumberOfStandardDeviations  number of SDs for confidence region, 1 (default)
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
    %   PositiveFrequency           positive frequency data of response, cell
    %   PositiveFrequencyResponse   complex data of response, cell
    %   NegativeFrequency           negative frequency data of response, cell
    %   NegativeFrequencyResponse   conjugate complex data of response, cell
    %   NyquistPeakResponse         peak response characteristic, controllib.chart.internal.data.characteristics.FrequencyPeakResponseData
    %   AllStabilityMargin          all stability margin characteristic (only for siso), controllib.chart.internal.data.characteristics.FrequencyAllStabilityMarginData
    %   MinimumStabilityMargin      min stability margin characteristic (only for siso), controllib.chart.internal.data.characteristics.FrequencyMinimumStabilityMarginData
    %   ConfidenceRegion            confidence region characteristic (only for ident), controllib.chart.internal.data.characteristics.NyquistConfidenceRegionData
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
    %   getCommonFocusForMultipleData(this,ShowFullContour,arrayVisible)
    %       Get real and imaginary focus values for an array of response data.
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
    %   computeFocuses(this,ShowFullContour)
    %       Compute the real and imaginary focuses. Called in getCommonFocusForMultipleData().
    %
    % See Also:
    %   <a href="matlab:help controllib.chart.internal.data.response.FrequencyResponseDataSource">controllib.chart.internal.data.response.FrequencyResponseDataSource</a>

    % Copyright 2022-2024 The MathWorks, Inc.

    %% Properties
    properties (GetAccess = public, SetAccess = private)
        % "Magnitude": cell vector
        % Magnitude for response.
        Magnitude
        % "Phase": cell vector
        % Phase for response.
        Phase        
        % "PositiveFrequency": cell vector
        % Positive frequency for response.
        PositiveFrequency
        % "PositiveFrequencyResponse": cell vector
        % Complex values for response.
        PositiveFrequencyResponse
        % "NegativeFrequency": cell vector
        % Negative frequency for response.
        NegativeFrequency
        % "NegativeFrequencyResponse": cell vector
        % Conjugate complex values for response.
        NegativeFrequencyResponse
        % "NumberOfStandardDeviations": double scalar
        % Number of standard deviations for confidence region.
        NumberOfStandardDeviations
        % "ConfidenceDisplaySampling": double scalar
        % Display spacing for confidence region.
        ConfidenceDisplaySampling
    end

    properties (Dependent)
        % "NyquistPeakResponse": controllib.chart.internal.data.characteristics.FrequencyPeakResponseData scalar
        % Peak response characteristic.
        NyquistPeakResponse   
        % "AllStabilityMargin": controllib.chart.internal.data.characteristics.FrequencyAllStabilityMarginData scalar
        % All stability margin characteristic. 
        AllStabilityMargin 
        % "MinimumStabilityMargin": controllib.chart.internal.data.characteristics.FrequencyMinimumStabilityMarginData scalar
        % Minimum stability margin characteristic.
        MinimumStabilityMargin
        % "ConfidenceRegion": controllib.chart.internal.data.characteristics.NyquistConfidenceRegionData scalar
        % Confidence region characteristic.
        ConfidenceRegion
    end
    
    %% Constructor
    methods
        function this = NyquistResponseDataSource(model,nyquistResponseOptionalArguments,frequencyResponseOptionalInputs)
            arguments
                model
                nyquistResponseOptionalArguments.NumberOfStandardDeviations = 1
                nyquistResponseOptionalArguments.ConfidenceDisplaySampling = 5
                frequencyResponseOptionalInputs.Frequency = []
            end
            frequencyResponseOptionalInputs = namedargs2cell(frequencyResponseOptionalInputs);            
            this@controllib.chart.internal.data.response.FrequencyResponseDataSource(model,frequencyResponseOptionalInputs{:});
            this.Type = "NyquistResponse";
            this.NumberOfStandardDeviations = nyquistResponseOptionalArguments.NumberOfStandardDeviations;
            this.ConfidenceDisplaySampling = nyquistResponseOptionalArguments.ConfidenceDisplaySampling;
            
            % Update response
            update(this);
        end
    end

    %% Public methods
    methods
        function [commonRealAxisFocus,commonImaginaryAxisFocus] = getCommonFocusForMultipleData(this,ShowFullContour,ZoomCP,arrayVisible)
            arguments
                this (:,1) controllib.chart.internal.data.response.NyquistResponseDataSource
                ShowFullContour (1,1) logical
                ZoomCP (1,1) logical
                arrayVisible (:,1) cell = arrayfun(@(x) {true(x.NResponses,1)},this)
            end
            nInputs = max([this.NInputs]);
            nOutputs = max([this.NOutputs]);

            commonRealAxisFocus = repmat({[NaN,NaN]},nOutputs,nInputs);
            commonImaginaryAxisFocus = repmat({[NaN,NaN]},nOutputs,nInputs);

            for k = 1:length(this) % loop for number of data objects
                [realAxisFocus,imaginaryAxisFocus] = computeFocuses(this(k),ShowFullContour,ZoomCP);
                for ka = 1:this(k).NResponses % loop for system array
                    if arrayVisible{k}(ka)
                        for ko = 1:this(k).NOutputs % loop for outputs
                            ko_idx = mapDataToPlotOutputIdx(this(k),ko);
                            for ki = 1:this(k).NInputs % loop for inputs
                                ki_idx = mapDataToPlotInputIdx(this(k),ki);
                                % Compute focus if plot i/o index are
                                % non-empty
                                if ~isempty(ko_idx) && ~isempty(ki_idx)
                                    % Real Axis Focus
                                    commonRealAxisFocus{ko,ki}(1) = ...
                                        min(commonRealAxisFocus{ko,ki}(1),realAxisFocus{ka}{ko_idx,ki_idx}(1));
                                    commonRealAxisFocus{ko,ki}(2) = ...
                                        max(commonRealAxisFocus{ko,ki}(2),realAxisFocus{ka}{ko_idx,ki_idx}(2));

                                    % Imaginary Axis Focus
                                    commonImaginaryAxisFocus{ko,ki}(1) = ...
                                        min(commonImaginaryAxisFocus{ko,ki}(1),imaginaryAxisFocus{ka}{ko_idx,ki_idx}(1));
                                    commonImaginaryAxisFocus{ko,ki}(2) = ...
                                        max(commonImaginaryAxisFocus{ko,ki}(2),imaginaryAxisFocus{ka}{ko_idx,ki_idx}(2));
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
        % NyquistPeakResponse
        function NyquistPeakResponse = get.NyquistPeakResponse(this)
            arguments
                this (1,1) controllib.chart.internal.data.response.NyquistResponseDataSource
            end
            NyquistPeakResponse = getCharacteristics(this,"FrequencyPeakResponse");
        end

        % AllStabilityMargin
        function AllStabilityMargin = get.AllStabilityMargin(this)
            arguments
                this (1,1) controllib.chart.internal.data.response.NyquistResponseDataSource
            end
            AllStabilityMargin = getCharacteristics(this,"AllStabilityMargins");
        end

        % MinimumStabilityMargin
        function MinimumStabilityMargin = get.MinimumStabilityMargin(this)
            arguments
                this (1,1) controllib.chart.internal.data.response.NyquistResponseDataSource
            end
            MinimumStabilityMargin = getCharacteristics(this,"MinimumStabilityMargins");
        end

        % ConfidenceRegion
        function ConfidenceRegion = get.ConfidenceRegion(this)
            arguments
                this (1,1) controllib.chart.internal.data.response.NyquistResponseDataSource
            end
            ConfidenceRegion = getCharacteristics(this,"ConfidenceRegion");
        end

        % NumberOfStandardDeviations
        function set.NumberOfStandardDeviations(this,NumberOfStandardDeviations)
            arguments
                this (1,1) controllib.chart.internal.data.response.NyquistResponseDataSource
                NumberOfStandardDeviations
            end
            this.NumberOfStandardDeviations = NumberOfStandardDeviations;
            if ~isempty(this.ConfidenceRegion) %#ok<MCSUP>
                update(this.ConfidenceRegion,NumberOfStandardDeviations,this.ConfidenceDisplaySampling); %#ok<MCSUP>
            end
        end
        
        % DisplaySpacing
        function set.ConfidenceDisplaySampling(this,ConfidenceDisplaySampling)
            arguments
                this (1,1) controllib.chart.internal.data.response.NyquistResponseDataSource
                ConfidenceDisplaySampling
            end
            this.ConfidenceDisplaySampling = ConfidenceDisplaySampling;
            if ~isempty(this.ConfidenceRegion) %#ok<MCSUP>
                update(this.ConfidenceRegion,this.NumberOfStandardDeviations,ConfidenceDisplaySampling); %#ok<MCSUP>
            end
        end
    end

    %% Protected methods
    methods (Access = protected)
        function updateData(this,nyquistResponseOptionalArguments,frequencyResponseOptionalInputs)
            arguments
                this (1,1) controllib.chart.internal.data.response.NyquistResponseDataSource
                nyquistResponseOptionalArguments.NumberOfStandardDeviations = this.NumberOfStandardDeviations
                nyquistResponseOptionalArguments.ConfidenceDisplaySampling = this.ConfidenceDisplaySampling
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
            this.NumberOfStandardDeviations = nyquistResponseOptionalArguments.NumberOfStandardDeviations;
            this.ConfidenceDisplaySampling = nyquistResponseOptionalArguments.ConfidenceDisplaySampling;
            this.Magnitude = repmat({NaN(this.NOutputs,this.NInputs)},this.NResponses,1);
            this.Phase = repmat({NaN(this.NOutputs,this.NInputs)},this.NResponses,1);
            this.Frequency = repmat({NaN},this.NResponses,1);
            this.PositiveFrequency = repmat({NaN},this.NResponses,1);
            this.NegativeFrequency = repmat({NaN},this.NResponses,1);
            this.PositiveFrequencyResponse = repmat({NaN(this.NOutputs,this.NInputs)},this.NResponses,1);
            this.NegativeFrequencyResponse = repmat({NaN(this.NOutputs,this.NInputs)},this.NResponses,1);
            focus = repmat({[NaN NaN]},this.NOutputs,this.NInputs);
            this.FrequencyFocus = repmat({focus},this.NResponses,1);
            if ~isempty(this.DataException)
                return;
            end
            try
                for ka = 1:this.NResponses
                    [mag,phase,w,focus] = getMagPhaseData_(this.ModelValue,...
                                                this.FrequencyInput,"nyquist",ka);
                    if size(mag,3) == 0 %idnlmodel idpoly
                        mag = NaN(size(mag,1),size(mag,2),1);
                        phase = NaN(size(phase,1),size(phase,2),1);
                    end
                    this.Magnitude{ka} = mag;
                    this.Phase{ka} = phase;
                    this.Frequency{ka} = w;

                    this.PositiveFrequency{ka} = w(:);
                    this.PositiveFrequencyResponse{ka} = mag .* exp(1i*phase);

                    this.NegativeFrequency{ka} = -flipud(this.PositiveFrequency{ka});
                    this.NegativeFrequencyResponse{ka} = conj(flipud(this.PositiveFrequencyResponse{ka}));

                    % FrequencyFocus
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
            catch ME
                this.DataException = ME;
            end
        end
    
        function characteristics = createCharacteristics_(this)
            arguments
                this (1,1) controllib.chart.internal.data.response.NyquistResponseDataSource
            end
            characteristics = controllib.chart.internal.data.characteristics.FrequencyPeakResponseData(this);
            if this.NInputs == 1 && this.NOutputs == 1
                c1 = controllib.chart.internal.data.characteristics.FrequencyAllStabilityMarginData(this);
                c2 = controllib.chart.internal.data.characteristics.FrequencyMinimumStabilityMarginData(this);
                characteristics = [characteristics,c1,c2];
            end
            % Create confidence region data if applicable
            if isa(this.Model,'idlti')
                c = controllib.chart.internal.data.characteristics.NyquistConfidenceRegionData(this,...
                    this.NumberOfStandardDeviations,this.ConfidenceDisplaySampling);
                characteristics = [characteristics,c];
            end
        end

        function [realAxisFocus,imaginaryAxisFocus] = computeFocuses(this,ShowFullContour,ZoomCP)
            arguments
                this (1,1) controllib.chart.internal.data.response.NyquistResponseDataSource
                ShowFullContour (1,1) logical
                ZoomCP (1,1) logical
            end                
            realAxisFocus = cell(1,this.NResponses);
            imaginaryAxisFocus = cell(1,this.NResponses);
            for ka = 1:this.NResponses
                realAxisFocus{ka} = cell(this.NOutputs,this.NInputs);
                imaginaryAxisFocus{ka} = cell(this.NOutputs,this.NInputs);
                for ko = 1:this.NOutputs
                    for ki = 1:this.NInputs
                        pr = this.PositiveFrequencyResponse{ka}(:,ko,ki);
                        nr = this.NegativeFrequencyResponse{ka}(:,ko,ki);
                        pf = this.PositiveFrequency{ka};
                        nf = this.NegativeFrequency{ka};
                        ff = this.FrequencyFocus{ka}{ko,ki};
                        
                        if ZoomCP
                            distp = abs(1+pr);
                            maxValp = max(4,1.5*min(abs(1+pr)));
                            pind = distp <= maxValp;
                            pr = pr(pind);
                            pf = pf(pind);
                            if ShowFullContour
                                distn = abs(1+nr);
                                maxValn = max(4,1.5*min(abs(1+nr)));
                                nind = distn <= maxValn;
                                nr = nr(nind);
                                nf = nf(nind);
                            end
                        end

                        positiveResponseRealFocus = this.computeResponseFocus(...
                            real(pr),pf,ff);
                        if ShowFullContour
                            negativeResponseRealFocus = this.computeResponseFocus(...
                                real(nr),nf,-fliplr(ff));
                        else
                            negativeResponseRealFocus = [NaN NaN];
                        end
                        realFocus = [min([positiveResponseRealFocus(1) negativeResponseRealFocus(1) -1]),...
                            max([positiveResponseRealFocus(2) negativeResponseRealFocus(2) -1])];
                        if (realFocus(1) == realFocus(2)) || any(isnan(realFocus))
                            value = realFocus(1);
                            if value == 0 || isnan(value)
                                realFocus(1) = -1;
                                realFocus(2) = 1;
                            else
                                absValue = abs(value);
                                realFocus(1) = value - 0.1*absValue;
                                realFocus(2) = value + 0.1*absValue;
                            end
                        end
                        realAxisFocus{ka}{ko,ki} = realFocus;

                        positiveResponseImagFocus = this.computeResponseFocus(...
                            imag(pr),pf,ff);
                        if ShowFullContour
                            negativeResponseImagFocus = this.computeResponseFocus(...
                                imag(nr),nf,-fliplr(ff));
                        else
                            negativeResponseImagFocus = [NaN NaN];
                        end
                        imagFocus = [min(positiveResponseImagFocus(1),negativeResponseImagFocus(1)),...
                            max(positiveResponseImagFocus(2),negativeResponseImagFocus(2))];
                        if (imagFocus(1) == imagFocus(2)) || any(isnan(imagFocus))
                            value = imagFocus(1);
                            if value == 0 || isnan(value)
                                imagFocus(1) = -1;
                                imagFocus(2) = 1;
                            else
                                absValue = abs(value);
                                imagFocus(1) = value - 0.1*absValue;
                                imagFocus(2) = value + 0.1*absValue;
                            end
                        end
                        imaginaryAxisFocus{ka}{ko,ki} = imagFocus;
                    end
                end
            end
        end
    end

    %% Static private methods
    methods (Static,Access=private)
        function focus = computeResponseFocus(yData,frequencyData,frequencyFocus)
            arguments
                yData (:,1) double
                frequencyData (:,1) double
                frequencyFocus (1,2) double
            end
            focus = [NaN NaN];
            idx1 = find(frequencyData >= frequencyFocus(1),1,'first');
            idx2 = find(frequencyData <= frequencyFocus(2),1,'last');

            if isempty(idx1) || isempty(idx2)
                return; % data lies outside focus
            end

            if idx1 >= idx2
                % focus lies between two data points
                values = yData([idx1 idx2]);
                focus = [min(values) max(values)];
            else
                values = yData(idx1:idx2);

                [valueMin, idxMin] = min(values);
                [valueMax, idxMax] = max(values);

                % Check if first data point is minimum
                if idxMin == 1 && idx1>1
                    % Interpolate to get yDataFocus(1) when f = frequencyFocus(1)
                    f = frequencyData(idx1-1:idx1);
                    y = yData(idx1-1:idx1);
                    valueMin = interp1(f,y,frequencyFocus(1));
                end

                % Check if last data point is maximum
                if idxMax == length(values) && idx2<length(frequencyData)
                    % Interpolate to get yDataFocus(2) when f = frequencyFocus(2)
                    f = frequencyData(idx2:idx2+1);
                    y = yData(idx2:idx2+1);
                    valueMax = interp1(f,y,frequencyFocus(2));
                end

                focus = [valueMin valueMax];
            end
        end
    end
end