classdef ModelResponse < controllib.chart.internal.foundation.BaseResponse
    % controllib.chart.internal.foundation.ModelResponse
    %   - base class for managing data and style for a model-based response in Control charts
    %   - inherited from controllib.chart.internal.foundation.BaseResponse
    %
    % h = ModelResponse(model)
    %   model           DynamicSystem
    %
    % h = ModelResponse(_____,Name-Value)
    %   Name            response name, string, "" (default)
    %   Style           response style object, controllib.chart.internal.options.ResponseStyle (default)
    %   Tag             response tag, string, matlab.lang.internal.uuid (default)
    %   LegendDisplay   show response in legend, matlab.lang.OnOffSwitchState, true (default)
    %
    % Settable properties:
    %   Name            label for response in chart, string
    %   Visible         show response in chart, matlab.lang.OnOffSwitchState
    %   Style           response style object, controllib.chart.internal.options.ResponseStyle
    %   LegendDisplay   show response in legend, matlab.lang.OnOffSwitchState
    %   UserData        custom data, any MATLAB array
    %   Model           DynamicSystem for response
    %
    % Read-Only / Internal properties (for subclasses):
    %   Tag                  unique tag for indexing, string
    %   Type                 type of response for subclass, string
    %   AutoGenerateXData    logical value used to set limits focus, matlab.lang.OnOffSwitchState
    %   ArrayDim             array dimensions of ResponseData, double
    %   NResponses           number of elements in array of ResponseData, double
    %   CharacteristicTypes  characteristic types of response data, string
    %   ResponseData         data source object, controllib.chart.internal.data.response.BaseResponseDataSource
    %   IsDiscrete           logical value to specify if Model is discrete
    %   IsReal               logical value to specify if Model is real
    %
    % Events:
    %   ResponseChanged      notified after update is called
    %   ResponseDeleted      notified after delete is called
    %   StyleChanged         notified after Style object is changed
    %
    % Public methods:
    %   build(this)
    %       Creates the data based on Model. Can call in subclass
    %       constructor to build on instantiation.
    %   update(this,Name-Value)
    %       Update the response data with new parameter values.
    %
    % Protected methods (to override in subclass):
    %   initializeData(this)
    %       Create the response data. Called in build().
    %   updateData(this,Name-Value)
    %       Update the response data. Called in update().
    %
    % See Also:
    %   <a href="matlab:help controllib.chart.internal.foundation.BaseResponse">controllib.chart.internal.foundation.BaseResponse</a>

    % Copyright 2022-2024 The MathWorks, Inc.

    %% Properties
    properties (Hidden,Dependent,SetAccess = private)
        % "IsDiscrete": logical scalar
        % Gets if Model is discrete or not.
        IsDiscrete (1,1) logical

        % "IsReal": logical scalar
        % Gets if Model is real or not.
        IsReal (1,1) logical
    end

    properties (Hidden,Dependent, AbortSet, SetObservable)
        % "Model": DynamicSystem array
        % Dynamic system object used to plot response and characteristics.
        Model
    end

    properties (Access=protected)
        % "ModelSource"
        ModelSource controllib.chart.internal.utils.ModelSource {mustBeScalarOrEmpty}
    end

    properties (Hidden,SetAccess={?controllib.chart.internal.foundation.AbstractPlot})
        SupportDynamicIOSize = true
    end

    %% Constructor
    methods
        function this = ModelResponse(modelSource,baseResponseOptionalInputs)
            arguments
                modelSource (1,1)
                baseResponseOptionalInputs.?controllib.chart.internal.foundation.BaseResponseOptionalInputs
            end
            baseResponseOptionalInputs = namedargs2cell(baseResponseOptionalInputs);
            this@controllib.chart.internal.foundation.BaseResponse(baseResponseOptionalInputs{:});
            
            if ~isa(modelSource,'controllib.chart.internal.utils.ModelSource')
                modelSource = this.createModelSource(modelSource);
            end

            this.Type = "model";
            this.ModelSource = modelSource;
            L = addlistener(this.ModelSource,'Model','PostSet',@(es,ed) markDirtyAndUpdate(this));
            registerListeners(this,L,"ModelSourceChangedListener")
            createDataTipInfoFromSamplingGrid(this);
        end
    end

    %% Get/Set
    methods
        % Model
        function Model = get.Model(this)
            arguments
                this (1,1) controllib.chart.internal.foundation.ModelResponse
            end
            Model = this.ModelSource.Model;
        end

        function set.Model(this,Model)
            arguments
                this (1,1) controllib.chart.internal.foundation.ModelResponse
                Model {validateModel(this,Model)}
            end
            if ~this.SupportDynamicIOSize && ~isequal(iosize(Model),iosize(this.Model))
                % New model must have same number of inputs & outputs
                s = size(this.Model);
                error(message('Controllib:plots:UpdateResponse1',s(1),s(2)))
            end
            try
                recreateDataTipInfo = false;
                if any(contains(properties(this.ModelSource.Model),'SamplingGrid'))
                    if any(contains(properties(Model),'SamplingGrid'))
                        if ~isequal(this.ModelSource.Model.SamplingGrid,Model.SamplingGrid)
                            % if old and new model have SamplingGrid but is
                            % different
                            recreateDataTipInfo = true;
                        end
                    else
                        % If old has SamplingGrid but new doesn't
                        recreateDataTipInfo = true;
                    end
                elseif any(contains(properties(Model),'SamplingGrid'))
                    % if old doesn't haven't SamplingGrid but new does
                    recreateDataTipInfo = true;
                end

                % Update Model
                this.ModelSource.Model = Model;

                % Recreate data tips if needed
                if recreateDataTipInfo
                    createDataTipInfoFromSamplingGrid(this);
                end
            catch ME
                throw(ME)
            end
        end

        % IsDiscrete
        function IsDiscrete = get.IsDiscrete(this)
            IsDiscrete = getIsDiscrete(this);
        end

        % IsReal
        function IsReal = get.IsReal(this)
            if isvalid(this.ResponseData)
                IsReal = this.ResponseData.IsReal;
            else
                IsReal = true;
            end
        end
    end

    %% Static methods
    methods (Static)
        function modifyIncomingSerializationContent(thisSerialized)
            modifyIncomingSerializationContent@controllib.chart.internal.foundation.BaseResponse(thisSerialized);
        end

        function this = finalizeIncomingObject(this)
            this = finalizeIncomingObject@controllib.chart.internal.foundation.BaseResponse(this);
            L = addlistener(this.ModelSource,'Model','PostSet',@(es,ed) markDirtyAndUpdate(this));
            registerListeners(this,L,"ModelSourceChangedListener")
            this.ResponseData.PlotInputIdx = this.SavedValues.PlotInputIdx;
            this.ResponseData.PlotOutputIdx = this.SavedValues.PlotOutputIdx;
        end

        function modifyOutgoingSerializationContent(thisSerialized,this)
            this.SavedValues.PlotInputIdx = this.ResponseData.PlotInputIdx;
            this.SavedValues.PlotOutputIdx = this.ResponseData.PlotOutputIdx;
            modifyOutgoingSerializationContent@controllib.chart.internal.foundation.BaseResponse(thisSerialized,this);
        end
    end

    %% Hidden methods
    methods (Hidden)
        function modelSource = getModelSource(this)
            arguments
                this (1,1) controllib.chart.internal.foundation.ModelResponse
            end
            modelSource = this.ModelSource;
        end
        function setModelSource(this,modelSource)
            arguments
                this (1,1) controllib.chart.internal.foundation.ModelResponse
                modelSource (1,1) controllib.chart.internal.utils.ModelSource
            end
            unregisterListeners(this,"ModelSourceChangedListener")
            this.ModelSource = modelSource;
            L = addlistener(this.ModelSource,'Model','PostSet',@(es,ed) markDirtyAndUpdate(this));
            registerListeners(this,L,"ModelSourceChangedListener")
            createDataTipInfoFromSamplingGrid(this);
            update(this);
        end

        function boo = usesModelSource(this, src)
            boo = this.ModelSource==src;
        end

        function Ts = getTs(this)
            Ts = this.Model.Ts;
        end
    end

    %% Protected methods (override in subclass)
    methods (Access = protected)
        function updateData(this,varargin,modelResponseOptionalInputs)
            arguments
                this (1,1) controllib.chart.internal.foundation.ModelResponse
            end
            arguments (Repeating)
                varargin
            end
            arguments
                modelResponseOptionalInputs.Model = this.Model
            end
            % Set model and related properties
            % Update data
            if ~isempty(this.ResponseData) && isvalid(this.ResponseData)
                update(this.ResponseData,varargin{:},Model=modelResponseOptionalInputs.Model);
                if ~isequal(size(this.ArrayVisible),size(this.ResponseData.ArrayDim))
                    this.ArrayVisible = true(this.ResponseData.ArrayDim);
                end
            end
        end

        function IsDiscrete = getIsDiscrete(this)
            Ts = getTs(this);
            IsDiscrete = Ts > 0 || Ts == -1;
        end

        function thisCopy = copyElement(this)
            thisCopy = copyElement@controllib.chart.internal.foundation.BaseResponse(this);
            thisCopy.ModelSource = copy(this.ModelSource);
            L = addlistener(thisCopy.ModelSource,'Model','PostSet',@(es,ed) markDirtyAndUpdate(thisCopy));
            registerListeners(thisCopy,L,"ModelSourceChangedListener")
        end

        function validateModel(~,model)
            mustBeA(model,'ltipack.LabeledIOModel');
        end
    end

    %% Private methods
    methods (Access = private)
        function createDataTipInfoFromSamplingGrid(this)
            clearDataTipInfo(this);
            % Create data tip info from sampling grid if available
            if any(contains(properties(this.Model),'SamplingGrid')) ...
                    && ~isempty(fieldnames(this.Model.SamplingGrid))
                samplingGrid = this.Model.SamplingGrid;
                [nOutputs,nInputs,nArray] = size(this.Model);
                samplingGridFieldNames = fieldnames(samplingGrid);
                for ka = 1:nArray
                    for ko = 1:nOutputs
                        for ki = 1:nInputs
                            for k = 1:length(samplingGridFieldNames)
                                s.(samplingGridFieldNames{k}) = ...
                                    samplingGrid.(samplingGridFieldNames{k})(ka);
                            end
                            setDataTipInfo(this,s,ko,ki,ka);
                            s = [];
                        end
                    end
                end
            end
        end
    end

    %% Static protected methods
    methods (Static,Access=protected)
        function [inputNames,outputNames] = getIONamesFromModel(model)
            [inputNames,outputNames] = mrgios(model);
            [nOutputs,nInputs] = iosize(model);
            if isa(model,'idnlmodel') && nInputs == 0
                nInputs = nOutputs; %noise2meas
            end
            outputNames = outputNames(1:nOutputs);
            inputNames = inputNames(1:nInputs);
        end

        function modelSource = createModelSource(model)
            modelSource = controllib.chart.internal.utils.ModelSource(model);
        end
    end
end
