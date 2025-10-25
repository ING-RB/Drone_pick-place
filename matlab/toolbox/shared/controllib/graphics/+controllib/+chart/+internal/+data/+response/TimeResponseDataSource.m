classdef TimeResponseDataSource < controllib.chart.internal.data.response.ModelResponseDataSource & ...
                                  controllib.chart.internal.data.response.TimeResponseData
    % controllib.chart.internal.data.response.TimeResponseDataSource
    %   - base class for managing source and data objects for given time response
    %   - inherited from controllib.chart.internal.data.response.ModelResponseDataSource
    %
    % h = TimeResponseDataSource()
    %
    % h = TimeResponseDataSource(_____,Name-Value)
    %   Time                   time specification used to generate data, [] (default) auto generates time specification
    %   Parameter              parameter specification used to generate data (only for lpvss models), [] (default)
    %   Config                 RespConfig object used to generate data
    %
    % Read-only properties:
    %   Type                  type of response for subclass, string
    %   ArrayDim              array dimensions of response data, double
    %   NResponses            number of elements of response data, double
    %   CharacteristicTypes   types of Characteristics, string
    %   Characteristics       characteristics of response data, controllib.chart.internal.data.characteristics.BaseCharacteristicData
    %   NInputs               number of inputs in Model, double
    %   NOutputs              number of outputs in Model, double
    %   IsDiscrete            logical value to specify if Model is discrete
    %   IsReal                logical array to specify if Model is real
    %   TimeUnit              time unit of Model, char
    %   Time                  time data of response, cell
    %   Amplitude             amplitude data of response, cell
    %   FinalValue            final value of respones, cell
    %   TimeFocus             time focus data of response, cell
    %   AmplitudeFocus        amplitude focus data of response, cell
    %   NData                 NResponses
    %   DataDimensions        [NOutputs NInputs]
    %   TimeInput             time specification used to generate data, double
    %   ParameterInput        parameter specification used to generate data, double or function_handle
    %   Config                RespConfig object used to generate data
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
    %   getCommonFocusForMultipleData(this,arrayVisible)
    %       Get time and amplitude focus values for an array of response data.
    %   getAmplitude(this,dataDimensionsIndex,seriesIndex)
    %       Get amplitude data at specified index.
    %   setAmplitude(this,amplitude,dataDimensionsIndex,seriesIndex)
    %       Set amplitude data at specified index.
    %   resetAmplitude(this)
    %       Reset amplitude data.
    %   getAmplitudeFocus(this,dataDimensionsIndex,arrayIndex)
    %       Get amplitude focus data at specified index.
    %   setAmplitudeFocus(this,amplitudeFocus,dataDimensionsIndex,arrayIndex)
    %       Set amplitude focus data at specified index.
    %   resetAmplitudeFocus(this)
    %       Reset amplitude focus data.
    %   getTime(this,dataDimensionsIndex,arrayIndex)
    %       Get time data at specified index.
    %   setTime(this,time,dataDimensionsIndex,arrayIndex)
    %       Set time data at specified index.
    %   resetTime(this)
    %       Reset time data.
    %   getTimeFocus(this,dataDimensionsIndex,arrayIndex)
    %       Get time focus data at specified index.
    %   setTimeFocus(this,timeFocus,dataDimensionsIndex,arrayIndex)
    %       Set time focus data at specified index.
    %   resetTimeFocus(this)
    %       Reset time focus data.
    %   getFinalValue(this,dataDimensionsIndex,arrayIndex)
    %       Get final value data at specified index.
    %   setFinalValue(this,finalValue,dataDimensionsIndex,arrayIndex)
    %       Set final value data at specified index.
    %   resetFinalValue(this)
    %       Reset final value data.
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
    %   computeAmplitudeFocus(this)
    %       Compute the amplitude focus.
    %   getAllIndices(this)
    %       Get all indices from DataDimensions.       
    %   getAllIndexCombinations(this)
    %       Get all index combinations from DataDimensions and NData.
    %
    % See Also:
    %   <a href="matlab:help controllib.chart.internal.data.response.ModelResponseDataSource">controllib.chart.internal.data.response.ModelResponseDataSource</a>
       
    %   Copyright 2021-2024 The MathWorks, Inc.

    %% Properties
    properties (SetAccess = protected)
        % "TimeInput": double vector
        % Time specification used to generate data.
        TimeInput
        % "ParameterInput": double array or function_handle
        % Parameter specification used to generate data.
        ParameterInput
        % "Config": double scalar
        % RespConfig object used to generate data.
        Config
    end

    %% Constructor
    methods
        function this = TimeResponseDataSource(model,timeResponseOptionalInputs)
            arguments
                model
                timeResponseOptionalInputs.Time = []
                timeResponseOptionalInputs.Parameter = []
                timeResponseOptionalInputs.Config = RespConfig
            end
            this@controllib.chart.internal.data.response.ModelResponseDataSource(model);
            this.NData = this.NResponses;
            this.DataDimensions = [this.NOutputs,this.NInputs];
            this.TimeInput = timeResponseOptionalInputs.Time;
            this.ParameterInput = timeResponseOptionalInputs.Parameter;
            this.Config = timeResponseOptionalInputs.Config;
            this.TimeUnit = this.Model.TimeUnit;
        end
    end

    %% Public methods
    methods
        function [commonTimeFocus, commonAmplitudeFocus, timeUnit] = getCommonFocusForMultipleData(this,arrayVisible,optionalInputs)
            arguments
                this (:,1) controllib.chart.internal.data.response.TimeResponseDataSource
                arrayVisible (:,1) cell = arrayfun(@(x) {true(x.NResponses,1)},this)
                optionalInputs.ShowRealImaginary = true
                optionalInputs.ShowMagnitude = false
            end
            nInputs = max([this.NInputs]);
            nOutputs = max([this.NOutputs]);
            commonTimeFocus = repmat({[NaN NaN]},nOutputs,nInputs);
            commonAmplitudeFocus = repmat({[NaN NaN]},nOutputs,nInputs);
            timeUnit = this(1).TimeUnit;

            for k = 1:length(this) % loop for number of data objects
                for ka = 1:this(k).NResponses % loop for system array
                    if arrayVisible{k}(ka)
                        for ko = 1:nOutputs % loop for outputs
                            for ki = 1:nInputs % loop for inputs
                                % Get output index based on plot output index
                                if ~isempty(this(k).PlotOutputIdx)
                                    ko_idx = find(this(k).PlotOutputIdx==ko,1);
                                elseif this(k).NOutputs <= ko
                                    ko_idx = ko;
                                else 
                                    ko_idx = [];
                                end

                                % Get input index based on plot input index
                                if ~isempty(this(k).PlotInputIdx)
                                    ki_idx = find(this(k).PlotInputIdx==ki,1);
                                elseif this(k).NInputs <= ki
                                    ki_idx = ki;
                                else 
                                    ki_idx = [];
                                end

                                if ~isempty(ko_idx) && ~isempty(ki_idx)
                                    % Time Focus
                                    cf = tunitconv(this(k).TimeUnit,timeUnit);
                                    timeFocus = cf*this(k).TimeFocus{ka}{ko_idx,ki_idx};
                                    commonTimeFocus{ko,ki}(1) = ...
                                        min(commonTimeFocus{ko,ki}(1),timeFocus(1));
                                    commonTimeFocus{ko_idx,ki}(2) = ...
                                        max(commonTimeFocus{ko,ki}(2),timeFocus(2));
                                    % Amplitude Focus
                                    amplitudeFocus = this(k).AmplitudeFocus{ka}{ko_idx,ki_idx};
                                    if amplitudeFocus(1) == amplitudeFocus(2)
                                        amplitudeFocus(1) = floor(amplitudeFocus(1));
                                        amplitudeFocus(2) = ceil(amplitudeFocus(2));
                                    end
                                    commonAmplitudeFocus{ko,ki}(1) = ...
                                        min(commonAmplitudeFocus{ko,ki}(1),amplitudeFocus(1));
                                    commonAmplitudeFocus{ko,ki}(2) = ...
                                        max(commonAmplitudeFocus{ko,ki}(2),amplitudeFocus(2));
                                end
                            end
                        end
                    end
                end
            end
        end

        function [commonRealAmplitudeFocus,commonImaginaryAmplitudeFocus] = getCommonRealImaginaryFocusForMultipleData(this,...
                                                                    arrayVisible)
            arguments
                this (:,1) controllib.chart.internal.data.response.TimeResponseDataSource
                arrayVisible (:,1) cell = arrayfun(@(x) {true(x.NResponses,1)},this)
            end
            nInputs = max([this.NInputs]);
            nOutputs = max([this.NOutputs]);
            commonRealAmplitudeFocus = repmat({[NaN NaN]},nOutputs,nInputs);
            commonImaginaryAmplitudeFocus = repmat({[NaN NaN]},nOutputs,nInputs);
            for k = 1:length(this) % loop for number of data objects
                for ka = 1:this(k).NResponses % loop for system array
                    if arrayVisible{k}(ka)
                        for ko = 1:nOutputs % loop for outputs
                            ko_idx = mapDataToPlotOutputIdx(this(k),ko);
                            for ki = 1:nInputs % loop for inputs
                                ki_idx = mapDataToPlotInputIdx(this(k),ki);
                                % Compute focus if plot i/o index is non empty
                                if ~isempty(ko_idx) && ~isempty(ki_idx)
                                    % Get amplitude focus for real and
                                    % imaginary signals
                                    [realAmplitudeFocus,imaginaryAmplitudeFocus] = getAmplitudeFocus(this(k),[ko_idx,ki_idx],ka);
                                    
                                    % Real Amplitude Focus
                                    if realAmplitudeFocus(1) == realAmplitudeFocus(2)
                                        realAmplitudeFocus(1) = floor(realAmplitudeFocus(1));
                                        realAmplitudeFocus(2) = ceil(realAmplitudeFocus(2));
                                    end
                                    commonRealAmplitudeFocus{ko,ki}(1) = ...
                                        min(commonRealAmplitudeFocus{ko,ki}(1),realAmplitudeFocus(1));
                                    commonRealAmplitudeFocus{ko,ki}(2) = ...
                                        max(commonRealAmplitudeFocus{ko,ki}(2),realAmplitudeFocus(2));

                                    % Imaginary Amplitude Focus
                                    if imaginaryAmplitudeFocus(1) == imaginaryAmplitudeFocus(2)
                                        imaginaryAmplitudeFocus(1) = floor(imaginaryAmplitudeFocus(1));
                                        imaginaryAmplitudeFocus(2) = ceil(imaginaryAmplitudeFocus(2));
                                    end
                                    commonImaginaryAmplitudeFocus{ko,ki}(1) = ...
                                        min(commonImaginaryAmplitudeFocus{ko,ki}(1),imaginaryAmplitudeFocus(1));
                                    commonImaginaryAmplitudeFocus{ko,ki}(2) = ...
                                        max(commonImaginaryAmplitudeFocus{ko,ki}(2),imaginaryAmplitudeFocus(2));
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
        function updateData(this,modelResponseOptionalInputs,timeResponseOptionalInputs)  
            arguments
                this (1,1) controllib.chart.internal.data.response.TimeResponseDataSource
                modelResponseOptionalInputs.Model = this.Model
                timeResponseOptionalInputs.Time = this.TimeInput
                timeResponseOptionalInputs.Parameter = this.ParameterInput
                timeResponseOptionalInputs.Config = this.Config
            end                  
            updateData@controllib.chart.internal.data.response.ModelResponseDataSource(this,Model=modelResponseOptionalInputs.Model);
            this.NData = this.NResponses;
            this.DataDimensions = [this.NOutputs,this.NInputs];
            this.TimeInput = timeResponseOptionalInputs.Time;
            this.ParameterInput = timeResponseOptionalInputs.Parameter;
            this.Config = timeResponseOptionalInputs.Config;
            this.TimeUnit = this.Model.TimeUnit;
        end
    end
end
