classdef InitialResponse < controllib.chart.internal.foundation.InputOutputModelResponse & ...
                        controllib.chart.internal.foundation.MixInControlsModelResponse
    % controllib.chart.response.InitialResponse
    %   - manage data and style properties for a response in "initialplot"
    %   - inherited from controllib.chart.internal.foundation.InputOutputModelResponse
    %
    % h = InitialResponse(model)
    %   model       DynamicSystem
    % 
    % h = InitialResponse(_____,Name-Value)
    %   Name                    response name, string, "" (default)
    %   Style                   response style object, controllib.chart.internal.options.ResponseStyle (default)
    %   Tag                     response tag, string, matlab.lang.internal.uuid (default)
    %   LegendDisplay           show response in legend, matlab.lang.OnOffSwitchState, true (default)
    %   Time                    time vector used to generate data, [] (default) auto generates time vector
    %   Parameter               parameter used to generate data, only for lpvss models
    %   Config                  RespConfig object used to generate data
    %   SettlingTimeThreshold   threshold to compute settling time and transient time, 0.02 (default) based on toolbox preferences
    %
    % Settable properties:
    %   SourceData              struct containing values (Model,TimeSpec,Parameter,Bias,Amplitude,Delay,InitialState,InitialParameter)
    %                           used in computing the response
    %   Name                    label for response in chart, string
    %   Visible                 show response in chart, matlab.lang.OnOffSwitchState
    %   Style                   response style object, controllib.chart.internal.options.ResponseStyle
    %   LegendDisplay           show response in legend, matlab.lang.OnOffSwitchState
    %   UserData                custom data, any MATLAB array
    %   SettlingTimeThreshold   threshold to compute settling time and transient time, double
    %
    % Read-Only properties:
    %   TimeUnit    string specifying time unit, based on Model TimeUnit.
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
    %   <a href="matlab:help controllib.chart.internal.foundation.InputOutputModelResponse">controllib.chart.internal.foundation.InputOutputModelResponse</a>
    %   <a href="matlab:help RespConfig">RespConfig</a>

    % Copyright 2023-2024 The MathWorks, Inc.
    
    %% Properties
    properties (Dependent, AbortSet, SetObservable)
        % "SourceData": struct
        % Values used to generate data
        SourceData
    end

    properties (Dependent,AbortSet,SetObservable,Access=protected)
        % "TimeSpec": double vector
        % Time specification for response.
        TimeSpec
        % "Parameter": function_handle scalar or double matrix
        % LPV model parameter trajectory.
        Parameter               
        % "InitialCondition": OperatingPoint(2) scalar
        % Initial condition for response.
        InitialCondition
    end

    properties (Hidden,Dependent,AbortSet,SetObservable)
        % "SettlingTimeThreshold": double scalar
        % Threshold to compute settling time and transient time.
        SettlingTimeThreshold
    end
    
    properties (Hidden,Dependent,SetAccess=private)
        % "TimeUnit": string
        % Get TimeUnit of Model.
        TimeUnit
    end
    
    properties (Hidden,Dependent,AbortSet)
        InitialState
    end

    properties (GetAccess=protected,SetAccess=private)
        TimeSpec_I
        Parameter_I
        SettlingTimeThreshold_I
        InitialCondition_I
    end

    %% Constructor
    methods
        function this = InitialResponse(modelSource,initialResponseOptionalInputs,baseResponseOptionalInputs)
            arguments
                modelSource
                initialResponseOptionalInputs.Time (:,1) double ...
                    {controllib.chart.internal.utils.validators.mustBeTimeVector} = []
                initialResponseOptionalInputs.Parameter = []
                initialResponseOptionalInputs.Config
                initialResponseOptionalInputs.SettlingTimeThreshold (1,1) double = get(cstprefs.tbxprefs,'SettlingTimeThreshold')
                baseResponseOptionalInputs.?controllib.chart.internal.foundation.BaseResponseOptionalInputs
            end

            % Create model source if model provided as first argument
            if ~isa(modelSource,'controllib.chart.internal.utils.ModelSource')
                modelSource = controllib.chart.internal.utils.ModelSource(modelSource);
            end

            [model,initialResponseOptionalInputs] = controllib.chart.response.InitialResponse.parseInitialResponseInputs(modelSource.Model,initialResponseOptionalInputs);
            modelSource.Model_I = model;
            baseResponseOptionalInputs = namedargs2cell(baseResponseOptionalInputs);
            this@controllib.chart.internal.foundation.InputOutputModelResponse(modelSource,baseResponseOptionalInputs{:});
            
            this.TimeSpec_I = initialResponseOptionalInputs.Time;
            this.Parameter_I = initialResponseOptionalInputs.Parameter;
            this.InitialCondition = initialResponseOptionalInputs.Config;
            this.SettlingTimeThreshold_I = initialResponseOptionalInputs.SettlingTimeThreshold;

            if ~isempty(initialResponseOptionalInputs.Time)
                this.AutoGenerateXData = false;
            end
            build(this);

            this.Type = "initial";
        end
    end
    
    %% Get/Set
    methods
        % SourceData
        function SourceData = get.SourceData(this)
            % Model and Time
            SourceData.Model = this.Model;
            SourceData.TimeSpec = this.TimeSpec;
            % Parameter (if applicable)
            if isa(this.Model,'lpvss')
                SourceData.Parameter = this.Parameter;
            end
            % Config
            SourceData.InitialCondition = this.InitialCondition;
        end

        function set.SourceData(this,SourceData)
            mustBeMember(fields(SourceData),fields(this.SourceData));
            this.Model = SourceData.Model;
            this.TimeSpec = SourceData.TimeSpec;
            % Parameter (if applicable)
            if isa(this.Model,'lpvss')
                this.Parameter = SourceData.Parameter;
            else
                this.Parameter = [];
            end
            % Config
            this.InitialCondition = SourceData.InitialCondition;

            markDirtyAndUpdate(this);
        end

        % TimeUnit
        function TimeUnit = get.TimeUnit(this)
            arguments
                this (1,1) controllib.chart.response.InitialResponse
            end
            TimeUnit = string(this.Model.TimeUnit);
        end

        % TimeSpec
        function TimeSpec = get.TimeSpec(this)
            arguments
                this (1,1) controllib.chart.response.InitialResponse
            end
            TimeSpec = this.TimeSpec_I;
        end
        
        function set.TimeSpec(this,TimeSpec)
            arguments
                this (1,1) controllib.chart.response.InitialResponse
                TimeSpec (:,1) double {controllib.chart.internal.utils.validators.mustBeTimeVector}
            end
            try
                this.TimeSpec_I = TimeSpec;
                markDirtyAndUpdate(this);               
            catch ME
                throw(ME);
            end
        end

        % Parameter
        function Parameter = get.Parameter(this)
            arguments
                this (1,1) controllib.chart.response.InitialResponse
            end
            Parameter = this.Parameter_I;
        end
        
        function set.Parameter(this,Parameter)
            arguments
                this (1,1) controllib.chart.response.InitialResponse
                Parameter
            end
            try
                this.Parameter_I = Parameter;
                markDirtyAndUpdate(this);               
            catch ME
                throw(ME);
            end
        end

        % SettlingTimeThreshold
        function SettlingTimeThreshold = get.SettlingTimeThreshold(this)
            arguments
                this (1,1) controllib.chart.response.InitialResponse
            end
            SettlingTimeThreshold = this.SettlingTimeThreshold_I;
        end
        
        function set.SettlingTimeThreshold(this,SettlingTimeThreshold)
            arguments
                this (1,1) controllib.chart.response.InitialResponse
                SettlingTimeThreshold (1,1) double
            end
            try
                this.SettlingTimeThreshold_I = SettlingTimeThreshold;
                markDirtyAndUpdate(this);
            catch ME
                throw(ME);
            end
        end

        % InitialCondition
        function InitialCondition = get.InitialCondition(this)
            arguments
                this (1,1) controllib.chart.response.InitialResponse
            end
            InitialCondition = this.InitialCondition_I;
        end
        
        function set.InitialCondition(this,IC)
            arguments
                this (1,1) controllib.chart.response.InitialResponse
                IC (1,1) {mustBeA(IC,["RespConfig","ltipack.OperatingPoint","ltipack.OperatingPoint2"])}
            end
            try
                this.InitialCondition_I = IC;
                markDirtyAndUpdate(this);               
            catch ME
                throw(ME);
            end
        end

        % InitialState
        function InitialState = get.InitialState(this)
            if isa(this.InitialCondition,'ltipack.OperatingPoint')
                InitialState = this.InitialCondition.x;
            elseif isa(this.InitialCondition,'ltipack.OperatingPoint2')
                InitialState = [this.InitialCondition.q;this.InitialCondition.dq];
            else
                InitialState = this.InitialCondition.InitialState;
            end
        end

        function set.InitialState(this,InitialState)
            arguments
                this (1,1) controllib.chart.response.InitialResponse
                InitialState (:,1) double
            end
            if isa(this.InitialCondition,'ltipack.OperatingPoint')
                this.InitialCondition.x = InitialState;
            elseif isa(this.InitialCondition,'ltipack.OperatingPoint2')
                this.InitialCondition.q = InitialState(1:length(InitialState)/2);
                this.InitialCondition.dq = InitialState(length(InitialState)/2+1:end);
            else
                this.InitialCondition.InitialState = InitialState;
            end
        end
    end

    %% Static methods
    methods (Static)
        function modifyIncomingSerializationContent(thisSerialized)
            if ~thisSerialized.hasNameValue("Version") %24b
                thisSerialized.rename("Time","TimeSpec_I");
                thisSerialized.rename("Parameter","Parameter_I");
            end
            modifyIncomingSerializationContent@controllib.chart.internal.foundation.InputOutputModelResponse(thisSerialized);
        end

        function this = finalizeIncomingObject(this)
            this = finalizeIncomingObject@controllib.chart.internal.foundation.InputOutputModelResponse(this);
        end

        function modifyOutgoingSerializationContent(thisSerialized,this)
            modifyOutgoingSerializationContent@controllib.chart.internal.foundation.InputOutputModelResponse(thisSerialized,this);
        end
    end

    %% Protected methods (override in subclass)
    methods (Access = protected)
        function initializeData(this)
            arguments
                this (1,1) controllib.chart.response.InitialResponse
            end
            this.ResponseData = controllib.chart.internal.data.response.InitialResponseDataSource(this.Model,...
                Time=this.TimeSpec,Parameter=this.Parameter,Config=this.InitialCondition);
        end

        function updateData(this)
            arguments
                this (1,1) controllib.chart.response.InitialResponse
            end
            options.Time = this.TimeSpec;
            options.Parameter = this.Parameter;
            options.Config = this.InitialCondition;
            options.SettlingTimeThreshold = this.SettlingTimeThreshold;
            this.AutoGenerateXData = isempty(options.Time);
            [model,initialResponseOptionalInputs] = controllib.chart.response.InitialResponse.parseInitialResponseInputs(...
                this.Model,options);
            optionsCell = namedargs2cell(initialResponseOptionalInputs);
            updateData@controllib.chart.internal.foundation.InputOutputModelResponse(this,optionsCell{:},Model=model);
        end
    end

    %% Private static methods
    methods (Static,Access=private)
        function [model,initialResponseOptionalInputs] = parseInitialResponseInputs(model,initialResponseOptionalInputs)
            % Parse Settling Time Threshold
            try
                mustBeInRange(initialResponseOptionalInputs.SettlingTimeThreshold,0,1)
            catch
                error(message('Controllib:plots:RespInfoCheck1'))
            end
        end
    end

    %% Hidden static methods
    methods (Hidden,Static)
        function dataProperties = getDataProperties()
            dataProperties = "SourceData";
        end
    end
end

