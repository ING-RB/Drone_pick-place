classdef StepResponse < controllib.chart.internal.foundation.InputOutputModelResponse & ...
                        controllib.chart.internal.foundation.MixInControlsModelResponse
    % controllib.chart.response.StepResponse
    %   - manage data and style properties for a response in "stepplot"
    %   - inherited from controllib.chart.internal.foundation.InputOutputModelResponse
    %
    % h = StepResponse(model)
    %   model       DynamicSystem
    % 
    % h = StepResponse(_____,Name-Value)
    %   Name                        response name, string, "" (default)
    %   Style                       response style object, controllib.chart.internal.options.ResponseStyle (default)
    %   Tag                         response tag, string, matlab.lang.internal.uuid (default)
    %   LegendDisplay               show response in legend, matlab.lang.OnOffSwitchState, true (default)
    %   Time                        time vector used to generate data, [] (default) auto generates time vector
    %   Parameter                   parameter used to generate data, only for lpvss models
    %   Config                      RespConfig object used to generate data
    %   SettlingTimeThreshold       threshold to compute settling time and transient time, 0.02 (default) based on toolbox preferences
    %   RiseTimeLimits              limits used to compute rise time, [0.1 0.9] (default) based on toolbox preferences
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
    %   Model                   DynamicSystem for response
    %   Time                    time vector used to generate data, double
    %   Parameter               parameter used to generate data, only for lpvss models
    %   Config                  RespConfig object used to generate data
    %   SettlingTimeThreshold   threshold to compute settling time and transient time, double
    %   RiseTimeLimits          limits used to compute rise time, 1x2 double
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
        % "Config": RespConfig scalar
        % Data options for response.
        Config
    end

    properties (Hidden,Dependent,AbortSet,SetObservable)
        % "SettlingTimeThreshold": double scalar
        % Threshold to compute settling time and transient time.
        SettlingTimeThreshold 
        % "RiseTimeLimits": 1x2 double
        % Limits used to compute rise time.
        RiseTimeLimits
    end

    properties (Hidden,Dependent,SetAccess=private)
        % "TimeUnit": string
        % Get TimeUnit of Model.
        TimeUnit
    end

    properties (GetAccess = protected,SetAccess=private)
        TimeSpec_I
        Parameter_I                   
        Config_I
        SettlingTimeThreshold_I
        RiseTimeLimits_I
        NumberOfStandardDeviations_I
    end
    
    %% Constructor
    methods
        function this = StepResponse(modelSource,stepResponseOptionalInputs,baseResponseOptionalInputs)
            arguments
                modelSource
                stepResponseOptionalInputs.Time (:,1) double ...
                    {controllib.chart.internal.utils.validators.mustBeTimeVector} = []
                stepResponseOptionalInputs.Parameter = []
                stepResponseOptionalInputs.Config (1,1) RespConfig = RespConfig
                stepResponseOptionalInputs.SettlingTimeThreshold (1,1) double = get(cstprefs.tbxprefs,'SettlingTimeThreshold')
                stepResponseOptionalInputs.RiseTimeLimits (1,2) double = get(cstprefs.tbxprefs,'RiseTimeLimits')
                stepResponseOptionalInputs.NumberOfStandardDeviations (1,1) double = get(timeoptions('cstprefs'),'ConfidenceRegionNumberSD')
                baseResponseOptionalInputs.?controllib.chart.internal.foundation.BaseResponseOptionalInputs
            end

            % Create model source if model provided as first argument
            if ~isa(modelSource,'controllib.chart.internal.utils.ModelSource')
                modelSource = controllib.chart.internal.utils.ModelSource(modelSource);
            end

            [model,stepResponseOptionalInputs] = controllib.chart.response.StepResponse.parseStepResponseInputs(modelSource.Model,stepResponseOptionalInputs);
            modelSource.Model_I = model;
            baseResponseOptionalInputs = namedargs2cell(baseResponseOptionalInputs);
            this@controllib.chart.internal.foundation.InputOutputModelResponse(modelSource,baseResponseOptionalInputs{:});
            
            this.TimeSpec_I = stepResponseOptionalInputs.Time;
            this.Parameter_I = stepResponseOptionalInputs.Parameter;
            this.Config_I = stepResponseOptionalInputs.Config;
            this.SettlingTimeThreshold_I = stepResponseOptionalInputs.SettlingTimeThreshold;
            this.RiseTimeLimits_I = stepResponseOptionalInputs.RiseTimeLimits;
            this.NumberOfStandardDeviations_I = stepResponseOptionalInputs.NumberOfStandardDeviations;

            if ~isempty(stepResponseOptionalInputs.Time)
                this.AutoGenerateXData = false;
            end
            build(this);

            this.Type = "step";
            if isa(model,'idlti')
                p = addprop(this,'NumberOfStandardDeviations');
                p.Hidden = 1;
                p.Dependent = 1;
                p.AbortSet = 1;
                p.SetObservable = 1;
                p.GetMethod = @getNumberOfStandardDeviations;
                p.SetMethod = @setNumberOfStandardDeviations;
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
                this (1,1) controllib.chart.response.StepResponse
            end
            TimeUnit = string(this.Model.TimeUnit);
        end

        % TimeSpec
        function TimeSpec = get.TimeSpec(this)
            arguments
                this (1,1) controllib.chart.response.StepResponse
            end
            TimeSpec = this.TimeSpec_I;
        end
        
        function set.TimeSpec(this,TimeSpec)
            arguments
                this (1,1) controllib.chart.response.StepResponse
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
                this (1,1) controllib.chart.response.StepResponse
            end
            Parameter = this.Parameter_I;
        end
        
        function set.Parameter(this,Parameter)
            arguments
                this (1,1) controllib.chart.response.StepResponse
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
                this (1,1) controllib.chart.response.StepResponse
            end
            Config = this.Config_I;
        end
        
        function set.Config(this,Config)
            arguments
                this (1,1) controllib.chart.response.StepResponse
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
                this (1,1) controllib.chart.response.StepResponse
            end
            SettlingTimeThreshold = this.SettlingTimeThreshold_I;
        end
        
        function set.SettlingTimeThreshold(this,SettlingTimeThreshold)
            arguments
                this (1,1) controllib.chart.response.StepResponse
                SettlingTimeThreshold (1,1) double
            end
            try
                this.SettlingTimeThreshold_I = SettlingTimeThreshold;
                markDirtyAndUpdate(this);               
            catch ME
                throw(ME);
            end
        end
        
        % RiseTimeLimits
        function RiseTimeLimits = get.RiseTimeLimits(this)
            arguments
                this (1,1) controllib.chart.response.StepResponse
            end
            RiseTimeLimits = this.RiseTimeLimits_I;
        end
        
        function set.RiseTimeLimits(this,RiseTimeLimits)
            arguments
                this (1,1) controllib.chart.response.StepResponse
                RiseTimeLimits (1,2) double
            end
            try
                this.RiseTimeLimits_I = RiseTimeLimits;
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
                this (1,1) controllib.chart.response.StepResponse
            end
            NumberOfStandardDeviations = this.NumberOfStandardDeviations_I;
        end
        
        function setNumberOfStandardDeviations(this,NumberOfStandardDeviations)
            arguments
                this (1,1) controllib.chart.response.StepResponse
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
                this (1,1) controllib.chart.response.StepResponse
            end
            this.ResponseData = controllib.chart.internal.data.response.StepResponseDataSource(this.Model,...
                Time=this.TimeSpec,Parameter=this.Parameter,Config=this.Config,...
                SettlingTimeThreshold=this.SettlingTimeThreshold,...
                RiseTimeLimits=this.RiseTimeLimits,...
                NumberOfStandardDeviations=this.NumberOfStandardDeviations_I);
        end

        function updateData(this)
            arguments
                this (1,1) controllib.chart.response.StepResponse
            end
            options.Time = this.TimeSpec;
            options.Parameter = this.Parameter;
            options.Config = this.Config;
            options.SettlingTimeThreshold = this.SettlingTimeThreshold;
            options.RiseTimeLimits = this.RiseTimeLimits;
            options.NumberOfStandardDeviations = this.NumberOfStandardDeviations_I;
            this.AutoGenerateXData = isempty(options.Time);
            
            [model,options] = controllib.chart.response.StepResponse.parseStepResponseInputs(this.Model,options);
            optionsCell = namedargs2cell(options);
            updateData@controllib.chart.internal.foundation.InputOutputModelResponse(this,optionsCell{:},Model=this.Model);
            
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
        function [model,stepResponseOptionalInputs] = parseStepResponseInputs(model,stepResponseOptionalInputs)
            % Parse Settling Time Threshold
            try
                mustBeInRange(stepResponseOptionalInputs.SettlingTimeThreshold,0,1)
            catch
                error(message('Controllib:plots:RespInfoCheck1'))
            end
            % Parse Rise Time Limits
            try
                mustBeInRange(stepResponseOptionalInputs.RiseTimeLimits(1),0,stepResponseOptionalInputs.RiseTimeLimits(2))
                mustBeInRange(stepResponseOptionalInputs.RiseTimeLimits(2),stepResponseOptionalInputs.RiseTimeLimits(1),1)
            catch
                error(message('Controllib:plots:RespInfoCheck2'))
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

