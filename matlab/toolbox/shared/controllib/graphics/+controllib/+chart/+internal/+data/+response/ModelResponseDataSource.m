classdef ModelResponseDataSource < controllib.chart.internal.data.response.BaseResponseDataSource
    % controllib.chart.internal.data.response.ModelResponseDataSource
    %   - base class for managing source and data objects for given model response
    %   - inherited from controllib.chart.internal.data.response.BaseResponseDataSource
    %
    % h = ModelResponseDataSource(model)
    %   model           DynamicSystem
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
    %
    % See Also:
    %   <a href="matlab:help controllib.chart.internal.data.response.BaseResponseDataSource">controllib.chart.internal.data.response.BaseResponseDataSource</a>

    % Copyright 2022-2024 The MathWorks, Inc.
    
    properties (SetAccess=protected,NonCopyable)
        % "ModelSource": resppack.ltisource scalar
        % Plot source generated from Model.
        ModelSource
    end

    properties (GetAccess={?controllib.chart.internal.data.response.ModelResponseDataSource,...
                           ?controllib.chart.internal.data.characteristics.BaseCharacteristicData},...
                SetAccess=private)
        ModelValue
    end

    properties (SetAccess=protected,Dependent) % read-only, dependent on model
        % "ModelData": (ssdata,tfdata,...) scalar
        % Data source generated from ModelSource.
        ModelData
    end

    properties (Dependent, SetAccess = private)
        % "NInputs": double scalar
        % Number of inputs for Model.
        NInputs
        % "NOutputs": double scalar
        % Number of outputs for Model.
        NOutputs
        % "IsDiscrete": logical scalar
        % Gets if ModelData is discrete or not.
        IsDiscrete
        % "IsReal": logical array
        % Gets if ModelData is real or not.
        IsReal
        % "IsStatic": logical array
        % Gets if Model is static or not
        IsStatic
    end

    properties (SetAccess=protected,...
                GetAccess={?controllib.chart.internal.data.response.ModelResponseDataSource,...
                           ?qe.sharedcontrol.chart.ModelResponseDataSourceVerification})
        % "Model": DynamicSystem
        % Dynamic system object used to plot response and characteristics.
        Model
    end
    
    %% Constructor
    methods
        function this = ModelResponseDataSource(model)
            arguments
                model
            end
            this@controllib.chart.internal.data.response.BaseResponseDataSource(); 
            this.Type = "ModelResponse";
            updateModelDataAndSource(this,model)
        end
    end

    methods (Access = protected)
       function sz = getCommonResponseSize(thisArray)
          nInputs = max([thisArray.NInputs]);
          nOutputs = max([thisArray.NOutputs]);
          sz = [nOutputs, nInputs];
       end
    end

    %% Get/Set
    methods
        % NOutputs
        function NOutputs = get.NOutputs(this)
            if isa(this.Model,'idnlmodel') || isa(this.Model,'idpoly')
                [~,OutputNames] = mrgios(this.Model);
                NOutputs = length(OutputNames);
            else
                [NOutputs,~] = iosize(this.Model);
            end
        end

        % NInputs
        function NInputs = get.NInputs(this)
            if isa(this.Model,'idnlmodel') || isa(this.Model,'idpoly')
                [InputNames,~] = mrgios(this.Model);
                NInputs = length(InputNames);
            else
                [~,NInputs] = iosize(this.Model);
            end
        end

        % IsDiscrete
        function IsDiscrete = get.IsDiscrete(this)
            IsDiscrete = this.ModelValue.Ts ~= 0;
        end

        % IsReal
        function IsReal = get.IsReal(this)
            IsReal = getIsReal_(this);
        end

        % IsStatic
        function IsStatic = get.IsStatic(this)
            IsStatic = isstatic(this.Model);
        end

        % ModelData
        function ModelData = get.ModelData(this)
            ModelData = getModelData(this);
        end
    end

    methods (Hidden)
        function Ts = getTs(this, varargin)
            Ts = this.ModelValue.Ts;
        end
    end

    %% Protected methods (override in subclass)
    methods (Access=protected)
       function sz = getResponseSize(this)
          sz = [this.NOutputs, this.NInputs];
       end

       function iPlot = getResponseIndices(this)
          iPlot = 1:this.NOutputs*this.NInputs;
       end

        function updateData(this,modelResponseOptionalInputs)
            arguments
                this (1,1) controllib.chart.internal.data.response.ModelResponseDataSource
                modelResponseOptionalInputs.Model = this.Model
            end
            updateModelDataAndSource(this,modelResponseOptionalInputs.Model);
        end

        function updateModelDataAndSource(this,model)
            arguments
                this (1,1) controllib.chart.internal.data.response.ModelResponseDataSource
                model
            end
            % Get model source and data
            this.Model = model;
            this.ModelSource = getModelSource(this);
            this.ModelValue = getModelValue(this);
            if isa(this.Model,'idnlmodel')
                this.ArrayDim = 1;
            else
                this.ArrayDim = getArraySize(this.ModelValue);
            end
        end

        function modelSource = getModelSource(this)
            % Override in subclass if needed
            modelSource = [];
        end

        function modelValue = getModelValue(this)
            modelValue = getValue(this.Model,'usample');
        end

        function modelData = getModelData(this)
            % Override in subclass if needed
            modelData = getPlotLTIData(this.ModelValue);
        end

        function ko_idx = mapDataToPlotOutputIdx(this,ko)
            % Get plot output index based on data output index
            if ~isempty(this.PlotOutputIdx)
                ko_idx = find(this.PlotOutputIdx==ko,1);
            elseif this.NOutputs <= ko
                ko_idx = ko;
            else
                ko_idx = [];
            end
        end

        function ki_idx = mapDataToPlotInputIdx(this,ki)
            % Get plot output index based on data output index
            if ~isempty(this.PlotInputIdx)
                ki_idx = find(this.PlotInputIdx==ki,1);
            elseif this.NOutputs <= ki
                ki_idx = ki;
            else
                ki_idx = [];
            end
        end

        function thisCopy = copyElement(this)
            thisCopy = copyElement@controllib.chart.internal.data.response.BaseResponseDataSource(this);
            % thisCopy.ModelSource = getPlotSource(thisCopy.Model,thisCopy.Model.Name);
        end

        function IsReal = getIsReal_(this)
            if isa(this.ModelValue,'ltvss')
                IsReal = true; % isreal is NaN for time-varying models, but setting to true from a chart perspective
            elseif isa(this.Model,'idnlmodel') % idnlmodel data cannot be indexed into. this will change with Model API updates.
                IsReal = isreal(this.ModelData);
            else
                IsReal = arrayfun(@(x) isreal(x),this.ModelData);
            end
        end
    end

    %% Hidden methods
    methods (Hidden)
        function modelValue = qeGetModelValue(this)
            modelValue = this.ModelValue;
        end
    end
end