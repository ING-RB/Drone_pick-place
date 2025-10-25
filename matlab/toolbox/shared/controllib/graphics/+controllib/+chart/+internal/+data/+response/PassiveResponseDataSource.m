classdef PassiveResponseDataSource < controllib.chart.internal.data.response.FrequencyResponseDataSource
    % controllib.chart.internal.data.response.PassiveResponseDataSource
    %   - manage source and data objects for given passive response
    %   - inherited from controllib.chart.internal.data.response.FrequencyResponseDataSource
    %
    % h = PassiveResponseDataSource(model)
    %   model           DynamicSystem
    %
    % h = PassiveResponseDataSource(_____,Name-Value)
    %   Frequency                   frequency specification used to generate data, [] (default) auto generates frequency specification
    %   PassiveType                 type of passive response to generate, "relative" (default)
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
    %   PassiveType                 type of passive response, string
    %   PassiveWorstIndexResponse   worst index characteristic, controllib.chart.internal.data.characteristics.PassiveWorstIndexResponseData
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
        % "PassiveType": string scalar
        % Type of passive response.
        PassiveType = "relative"
    end
    
    properties (Dependent, SetAccess=private)
        % "PassiveWorstIndexResponse": controllib.chart.internal.data.characteristics.PassiveWorstIndexResponseData scalar
        % Worst index response characteristic.
        PassiveWorstIndexResponse
    end

    %% Constructor
    methods
        function this = PassiveResponseDataSource(model,passiveResponseInputs,frequencyResponseOptionalInputs)
            arguments
                model
                passiveResponseInputs.PassiveType = "relative"
                frequencyResponseOptionalInputs.Frequency = []
            end           
            frequencyResponseOptionalInputs = namedargs2cell(frequencyResponseOptionalInputs);   
            this@controllib.chart.internal.data.response.FrequencyResponseDataSource(model,frequencyResponseOptionalInputs{:});
            this.Type = "PassiveResponse";
            this.PassiveType = passiveResponseInputs.PassiveType;

            % Update response
            update(this);
        end
    end

    %% Public methods
    methods
        function [commonFrequencyFocus,frequencyUnit] = getCommonFrequencyFocus(this,frequencyScale,arrayVisible)
            arguments
                this (:,1) controllib.chart.internal.data.response.PassiveResponseDataSource
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
                this (:,1) controllib.chart.internal.data.response.PassiveResponseDataSource
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

    %% Get/Set methods
    methods
        function PassiveWorstIndexResponse = get.PassiveWorstIndexResponse(this)
            arguments
                this (:,1) controllib.chart.internal.data.response.PassiveResponseDataSource
            end
            PassiveWorstIndexResponse = getCharacteristics(this,"PassiveWorstIndexResponse");
        end
    end

    %% Protected methods
    methods (Access = protected)
        function modelValue = getModelValue(this)
            if this.PassiveType=="io" || this.PassiveType=="relative"
                [~,nu] = iosize(this.Model);
                model = [this.Model;eye(nu)]; % Pass [H;I]
            else
                model = this.Model;
            end
            modelValue = getValue(model,'usample');
        end
        
        function updateData(this,passiveResponseInputs,frequencyResponseOptionalInputs)
            arguments
                this (1,1) controllib.chart.internal.data.response.PassiveResponseDataSource
                passiveResponseInputs.PassiveType = this.PassiveType
                frequencyResponseOptionalInputs.Frequency = this.FrequencyInput
                frequencyResponseOptionalInputs.Model = this.Model
            end
            try
                sysList.System = frequencyResponseOptionalInputs.Model;
                ParamList = {frequencyResponseOptionalInputs.Frequency};
                switch passiveResponseInputs.PassiveType
                    case 'input'
                        type = 1;
                    case 'output'
                        type = 2;
                    case 'io'
                        type = 3;
                    case 'relative'
                        type = 4;
                end
                [sysList,M0,W1,W2,w] = DynamicSystem.checkPassivityInputs(sysList,ParamList,type);
                frequencyResponseOptionalInputs.Model = sysList.System;
                frequencyResponseOptionalInputs.Frequency = w;
                if isempty(sysList.System)
                    error(message('Controllib:plots:PlotEmptyModel'))
                end
            catch ME
                this.DataException = ME;
            end   
            this.PassiveType = passiveResponseInputs.PassiveType; 
            frequencyResponseOptionalInputs = namedargs2cell(frequencyResponseOptionalInputs);            
            updateData@controllib.chart.internal.data.response.FrequencyResponseDataSource(this,frequencyResponseOptionalInputs{:});
            this.RelativeIndex = repmat({NaN(min(this.NInputs,this.NOutputs),1)},this.NResponses,1);
            this.Frequency = repmat({NaN},this.NResponses,1);
            this.FrequencyFocus = repmat({[NaN NaN]},this.NResponses,1);
            if ~isempty(this.DataException)
                return;
            end
            try
                anyInf = false;
                for ka = 1:this.NResponses
                    switch this.PassiveType
                        case 'input'
                            [ind,w,focus,isInf] = ifpofpresp(this.ModelData(ka),1,this.FrequencyInput,true);
                        case 'output'
                            [ind,w,focus,isInf] = ifpofpresp(this.ModelData(ka),2,this.FrequencyInput,true);
                        case 'io'
                            [ind,w,focus,isInf] = sectorresp(this.ModelData(ka),M0,W1,W2,this.FrequencyInput,true);
                            R = ind(1,:);
                            ind = 0.5*(1-R.^2)./(1+R.^2);
                            ind(isinf(R)) = -0.5;
                        case 'relative'
                            [ind,w,focus,isInf] = sectorresp(this.ModelData(ka),M0,W1,W2,this.FrequencyInput,true);
                    end
                    if isInf
                        anyInf = true;
                        continue;
                    end
                    this.RelativeIndex{ka} = ind;
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
                if anyInf
                    error(message('Control:analysis:sectorplot4'));
                end
            catch ME
                this.DataException = ME;
            end
        end

        function characteristics = createCharacteristics_(this)
            % Create objects for characteristic data (will update dynamically on demand)
            arguments
                this (1,1) controllib.chart.internal.data.response.PassiveResponseDataSource
            end
            characteristics = controllib.chart.internal.data.characteristics.PassiveWorstIndexData(this);
        end
        
        function indexFocus = computeIndexFocus(this,frequencyFocus,indexScale)
            arguments
                this (1,1) controllib.chart.internal.data.response.PassiveResponseDataSource
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
