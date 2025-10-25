classdef ImpulseResponse < controllib.chart.internal.foundation.InputOutputModelResponse & ...
                        controllib.chart.internal.foundation.MixInControlsModelResponse
    % controllib.chart.response.ImpulseResponse
    %   - manage data and style properties for a response in "impulseplot"
    %   - inherited from controllib.chart.internal.foundation.InputOutputModelResponse
    %
    % h = ImpulseResponse(model)
    %   model       DynamicSystem
    % 
    % h = ImpulseResponse(_____,Name-Value)
    %   Name                    response name, string, "" (default)
    %   Style                   response style object, controllib.chart.internal.options.ResponseStyle (default)
    %   Tag                     response tag, string, matlab.lang.internal.uuid (default)
    %   LegendDisplay           show response in legend, matlab.lang.OnOffSwitchState, true (default)
    %   Time                    time vector used to generate data, [] (default) auto generates time vector
    %   Parameter               parameter used to generate data, only for lpvss models
    %   Config                  RespConfig object used to generate data
    %   SettlingTimeThreshold   threshold to compute settling time and transient time, 0.02 (default) based on toolbox preferences
    %   NumberOfStandardDeviations  standard deviation used to show confidence region for identified models
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
    %   NumberOfStandardDeviations  standard deviation used to show confidence region for identified models
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
    
    % Copyright 2022-2024 The MathWorks, Inc.
    
    %% Properties
    properties(Dependent, AbortSet, SetObservable)
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
        % "Config": RespConfig scalar
        % Data options for response.
        Config
    end

    properties (Hidden,Dependent,AbortSet,SetObservable)
        % "SettlingTimeThreshold": double scalar
        % Threshold to compute settling time and transient time.
        SettlingTimeThreshold
    end

    properties(Hidden,Dependent,SetAccess=private)
        % "TimeUnit": string
        % Get TimeUnit of Model.
        TimeUnit
    end
    
    properties (GetAccess = protected,SetAccess=private)
        TimeSpec_I
        Parameter_I
        Config_I
        SettlingTimeThreshold_I
        NumberOfStandardDeviations_I
    end

    %% Constructor
    methods
        function this = ImpulseResponse(modelSource,impulseResponseOptionalInputs,baseResponseOptionalInputs)
            arguments
                modelSource
                impulseResponseOptionalInputs.Time (:,1) double ...
                    {controllib.chart.internal.utils.validators.mustBeTimeVector} = []
                impulseResponseOptionalInputs.Parameter = []
                impulseResponseOptionalInputs.Config (1,1) RespConfig = RespConfig
                impulseResponseOptionalInputs.SettlingTimeThreshold (1,1) double = get(cstprefs.tbxprefs,'SettlingTimeThreshold')
                impulseResponseOptionalInputs.NumberOfStandardDeviations (1,1) double = get(timeoptions('cstprefs'),'ConfidenceRegionNumberSD')
                baseResponseOptionalInputs.?controllib.chart.internal.foundation.BaseResponseOptionalInputs
            end

            % Create model source if model provided as first argument
            if ~isa(modelSource,'controllib.chart.internal.utils.ModelSource')
                modelSource = controllib.chart.internal.utils.ModelSource(modelSource);
            end

            [model,impulseResponseOptionalInputs] = controllib.chart.response.ImpulseResponse.parseImpulseResponseInputs(modelSource.Model,impulseResponseOptionalInputs);
            modelSource.Model_I = model;
            baseResponseOptionalInputs = namedargs2cell(baseResponseOptionalInputs);
            this@controllib.chart.internal.foundation.InputOutputModelResponse(modelSource,baseResponseOptionalInputs{:});
            
            this.TimeSpec_I = impulseResponseOptionalInputs.Time;
            this.Config_I = impulseResponseOptionalInputs.Config;
            this.Parameter_I = impulseResponseOptionalInputs.Parameter;
            this.SettlingTimeThreshold_I = impulseResponseOptionalInputs.SettlingTimeThreshold;
            this.NumberOfStandardDeviations_I = impulseResponseOptionalInputs.NumberOfStandardDeviations;
            
            if ~isempty(impulseResponseOptionalInputs.Time)
                this.AutoGenerateXData = false;
            end
            build(this);

            this.Type = "impulse";

            if isa(model,'idlti')
                p = addprop(this,'NumberOfStandardDeviations');
                p.Hidden = 1;
                p.Dependent = 1;
                p.AbortSet = 1;
                p.SetObservable = 1;
                p.GetMethod = @getNumberOfStandardDeviations;
                p.SetMethod = @setNumberOfStandardDeviations;
            end
            if isa(model,'idlti') && model.Ts ~= 0
                if this.Style.MarkerStyleMode == "auto"
                    this.Style.MarkerStyle = get(groot,'DefaultStemMarker');
                    this.Style.MarkerStyleMode = "auto";
                end
            else
                if this.Style.MarkerStyleMode == "auto"
                    this.Style.MarkerStyle = get(groot,'DefaultLineMarker');
                    this.Style.MarkerStyleMode = "auto";
                end
            end
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
            SourceData.Config = this.Config;
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
            this.Config = SourceData.Config;

            markDirtyAndUpdate(this);
        end

        % TimeUnit
        function TimeUnit = get.TimeUnit(this)
            arguments
                this (1,1) controllib.chart.response.ImpulseResponse
            end
            TimeUnit = string(this.Model.TimeUnit);
        end

        % TimeSpec
        function TimeSpec = get.TimeSpec(this)
            arguments
                this (1,1) controllib.chart.response.ImpulseResponse
            end
            TimeSpec = this.TimeSpec_I;
        end
        
        function set.TimeSpec(this,TimeSpec)
            arguments
                this (1,1) controllib.chart.response.ImpulseResponse
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
                this (1,1) controllib.chart.response.ImpulseResponse
            end
            Parameter = this.Parameter_I;
        end
        
        function set.Parameter(this,Parameter)
            arguments
                this (1,1) controllib.chart.response.ImpulseResponse
                Parameter
            end
            try
                this.Parameter_I = Parameter;
                markDirtyAndUpdate(this);               
            catch ME
                throw(ME);
            end
        end

        % Config
        function Config = get.Config(this)
            arguments
                this (1,1) controllib.chart.response.ImpulseResponse
            end
            Config = this.Config_I;
        end
        
        function set.Config(this,Config)
            arguments
                this (1,1) controllib.chart.response.ImpulseResponse
                Config (1,1) RespConfig
            end
            try
                this.Config_I = Config;
                markDirtyAndUpdate(this);               
            catch ME
                throw(ME);
            end
        end

        % SettlingTimeThreshold
        function SettlingTimeThreshold = get.SettlingTimeThreshold(this)
            arguments
                this (1,1) controllib.chart.response.ImpulseResponse
            end
            SettlingTimeThreshold = this.SettlingTimeThreshold_I;
        end
        
        function set.SettlingTimeThreshold(this,SettlingTimeThreshold)
            arguments
                this (1,1) controllib.chart.response.ImpulseResponse
                SettlingTimeThreshold (1,1) double
            end
            try
                this.SettlingTimeThreshold_I = SettlingTimeThreshold;
                markDirtyAndUpdate(this); 
            catch ME
                throw(ME);
            end
        end
    end
    
    %% Get/Set dynamic props
    methods (Access = private)
        % NumberOfStandardDeviations
        function NumberOfStandardDeviations = getNumberOfStandardDeviations(this)
            arguments
                this (1,1) controllib.chart.response.ImpulseResponse
            end
            NumberOfStandardDeviations = this.NumberOfStandardDeviations_I;
        end
        
        function setNumberOfStandardDeviations(this,NumberOfStandardDeviations)
            arguments
                this (1,1) controllib.chart.response.ImpulseResponse
                NumberOfStandardDeviations (1,1) double
            end
            try
                this.NumberOfStandardDeviations_I = NumberOfStandardDeviations;
                markDirtyAndUpdate(this);
            catch ME
                throw(ME);
            end
        end
    end

    %% Static methods
    methods (Static)
        function modifyIncomingSerializationContent(thisSerialized)
            if ~thisSerialized.hasNameValue("Version") %24b
                thisSerialized.rename("Time","TimeSpec_I");
                thisSerialized.rename("Parameter","Parameter_I");
                thisSerialized.rename("Config","Config_I");
            end
            modifyIncomingSerializationContent@controllib.chart.internal.foundation.InputOutputModelResponse(thisSerialized);
        end

        function this = finalizeIncomingObject(this)
            this = finalizeIncomingObject@controllib.chart.internal.foundation.InputOutputModelResponse(this);
            if isa(this.Model,'idlti') && ~isprop(this,'NumberOfStandardDeviations')
                p = addprop(this,'NumberOfStandardDeviations');
                p.Hidden = 1;
                p.Dependent = 1;
                p.AbortSet = 1;
                p.SetObservable = 1;
                p.GetMethod = @getNumberOfStandardDeviations;
                p.SetMethod = @setNumberOfStandardDeviations;
            end
        end

        function modifyOutgoingSerializationContent(thisSerialized,this)
            modifyOutgoingSerializationContent@controllib.chart.internal.foundation.InputOutputModelResponse(thisSerialized,this);
        end
    end

    %% Protected methods (override in subclass)
    methods (Access = protected)
        function initializeData(this)
            arguments
                this (1,1) controllib.chart.response.ImpulseResponse
            end
            this.ResponseData = controllib.chart.internal.data.response.ImpulseResponseDataSource(this.Model,...
                Time=this.TimeSpec,Parameter=this.Parameter,...
                Config=this.Config,SettlingTimeThreshold=this.SettlingTimeThreshold,...
                NumberOfStandardDeviations=this.NumberOfStandardDeviations_I);
        end

        function updateData(this)
            arguments
                this (1,1) controllib.chart.response.ImpulseResponse
            end
            
            options.Time = this.TimeSpec;
            options.Parameter = this.Parameter;
            options.Config = this.Config;
            options.SettlingTimeThreshold = this.SettlingTimeThreshold;
            options.NumberOfStandardDeviations = this.NumberOfStandardDeviations_I;
            this.AutoGenerateXData = isempty(options.Time);
            
            [model,options] = controllib.chart.response.ImpulseResponse.parseImpulseResponseInputs(this.Model,options);
            optionsCell = namedargs2cell(options);
            updateData@controllib.chart.internal.foundation.InputOutputModelResponse(this,optionsCell{:},Model=model);

            if isa(model,'idlti') && ~isprop(this,'NumberOfStandardDeviations')
                p = addprop(this,'NumberOfStandardDeviations');
                p.Hidden = 1;
                p.Dependent = 1;
                p.AbortSet = 1;
                p.SetObservable = 1;
                p.GetMethod = @getNumberOfStandardDeviations;
                p.SetMethod = @setNumberOfStandardDeviations;
            elseif ~isa(model,'idlti') && isprop(this,'NumberOfStandardDeviations')
                p = findprop(this,'NumberOfStandardDeviations');
                delete(p);
            end
            if isa(model,'idlti') && model.Ts ~= 0
                if this.Style.MarkerStyleMode == "auto"
                    this.Style.MarkerStyle = get(groot,'DefaultStemMarker');
                    this.Style.MarkerStyleMode = "auto";
                end
            else
                if this.Style.MarkerStyleMode == "auto"
                    this.Style.MarkerStyle = get(groot,'DefaultLineMarker');
                    this.Style.MarkerStyleMode = "auto";
                end
            end
        end
        
        function thisCopy = copyElement(this)
            thisCopy = copyElement@controllib.chart.internal.foundation.InputOutputModelResponse(this);
            if isa(thisCopy.Model,'idlti')
                p = addprop(thisCopy,'NumberOfStandardDeviations');
                p.Hidden = 1;
                p.Dependent = 1;
                p.AbortSet = 1;
                p.SetObservable = 1;
                p.GetMethod = @getNumberOfStandardDeviations;
                p.SetMethod = @setNumberOfStandardDeviations;
            end
        end
    end

    %% Private static methods
    methods (Static,Access=private)
        function [model,impulseResponseOptionalInputs] = parseImpulseResponseInputs(model,impulseResponseOptionalInputs)
            % Parse Settling Time Threshold
            try
                mustBeInRange(impulseResponseOptionalInputs.SettlingTimeThreshold,0,1)
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

