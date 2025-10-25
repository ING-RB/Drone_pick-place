classdef SigmaResponseDataSource < controllib.chart.internal.data.response.FrequencyResponseDataSource
    % controllib.chart.internal.data.response.SigmaResponseDataSource
    %   - manage source and data objects for given sigma response
    %   - inherited from controllib.chart.internal.data.response.FrequencyResponseDataSource
    %
    % h = SigmaResponseDataSource(model)
    %   model           DynamicSystem
    %
    % h = SigmaResponseDataSource(_____,Name-Value)
    %   Frequency               frequency specification used to generate data, [] (default) auto generates frequency specification
    %   SingularValueType       type of singular value response, 0 (default) plots the SV of H
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
    %   SingularValue               singular value data of response, cell
    %   SingularValueType           type of singular value response, double
    %   SigmaPeakResponse           peak response characteristic, controllib.chart.internal.data.characteristics.SigmaPeakResponseData
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
    %   getCommonFrequencyFocus(this,frequencyScale,arrayVisible)
    %       Get frequency focus values for an array of response data.
    %   getCommonSingularValueFocus(this,commonFrequencyFocus,magnitudeScale,arrayVisible)
    %       Get singular value focus values for an array of response data.
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
    %   computeSingularValueFocus(this,frequencyFocus,magnitudeScale)
    %       Compute the singular value focus. Called in getCommonSingularValueFocus().
    %
    % See Also:
    %   <a href="matlab:help
    %   controllib.chart.internal.data.response.FrequencyResponseDataSource">controllib.chart.internal.data.response.FrequencyResponseDataSource</a>

    % Copyright 2021-2024 The MathWorks, Inc.
    
    %% Properties
    properties (SetAccess = protected)
        % "SingularValue": cell vector
        % Singular values of response.
        SingularValue
        % "SingularValueType": double scalar
        % Type of singular value response.
        SingularValueType
    end
    
    properties (Dependent,SetAccess=private)
        % "SigmaPeakResponse": controllib.chart.internal.data.characteristics.SigmaPeakResponseData scalar
        % Peak response characteristic.
        SigmaPeakResponse
    end

    %% Constructor
    methods
        function this = SigmaResponseDataSource(model,sigmaResponseOptionalInputs,frequencyResponseOptionalInputs)
            arguments
                model
                sigmaResponseOptionalInputs.SingularValueType = 0;
                frequencyResponseOptionalInputs.Frequency = []
            end
            frequencyResponseOptionalInputs = namedargs2cell(frequencyResponseOptionalInputs);            
            this@controllib.chart.internal.data.response.FrequencyResponseDataSource(model,frequencyResponseOptionalInputs{:});
            this.Type = "SigmaResponse";
            this.SingularValueType = sigmaResponseOptionalInputs.SingularValueType;

            % Update response
            update(this);
        end
    end

    %% Public methods
    methods
        function [commonFrequencyFocus,frequencyUnit] = getCommonFrequencyFocus(this,frequencyScale,arrayVisible)
            arguments
                this (:,1) controllib.chart.internal.data.response.SigmaResponseDataSource
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

        function [commonSingularValueFocus,magnitudeUnit] = getCommonSingularValueFocus(this,commonFrequencyFocus,magnitudeScale,arrayVisible)
            arguments
                this (:,1) controllib.chart.internal.data.response.SigmaResponseDataSource
                commonFrequencyFocus (1,1) cell
                magnitudeScale (1,1) string {mustBeMember(magnitudeScale,["linear","log"])}
                arrayVisible (:,1) cell = arrayfun(@(x) {true(x.NResponses,1)},this)
            end
            commonSingularValueFocus = {[NaN,NaN]};
            magnitudeUnit = 'abs';
            for k = 1:length(this) % loop for number of data objects
                singularValueFocuses = computeSingularValueFocus(this(k),commonFrequencyFocus,magnitudeScale);
                for ka = 1:this(k).NResponses % loop for system array
                    % Singular Value Focus
                    if arrayVisible{k}(ka)
                        singularValueFocus = singularValueFocuses{ka};
                        commonSingularValueFocus{1}(1) = ...
                            min(commonSingularValueFocus{1}(1),singularValueFocus(1));
                        commonSingularValueFocus{1}(2) = ...
                            max(commonSingularValueFocus{1}(2),singularValueFocus(2));
                    end
                end
            end
        end
    end

    %% Get/Set methods
    methods
        % SigmaPeakResponse
        function SigmaPeakResponse = get.SigmaPeakResponse(this)
            arguments
                this (1,1) controllib.chart.internal.data.response.SigmaResponseDataSource
            end
            SigmaPeakResponse = getCharacteristics(this,"SigmaPeakResponse");
        end
    end

    %% Protected methods
    methods (Access = protected)
        function updateData(this,sigmaResponseOptionalInputs,frequencyResponseOptionalInputs)
            arguments
                this (1,1) controllib.chart.internal.data.response.SigmaResponseDataSource
                sigmaResponseOptionalInputs.SingularValueType = this.SingularValueType
                frequencyResponseOptionalInputs.Model = this.Model
                frequencyResponseOptionalInputs.Frequency = this.FrequencyInput
            end
            try
                sysList.System = frequencyResponseOptionalInputs.Model;
                ParamList = {frequencyResponseOptionalInputs.Frequency,sigmaResponseOptionalInputs.SingularValueType};
                [sysList,w,type] = DynamicSystem.checkSigmaInputs(sysList,ParamList);
                frequencyResponseOptionalInputs.Model = sysList.System;
                frequencyResponseOptionalInputs.Frequency = w;
                sigmaResponseOptionalInputs.SingularValueType = type;
                if isempty(sysList.System)
                    error(message('Controllib:plots:PlotEmptyModel'))
                end
            catch ME
                this.DataException = ME;
            end
            frequencyResponseOptionalInputs = namedargs2cell(frequencyResponseOptionalInputs);            
            updateData@controllib.chart.internal.data.response.FrequencyResponseDataSource(this,frequencyResponseOptionalInputs{:});
            this.SingularValueType = sigmaResponseOptionalInputs.SingularValueType;
            this.SingularValue = repmat({NaN(min(this.NInputs,this.NOutputs),1)},this.NResponses,1);
            this.Frequency = repmat({NaN},this.NResponses,1);
            this.FrequencyFocus = repmat({[NaN NaN]},this.NResponses,1);
            if ~isempty(this.DataException)
                return;
            end
            try
                for ka = 1:this.NResponses
                    [sv,w,focus] = getSingularValueData_(this.ModelValue,this.FrequencyInput,this.SingularValueType,...
                        ka);
                    this.SingularValue{ka} = sv;
                    this.Frequency{ka} = w;

                    % Round focus if frequency grid is automatically computed
                    roundedFocus = focus.Focus;
                    roundUpperFocus = false;
                    roundLowerFocus = false;
                    if isempty(this.FrequencyInput) 
                        roundUpperFocus = true;
                        roundLowerFocus = true;
                    elseif iscell(this.FrequencyInput)
                        if isinf(this.FrequencyInput{2})
                            roundUpperFocus = true;
                        else
                            roundedFocus(2) = this.FrequencyInput{2};
                        end
                        if this.FrequencyInput{1} == 0
                            roundLowerFocus = true;
                        else
                            roundedFocus(1) = this.FrequencyInput{1};
                        end
                    end
                    
                    if roundLowerFocus
                        roundedFocus(1) = 10^floor(log10(roundedFocus(1)));
                    end
                    if roundUpperFocus
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
                this (1,1) controllib.chart.internal.data.response.SigmaResponseDataSource
            end
            characteristics = controllib.chart.internal.data.characteristics.SigmaPeakResponseData(this);
        end

        function svFocus = computeSingularValueFocus(this,frequencyFocus,magnitudeScale)
            arguments
                this (1,1) controllib.chart.internal.data.response.SigmaResponseDataSource
                frequencyFocus (1,1) cell
                magnitudeScale (1,1) string {mustBeMember(magnitudeScale,["linear","log"])}
            end
            svFocus = cell(1,this.NResponses);
            for ka = 1:this.NResponses
                svFocus{ka} = [NaN, NaN];

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
                    sv_k = this.SingularValue{ka}(:,[idx1 idx2]);
                    sv_k(sv_k == 0) = NaN;
                    rowMinValues = min(sv_k,[],2);
                    rowMaxValues = max(sv_k,[],2);
                    svMin = min(rowMinValues);
                    svMax = max(rowMaxValues);
                else
                    % Get min and max of yData
                    sv_k = this.SingularValue{ka}(:,idx1:idx2);
                    sv_k(sv_k == 0) = NaN;

                    [rowMinValues, rowMinIdx] = min(sv_k,[],2);
                    [rowMaxValues, rowMaxIdx] = max(sv_k,[],2);

                    [svMin,rowIdxWithMinimumValue] = min(rowMinValues);
                    idxMin = rowMinIdx(rowIdxWithMinimumValue);

                    [svMax,rowIdxWithMaximumValue] = max(rowMaxValues);
                    idxMax = rowMaxIdx(rowIdxWithMaximumValue);

                    % Check if first data point is minimum
                    if idxMin == 1 && idx1>1
                        % Interpolate to get yDataFocus(1) when f = frequencyFocus(1)
                        f = this.Frequency{ka}(idx1-1:idx1);
                        y = this.SingularValue{ka}(rowIdxWithMinimumValue,idx1-1:idx1);
                        svMin = interp1(f,y,frequencyFocus{1}(1));
                    end

                    % Check if last data point is maximum
                    if idxMax == length(sv_k) && idx2<length(this.Frequency{ka})
                        % Interpolate to get yDataFocus(2) when f = frequencyFocus(2)
                        f = this.Frequency{ka}(idx2:idx2+1);
                        y = this.SingularValue{ka}(rowIdxWithMaximumValue,idx2:idx2+1);
                        svMax = interp1(f,y,frequencyFocus{1}(2));
                    end
                end
                
                % Check if value close to 0 (which results in error when
                % converting setting axis limits)
                if magnitudeScale == "log"
                    svMin = max([svMin, 1/realmax]);
                    svMax = max([svMax, 1/realmax]);
                end

                svFocus{ka} = [svMin,svMax];
                if (svFocus{ka}(1) == svFocus{ka}(2)) || any(isnan(svFocus{ka}))
                    value = svFocus{ka}(1);
                    if value == 0 || isnan(value)
                        svFocus{ka}(1) = 0.9;
                        svFocus{ka}(2) = 1.1;
                    else
                        absValue = abs(value);
                        svFocus{ka}(1) = value - 0.1*absValue;
                        svFocus{ka}(2) = value + 0.1*absValue;
                    end
                end                
            end
        end
    end
end
