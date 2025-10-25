classdef SectorBoundResponseDataSource < controllib.chart.internal.data.response.FrequencyResponseDataSource
    % controllib.chart.internal.data.response.SectorBoundResponseDataSource
    %   - manage source and data objects for given sector bound response
    %   - inherited from controllib.chart.internal.data.response.FrequencyResponseDataSource
    %
    % h = SectorBoundResponseDataSource(model)
    %   model           DynamicSystem
    %
    % h = SectorBoundResponseDataSource(_____,Name-Value)
    %   Frequency                   frequency specification used to generate data, [] (default) auto generates frequency specification
    %   BoundType             type of bound, "upper" (default) plots above response data
    %   Focus                 focus of Tuning Goal, [0 Inf] (default)
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
    %   RelativeIndex               relative index data of response, cell
    %   BoundType             type of bound, string
    %   Focus                 focus of Tuning Goal, double
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
    %   getCommonIndexFocus(this,commonFrequencyFocus,indexScale,arrayVisible)
    %       Get index focus values for an array of response data.
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
    %   computeIndexFocus(this,frequencyFocuses,indexScale)
    %       Compute the index focus. Called in getCommonIndexFocus().
    %
    % See Also:
    %   <a href="matlab:help controllib.chart.internal.data.response.FrequencyResponseDataSource">controllib.chart.internal.data.response.FrequencyResponseDataSource</a>
    
    % Copyright 2023-2024 The MathWorks, Inc.
    
    %% Properties
    properties (SetAccess = protected)
        % "RelativeIndex": cell vector
        % Relative index for response.
        RelativeIndex
        % "BoundType": string scalar
        % Type of response bound.
        BoundType
        % "Focus": 1x2 double
        % Frequency focus of Tuning Goal.
        Focus
    end

    %% Constructor
    methods
        function this = SectorBoundResponseDataSource(model,sectorBoundResponseOptionalInputs,frequencyResponseOptionalInputs)
            arguments
                model
                sectorBoundResponseOptionalInputs.BoundType = "upper"
                sectorBoundResponseOptionalInputs.Focus = [0 Inf]
                frequencyResponseOptionalInputs.Frequency = []
            end
            frequencyResponseOptionalInputs = namedargs2cell(frequencyResponseOptionalInputs);
            this@controllib.chart.internal.data.response.FrequencyResponseDataSource(model,frequencyResponseOptionalInputs{:});

            this.Type = "SectorBoundResponse";
            this.BoundType = sectorBoundResponseOptionalInputs.BoundType;
            this.Focus = sectorBoundResponseOptionalInputs.Focus;

            % Update response
            update(this);
        end
    end

    %% Public methods
    methods
        function [commonFrequencyFocus,frequencyUnit] = getCommonFrequencyFocus(this,frequencyScale,arrayVisible)
            arguments
                this (:,1) controllib.chart.internal.data.response.SectorBoundResponseDataSource
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

        function [commonIndexFocus,indexUnit] = getCommonIndexFocus(this,commonFrequencyFocus,indexScale,arrayVisible)
            arguments
                this (:,1) controllib.chart.internal.data.response.SectorBoundResponseDataSource
                commonFrequencyFocus (1,1) cell
                indexScale (1,1) string {mustBeMember(indexScale,["linear","log"])}
                arrayVisible (:,1) cell = arrayfun(@(x) {true(x.NResponses,1)},this)
            end
            commonIndexFocus = {[NaN,NaN]};
            indexUnit = 'abs';
            for k = 1:length(this) % loop for number of data objects
                indexFocuses = computeIndexFocus(this(k),commonFrequencyFocus,indexScale);
                for ka = 1:this(k).NResponses % loop for system array
                    % Index Focus
                    if arrayVisible{k}(ka)
                        indexFocus = indexFocuses{ka};
                        commonIndexFocus{1}(1) = ...
                            min(commonIndexFocus{1}(1),indexFocus(1));
                        commonIndexFocus{1}(2) = ...
                            max(commonIndexFocus{1}(2),indexFocus(2));
                    end
                end
            end
        end
    end

    %% Protected methods
    methods (Access = protected)
        function updateData(this,sectorBoundResponseOptionalInputs,frequencyResponseOptionalInputs)
            arguments
                this (1,1) controllib.chart.internal.data.response.SectorBoundResponseDataSource
                sectorBoundResponseOptionalInputs.BoundType = this.BoundType
                sectorBoundResponseOptionalInputs.Focus = this.Focus
                frequencyResponseOptionalInputs.Model = this.Model
                frequencyResponseOptionalInputs.Frequency = this.FrequencyInput
            end
            try
                sysList.System = frequencyResponseOptionalInputs.Model;
                ParamList = {frequencyResponseOptionalInputs.Frequency};
                [sysList,w] = DynamicSystem.checkSigmaInputs(sysList,ParamList);
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
            this.BoundType = sectorBoundResponseOptionalInputs.BoundType;
            this.Focus = sectorBoundResponseOptionalInputs.Focus;
            this.RelativeIndex = repmat({NaN(min(this.NInputs,this.NOutputs),1)},this.NResponses,1);
            this.Frequency = repmat({NaN},this.NResponses,1);
            this.FrequencyFocus = repmat({[NaN NaN]},this.NResponses,1);
            if ~isempty(this.DataException)
                return;
            end
            try
                for ka = 1:this.NResponses
                    [sv,w,focus] = getSingularValueData_(this.ModelValue,this.FrequencyInput,0,ka);
                    this.RelativeIndex{ka} = sv;
                    this.Frequency{ka} = w;
                    if this.Focus(1)>w(1) || this.Focus(2)<w(end)
                        % Clip and interpolate to show true edges
                        if this.Focus(1)>w(1)
                            w = [this.Focus(1) ; w(w>this.Focus(1),:,:)];
                        end
                        if this.Focus(2)<w(end)
                            w = [w(w<this.Focus(2),:,:) ; this.Focus(2)];
                        end
                        % Note: Use log-log interpolation to preserve slope of gain asymptotes
                        this.RelativeIndex{ka} = exp(utInterp1(log(this.Frequency{ka}),log(this.RelativeIndex{ka}),log(w')));
                        this.Frequency{ka} = w;
                    end
                    DataFocus = focus.Focus;

                    % Remove NaNs from focus
                    if any(isnan(DataFocus))
                        % Check if focus contains NaN
                        DataFocus = [1 10];
                    end

                    w = this.Frequency{ka};
                    wMin = w(1);
                    wMax = w(end);
                    Span = min(DataFocus(2)/DataFocus(1),wMax/wMin);
                    if DataFocus(1)<wMin
                        DataFocus = [wMin wMin*Span];  % Slide right
                    elseif DataFocus(2)>wMax
                        DataFocus = [wMax/Span wMax];  % Slide left
                    end

                    % Round focus if frequency grid is automatically computed
                    roundedFocus = DataFocus;
                    if isempty(this.FrequencyInput)
                        roundedFocus(1) = 10^floor(log10(roundedFocus(1)));
                        roundedFocus(2) = 10^ceil(log10(roundedFocus(2)));
                    end

                    % Remove NaNs from focus
                    if roundedFocus(1) >= roundedFocus(2)
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
        
        function indexFocus = computeIndexFocus(this,frequencyFocus,indexScale)
            arguments
                this (1,1) controllib.chart.internal.data.response.SectorBoundResponseDataSource
                frequencyFocus (1,1) cell
                indexScale (1,1) string {mustBeMember(indexScale,["linear","log"])}
            end
            indexFocus = cell(1,this.NResponses);
            for ka = 1:this.NResponses
                indexFocus{ka} = [NaN, NaN];

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
                    index_k = this.RelativeIndex{ka}(:,[idx1 idx2]);

                    if indexScale=="log"
                        index_k(index_k<=0) = NaN; %exclude non-positive data
                    end

                    rowMinValues = min(index_k,[],2);
                    rowMaxValues = max(index_k,[],2);
                    indexMin = min(rowMinValues);
                    indexMax = max(rowMaxValues);
                else
                    % Get min and max of yData
                    index_k = this.RelativeIndex{ka}(:,idx1:idx2);

                    if indexScale=="log"
                        index_k(index_k<=0) = NaN; %exclude non-positive data
                    end

                    [rowMinValues, rowMinIdx] = min(index_k,[],2);
                    [rowMaxValues, rowMaxIdx] = max(index_k,[],2);

                    [indexMin,rowIdxWithMinimumValue] = min(rowMinValues);
                    idxMin = rowMinIdx(rowIdxWithMinimumValue);

                    [indexMax,rowIdxWithMaximumValue] = max(rowMaxValues);
                    idxMax = rowMaxIdx(rowIdxWithMaximumValue);

                    % Check if first data point is minimum
                    if idxMin == 1 && idx1~=1
                        % Interpolate to get yDataFocus(1) when f = frequencyFocus(1)
                        f = this.Frequency{ka}(idx1-1:idx1);
                        y = this.RelativeIndex{ka}(rowIdxWithMinimumValue,idx1-1:idx1);
                        indexMin = interp1(f,y,frequencyFocus{1}(1));
                    end

                    % Check if last data point is maximum
                    if idxMax == length(index_k) && idx2~=length(this.Frequency{ka})
                        % Interpolate to get yDataFocus(2) when f = frequencyFocus(2)
                        f = this.Frequency{ka}(idx2:idx2+1);
                        y = this.RelativeIndex{ka}(rowIdxWithMaximumValue,idx2:idx2+1);
                        indexMax = interp1(f,y,frequencyFocus{1}(2));
                    end
                end
                
                % Check if value close to 0 (which results in error when
                % converting to dB and setting axis limits)
                if indexScale=="log"
                    indexMin = max([indexMin, eps]);
                    indexMax = max([indexMax, eps]);
                end

                indexFocus{ka} = [indexMin,indexMax];
                if (indexFocus{ka}(1) == indexFocus{ka}(2)) || any(isnan(indexFocus{ka}))
                    value = indexFocus{ka}(1);
                    if value == 0 || isnan(value)
                        indexFocus{ka}(1) = 0.9;
                        indexFocus{ka}(2) = 1.1;
                    else
                        absValue = abs(value);
                        indexFocus{ka}(1) = value - 0.1*absValue;
                        indexFocus{ka}(2) = value + 0.1*absValue;
                    end
                end                
            end
        end
    end
end
