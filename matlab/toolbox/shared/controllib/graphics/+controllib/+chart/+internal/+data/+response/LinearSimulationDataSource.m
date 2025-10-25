classdef LinearSimulationDataSource < controllib.chart.internal.data.response.TimeResponseDataSource
    % controllib.chart.internal.data.response.LinearSimulationDataSource
    %   - base class for managing source and data objects for given lsim response
    %   - inherited from controllib.chart.internal.data.response.TimeResponseDataSource
    %
    % h = LinearSimulationDataSource()
    %
    % h = LinearSimulationDataSource(_____,Name-Value)
    %   Time                         time specification used to generate data, [] (default) auto generates time specification
    %   Parameter                    parameter specification used to generate data (only for lpvss models), [] (default)
    %   Config                       RespConfig object used to generate data
    %   InputSignal                  input signal used to generate data
    %   InterpolationMethod          interpolation method used to generate data, "auto" (default) selects best method
    %
    % Read-only properties:
    %   Type                         type of response for subclass, string
    %   ArrayDim                     array dimensions of response data, double
    %   NResponses                   number of elements of response data, double
    %   CharacteristicTypes          types of Characteristics, string
    %   Characteristics              characteristics of response data, controllib.chart.internal.data.characteristics.BaseCharacteristicData
    %   NInputs                      number of inputs in Model, double
    %   NOutputs                     number of outputs in Model, double
    %   IsDiscrete                   logical value to specify if Model is discrete
    %   IsReal                       logical array to specify if Model is real
    %   TimeUnit                     time unit of Model, char
    %   Time                         time data of response, cell
    %   Amplitude                    amplitude data of response, cell
    %   FinalValue                   final value of respones, cell
    %   TimeFocus                    time focus data of response, cell
    %   AmplitudeFocus               amplitude focus data of response, cell
    %   NData                        NResponses
    %   DataDimensions               [NOutputs 1]
    %   TimeInput                    time specification used to generate data, double
    %   ParameterInput               parameter specification used to generate data, double or function_handle
    %   Config                       RespConfig object used to generate data
    %   InputSignal                  input signal used to generate data, double
    %   InterpolationMethod          interpolation method used to generate data, string
    %   PeakResponse                 peak response characteristic, controllib.chart.internal.data.characteristics.TimePeakResponseData
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
    %   <a href="matlab:help controllib.chart.internal.data.response.TimeResponseDataSource">controllib.chart.internal.data.response.TimeResponseDataSource</a>

    %   Copyright 2023-2024 The MathWorks, Inc.

    %% Properties
    properties (SetAccess=protected)
        % "InputSignal": double array
        % Input signals used to generate data.
        InputSignal
        % "InterpolationMethod": string scalar
        % Interpolation method between points in input signal.
        InterpolationMethod
    end

    properties (Dependent,SetAccess=private)
        % "PeakResponse": controllib.chart.internal.data.characteristics.TimePeakResponseData scalar
        % Peak response characteristic.
        PeakResponse
    end

    %% Constructor
    methods
        function this = LinearSimulationDataSource(model,lsimResponseOptionalArguments,timeResponseOptionalInputs)
            arguments
                model
                lsimResponseOptionalArguments.InputSignal = [];
                lsimResponseOptionalArguments.InterpolationMethod = "auto";
                timeResponseOptionalInputs.Time = []
                timeResponseOptionalInputs.Parameter = []
                timeResponseOptionalInputs.Config = RespConfig
            end
            timeResponseOptionalInputs = namedargs2cell(timeResponseOptionalInputs);
            this@controllib.chart.internal.data.response.TimeResponseDataSource(model,timeResponseOptionalInputs{:});
            this.DataDimensions = [this.NOutputs,1];

            this.InputSignal = lsimResponseOptionalArguments.InputSignal;
            this.InterpolationMethod = lsimResponseOptionalArguments.InterpolationMethod;
            this.Type = 'LSimResponse';

            % Update
            update(this);
        end
    end

    %% Public methods
    methods
        function [commonTimeFocus,commonAmplitudeFocus,timeUnit] = getCommonFocusForMultipleData(this,...
                InputVisible,arrayVisible,optionalInputs)
            arguments
                this (:,1) controllib.chart.internal.data.response.LinearSimulationDataSource
                InputVisible (1,1) logical
                arrayVisible (:,1) cell = arrayfun(@(x) {true(x.NResponses,1)},this)
                optionalInputs.ShowMagnitude = false
                optionalInputs.ShowReal = true
                optionalInputs.ShowImaginary = true;
            end
            nOutputs = max([this.NOutputs]);
            commonTimeFocus = repmat({[NaN NaN]},nOutputs,1);
            commonAmplitudeFocus = repmat({[NaN NaN]},nOutputs,1);
            commonImaginaryAmplitudeFocus = repmat({[NaN,NaN]},nOutputs,1);
            timeUnit = this(1).TimeUnit;
            for k = 1:length(this) % loop for number of data objects
                for ka = 1:this(k).NResponses % loop for system array
                    if arrayVisible{k}(ka)
                        for ko = 1:nOutputs % loop for outputs
                            ko_idx = mapDataToPlotOutputIdx(this(k),ko);
                            if ~isempty(ko_idx)
                                % Time Focus
                                cf = tunitconv(this(k).TimeUnit,timeUnit);
                                timeFocus = cf*this(k).TimeFocus{ka}{ko_idx};
                                commonTimeFocus{ko}(1) = ...
                                    min(commonTimeFocus{ko}(1),timeFocus(1));
                                commonTimeFocus{ko}(2) = ...
                                    max(commonTimeFocus{ko}(2),timeFocus(2));

                                % Get amplitude focus for real and
                                % imaginary signals
                                [realAmplitudeFocus,imaginaryAmplitudeFocus] = getAmplitudeFocus(this(k),[ko_idx,1],ka);

                                if ~this(k).IsReal(ka)
                                    % Signal is complex
                                    amplitudeFocus = [NaN,NaN];

                                    if optionalInputs.ShowReal
                                        % focus includes real and
                                        % imaginary signals
                                        amplitudeFocus = realAmplitudeFocus;
                                    end

                                    if optionalInputs.ShowImaginary
                                        amplitudeFocus = [min(amplitudeFocus(1),imaginaryAmplitudeFocus(1)),...
                                            max(amplitudeFocus(2),imaginaryAmplitudeFocus(2))];
                                    end

                                    if optionalInputs.ShowMagnitude
                                        % combine magnitude focus
                                        magnitudeFocus = getMagnitudeFocus(this(k),[ko_idx,1],ka);
                                        amplitudeFocus = [min(amplitudeFocus(1),magnitudeFocus(1)),...
                                            max(amplitudeFocus(2),magnitudeFocus(2))];
                                    end
                                else
                                    % signal is real
                                    amplitudeFocus = realAmplitudeFocus;
                                end

                                if amplitudeFocus(1) == amplitudeFocus(2)
                                    amplitudeFocus(1) = floor(amplitudeFocus(1));
                                    amplitudeFocus(2) = ceil(amplitudeFocus(2));
                                end
                                if isempty(this(k).InputSignal)
                                    amplitudeFocus(1) = NaN;
                                    amplitudeFocus(2) = NaN;
                                elseif InputVisible
                                    mininput = min(real(this(k).InputSignal),[],'all');
                                    maxinput = max(real(this(k).InputSignal),[],'all');
                                    amplitudeFocus(1) = min(amplitudeFocus(1),mininput);
                                    amplitudeFocus(2) = max(amplitudeFocus(2),maxinput);
                                end
                                commonAmplitudeFocus{ko}(1) = ...
                                    min(commonAmplitudeFocus{ko}(1),amplitudeFocus(1));
                                commonAmplitudeFocus{ko}(2) = ...
                                    max(commonAmplitudeFocus{ko}(2),amplitudeFocus(2));
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
            nOutputs = max([this.NOutputs]);
            commonRealAmplitudeFocus = repmat({[NaN NaN]},nOutputs,1);
            commonImaginaryAmplitudeFocus = repmat({[NaN NaN]},nOutputs,1);
            for k = 1:length(this) % loop for number of data objects
                for ka = 1:this(k).NResponses % loop for system array
                    if arrayVisible{k}(ka)
                        for ko = 1:nOutputs % loop for outputs
                            ko_idx = mapDataToPlotOutputIdx(this(k),ko);
                            % Compute focus if plot i/o index is non empty
                            if ~isempty(ko_idx)
                                % Get amplitude focus for real and
                                % imaginary signals
                                [realAmplitudeFocus,imaginaryAmplitudeFocus] = getAmplitudeFocus(this(k),[ko_idx,1],ka);

                                % Real Amplitude Focus
                                if realAmplitudeFocus(1) == realAmplitudeFocus(2)
                                    realAmplitudeFocus(1) = floor(realAmplitudeFocus(1));
                                    realAmplitudeFocus(2) = ceil(realAmplitudeFocus(2));
                                end
                                commonRealAmplitudeFocus{ko,1}(1) = ...
                                    min(commonRealAmplitudeFocus{ko,1}(1),realAmplitudeFocus(1));
                                commonRealAmplitudeFocus{ko,1}(2) = ...
                                    max(commonRealAmplitudeFocus{ko,1}(2),realAmplitudeFocus(2));

                                % Imaginary Amplitude Focus
                                if imaginaryAmplitudeFocus(1) == imaginaryAmplitudeFocus(2)
                                    imaginaryAmplitudeFocus(1) = floor(imaginaryAmplitudeFocus(1));
                                    imaginaryAmplitudeFocus(2) = ceil(imaginaryAmplitudeFocus(2));
                                end
                                commonImaginaryAmplitudeFocus{ko,1}(1) = ...
                                    min(commonImaginaryAmplitudeFocus{ko,1}(1),imaginaryAmplitudeFocus(1));
                                commonImaginaryAmplitudeFocus{ko,1}(2) = ...
                                    max(commonImaginaryAmplitudeFocus{ko,1}(2),imaginaryAmplitudeFocus(2));
                            end
                        end
                    end
                end
            end
        end
    end

    %% Get/Set methods
    methods
        function PeakResponse = get.PeakResponse(this)
            arguments
                this (1,1) controllib.chart.internal.data.response.LinearSimulationDataSource
            end
            PeakResponse = getCharacteristics(this,"PeakResponse");
        end
    end

    %% Protected methods
    methods (Access = protected)
        function updateData(this,lsimResponseOptionalArguments,timeResponseOptionalInputs)
            arguments
                this (1,1) controllib.chart.internal.data.response.LinearSimulationDataSource
                lsimResponseOptionalArguments.InputSignal = this.InputSignal;
                lsimResponseOptionalArguments.InterpolationMethod = this.InterpolationMethod;
                timeResponseOptionalInputs.Model = this.Model
                timeResponseOptionalInputs.Time = this.TimeInput
                timeResponseOptionalInputs.Parameter = this.ParameterInput
                timeResponseOptionalInputs.Config = this.Config
            end
            try
                sysList.System = timeResponseOptionalInputs.Model;
                ParamList = {lsimResponseOptionalArguments.InputSignal,timeResponseOptionalInputs.Time,timeResponseOptionalInputs.Config,timeResponseOptionalInputs.Parameter};
                if lsimResponseOptionalArguments.InterpolationMethod ~= "auto"
                    ParamList = [{lsimResponseOptionalArguments.InterpolationMethod},ParamList];
                end
                if isempty(timeResponseOptionalInputs.Time)
                    ParamList = {}; %case for lsimplot(sys)
                end
                [sysList,t,xinit,u,p,InterpRule] = DynamicSystem.checkLsimInputs(sysList,ParamList,true);
                timeResponseOptionalInputs.Model = sysList.System;
                timeResponseOptionalInputs.Time = t;
                timeResponseOptionalInputs.Parameter = p;
                if ~isempty(xinit)
                    timeResponseOptionalInputs.Config = xinit;
                end
                lsimResponseOptionalArguments.InputSignal = u;
                lsimResponseOptionalArguments.InterpolationMethod = InterpRule;
                if isempty(sysList.System)
                    error(message('Controllib:plots:PlotEmptyModel'))
                end
            catch ME
                this.DataException = ME;
            end
            timeResponseOptionalInputs = namedargs2cell(timeResponseOptionalInputs);
            updateData@controllib.chart.internal.data.response.TimeResponseDataSource(this,timeResponseOptionalInputs{:});
            this.DataDimensions = [this.NOutputs,1];
            this.InputSignal = lsimResponseOptionalArguments.InputSignal;
            this.InterpolationMethod = lsimResponseOptionalArguments.InterpolationMethod;
            resetAmplitude(this);
            resetTime(this);
            resetFinalValue(this);
            if ~isempty(this.DataException)
                return;
            end
            try
                if isempty(this.TimeInput)
                    t = [];
                else
                    t = this.TimeInput;
                end
                for ka = 1:this.NResponses
                    if isempty(this.InputSignal) || isempty(this.TimeInput)
                        setAmplitude(this,NaN,{1:this.NOutputs,1},ka);
                        setTime(this,NaN,{1:this.NOutputs,1},ka);
                        setTimeFocus(this,repmat(mat2cell([0 1],1,2),1,this.NOutputs),{1:this.NOutputs,1},ka);
                        setFinalValue(this,NaN,{1:this.NOutputs,1},ka);
                        continue;
                    end
                    yData = getSimulationData_(this.ModelValue,this.InputSignal,t,...
                        this.ParameterInput,this.Config,this.InterpolationMethod,ka);

                    xData = this.TimeInput;
                    focus = [this.TimeInput(1) this.TimeInput(end)];
                    setAmplitude(this,yData,{1:this.NOutputs,1},ka);
                    setTime(this,repmat(real(xData),1,this.NOutputs),{1:this.NOutputs,1},ka);
                    setTimeFocus(this,repmat(mat2cell(real(focus),1,2),this.NOutputs,1),...
                        {1:this.NOutputs,1},ka);
                    setFinalValue(this,yData(end),{1:this.NOutputs,1},ka);
                    setInitialValue(this,yData(1),{1:this.NOutputs,1},ka);
                end
                computeAmplitudeFocus(this);
            catch ME
                this.DataException = ME;
            end
        end

        function characteristics = createCharacteristics_(this)
            arguments
                this (1,1) controllib.chart.internal.data.response.LinearSimulationDataSource
            end
            characteristics = controllib.chart.internal.data.characteristics.TimePeakResponseData(this);
        end
    end
end
