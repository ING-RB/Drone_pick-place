classdef LinearSimulationResponse < controllib.chart.internal.foundation.InputOutputModelResponse & ...
                        controllib.chart.internal.foundation.MixInControlsModelResponse
    % controllib.chart.response.LinearSimulationResponse
    %   - manage data and style properties for a response in "lsimplot"
    %   - inherited from controllib.chart.internal.foundation.InputOutputModelResponse
    %
    % h = LinearSimulationResponse(model)
    %   model       DynamicSystem
    % 
    % h = LinearSimulationResponse(_____,Name-Value)
    %   Name                    response name, string, "" (default)
    %   Style                   response style object, controllib.chart.internal.options.ResponseStyle (default)
    %   Tag                     response tag, string, matlab.lang.internal.uuid (default)
    %   LegendDisplay           show response in legend, matlab.lang.OnOffSwitchState, true (default)
    %   Time                    time vector used to generate data, [] (default) auto generates time vector
    %   Parameter               parameter used to generate data, only for lpvss models
    %   Config                  RespConfig object used to generate data
    %   InputSignal             input signal used to generate data
    %   InterpolationMethod     interpolation method used to generate data, "auto" (default) selects best method
    %
    % Settable properties:
    %   SourceData              struct containing values (Model,Time,InputSignal,Parameter,Bias,Amplitude,Delay,
    %                           InitialState,InitialParameter,InterpolationMethod) used in computing the response
    %   Name                    label for response in chart, string
    %   Visible                 show response in chart, matlab.lang.OnOffSwitchState
    %   Style                   response style object, controllib.chart.internal.options.ResponseStyle
    %   LegendDisplay           show response in legend, matlab.lang.OnOffSwitchState
    %   UserData                custom data, any MATLAB array
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
        % "Time": double vector
        % Time steps for response.
        Time
        % "Parameter": function_handle scalar or double matrix
        % LPV model parameter trajectory.
        Parameter               
        % "InitialCondition": OperatingPoint(2) scalar
        % Initial condition for response.
        InitialCondition
        % "InputSignal": double matrix
        % Input signal for response.
        InputSignal
        % "InterpolationMethod": string scalar
        % Interpolation method between input samples.
        InterpolationMethod
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
        Time_I
        Parameter_I
        InitialCondition_I
        InputSignal_I
        InterpolationMethod_I
    end
    
    %% Constructor
    methods
        function this = LinearSimulationResponse(modelSource,lSimResponseOptionalInputs,baseResponseOptionalInputs)
            arguments
                modelSource
                lSimResponseOptionalInputs.Time (:,1) double ...
                    {controllib.chart.internal.utils.validators.mustBeTimeVector} = []
                lSimResponseOptionalInputs.InputSignal (:,:) double = []
                lSimResponseOptionalInputs.InterpolationMethod (1,1) string {mustBeMember(lSimResponseOptionalInputs.InterpolationMethod,["auto","zoh","foh"])} = "auto"; 
                lSimResponseOptionalInputs.Parameter = []
                lSimResponseOptionalInputs.Config = []
                baseResponseOptionalInputs.?controllib.chart.internal.foundation.BaseResponseOptionalInputs
            end

            % Create model source if model provided as first argument
            if ~isa(modelSource,'controllib.chart.internal.utils.ModelSource')
                modelSource = controllib.chart.internal.utils.ModelSource(modelSource);
            end
            
            baseResponseOptionalInputs = namedargs2cell(baseResponseOptionalInputs);
            this@controllib.chart.internal.foundation.InputOutputModelResponse(modelSource,baseResponseOptionalInputs{:});
            
            this.Time_I = lSimResponseOptionalInputs.Time;
            this.InputSignal_I = lSimResponseOptionalInputs.InputSignal;
            this.InterpolationMethod_I = lSimResponseOptionalInputs.InterpolationMethod;
            this.Parameter_I = lSimResponseOptionalInputs.Parameter;
            this.InitialCondition_I = lSimResponseOptionalInputs.Config;

            this.AutoGenerateXData = false;
            build(this);

            this.Type = "lsim";
        end
    end
    
    %% Get/Set
    methods
        % SourceData
        function SourceData = get.SourceData(this)
            % Model, Time and InputSignal
            SourceData.Model = this.Model;
            SourceData.Time = this.Time;
            SourceData.InputSignal = this.InputSignal;
            % Parameter (if applicable)
            if isa(this.Model,'lpvss')
                SourceData.Parameter = this.Parameter;
            end
            % Config
            SourceData.InitialCondition = this.InitialCondition;
            % Interpolation method
            SourceData.InterpolationMethod = this.InterpolationMethod;
        end

        function set.SourceData(this,SourceData)
            mustBeMember(fields(SourceData),fields(this.SourceData));
            % Model, Time and InputSignal
            this.Model = SourceData.Model;
            this.Time = SourceData.Time;
            this.InputSignal = SourceData.InputSignal;
            % Parameter (if applicable)
            if isa(this.Model,'lpvss')
                this.Parameter = SourceData.Parameter;
            else
                this.Parameter = [];
            end
            % Config
            this.InitialCondition = SourceData.InitialCondition;
            % Interpolation method
            this.InterpolationMethod = SourceData.InterpolationMethod;

            markDirtyAndUpdate(this);
        end

        % TimeUnit
        function TimeUnit = get.TimeUnit(this)
            arguments
                this (1,1) controllib.chart.response.LinearSimulationResponse
            end
            TimeUnit = string(this.Model.TimeUnit);
        end

        % Time
        function Time = get.Time(this)
            arguments
                this (1,1) controllib.chart.response.LinearSimulationResponse
            end
            Time = this.Time_I;
        end
        
        function set.Time(this,Time)
            arguments
                this (1,1) controllib.chart.response.LinearSimulationResponse
                Time (:,1) double {controllib.chart.internal.utils.validators.mustBeTimeVector}
            end
            try
                this.Time_I = Time;
                markDirtyAndUpdate(this);               
            catch ME
                throw(ME);
            end
        end

        % Parameter
        function Parameter = get.Parameter(this)
            arguments
                this (1,1) controllib.chart.response.LinearSimulationResponse
            end
            Parameter = this.Parameter_I;
        end
        
        function set.Parameter(this,Parameter)
            arguments
                this (1,1) controllib.chart.response.LinearSimulationResponse
                Parameter
            end
            try
                this.Parameter_I = Parameter;
                markDirtyAndUpdate(this);               
            catch ME
                throw(ME);
            end
        end

        % InitialCondition
        function InitialCondition = get.InitialCondition(this)
            arguments
                this (1,1) controllib.chart.response.LinearSimulationResponse
            end
            InitialCondition = this.InitialCondition_I;
        end
        
        function set.InitialCondition(this,IC)
            arguments
                this (1,1) controllib.chart.response.LinearSimulationResponse
                IC {mustBeA(IC,["RespConfig","ltipack.OperatingPoint","ltipack.OperatingPoint2"]),mustBeScalarOrEmpty}
            end
            try
                this.InitialCondition_I = IC;
                markDirtyAndUpdate(this);               
            catch ME
                throw(ME);
            end
        end

        % InputSignal
        function InputSignal = get.InputSignal(this)
            arguments
                this (1,1) controllib.chart.response.LinearSimulationResponse
            end
            InputSignal = this.InputSignal_I;
        end
        
        function set.InputSignal(this,InputSignal)
            arguments
                this (1,1) controllib.chart.response.LinearSimulationResponse
                InputSignal (:,:) double
            end
            try
                this.InputSignal_I = InputSignal;
                markDirtyAndUpdate(this);               
            catch ME
                throw(ME);
            end
        end

        % InterpolationMethod
        function InterpolationMethod = get.InterpolationMethod(this)
            arguments
                this (1,1) controllib.chart.response.LinearSimulationResponse
            end
            InterpolationMethod = this.InterpolationMethod_I;
        end
        
        function set.InterpolationMethod(this,InterpolationMethod)
            arguments
                this (1,1) controllib.chart.response.LinearSimulationResponse
                InterpolationMethod (1,1) string {mustBeMember(InterpolationMethod,["auto","zoh","foh"])}
            end
            try
                this.InterpolationMethod_I = InterpolationMethod;
                markDirtyAndUpdate(this);               
            catch ME
                throw(ME);
            end
        end

        % InitialState
        function InitialState = get.InitialState(this)
            if isempty(this.InitialCondition)
				try
					nx = order(this.Model(:,:,1));
				catch
					nx = 1;
				end
				InitialState = zeros(nx,1);
            elseif isa(this.InitialCondition,'ltipack.OperatingPoint')
                InitialState = this.InitialCondition.x;
            elseif isa(this.InitialCondition,'ltipack.OperatingPoint2')
                InitialState = [this.InitialCondition.q;this.InitialCondition.dq];
            else
                InitialState = this.InitialCondition.InitialState;
            end
        end

        function set.InitialState(this,InitialState)
            arguments
                this (1,1) controllib.chart.response.LinearSimulationResponse
                InitialState (:,1) double
            end
            if isempty(this.InitialCondition)
                this.InitialCondition = RespConfig(InitialState=InitialState);
            elseif isa(this.InitialCondition,'ltipack.OperatingPoint')
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
                thisSerialized.rename("Time","Time_I");
                thisSerialized.rename("Parameter","Parameter_I");
                thisSerialized.rename("InputSignal","InputSignal_I");
                thisSerialized.rename("InterpolationMethod","InterpolationMethod_I");
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
                this (1,1) controllib.chart.response.LinearSimulationResponse
            end
            this.ResponseData = controllib.chart.internal.data.response.LinearSimulationDataSource(this.Model,...
                Time=this.Time,InputSignal=this.InputSignal,InterpolationMethod=this.InterpolationMethod,...
                Parameter=this.Parameter,Config=this.InitialCondition);
        end

        function updateData(this)
            arguments
                this (1,1) controllib.chart.response.LinearSimulationResponse
            end
            options.InputSignal = this.InputSignal;
            options.Time = this.Time;
            options.InterpolationMethod = this.InterpolationMethod;
            options.Parameter = this.Parameter;
            options.Config = this.InitialCondition;

            optionsCell = namedargs2cell(options);
            updateData@controllib.chart.internal.foundation.InputOutputModelResponse(this,optionsCell{:},Model=this.Model);
        end
    end
    
    %% Hidden static methods
    methods (Hidden,Static)
        function dataProperties = getDataProperties()
            dataProperties = "SourceData";
        end
    end

    %% Hidden methods
    methods (Hidden)
        function config = qeGetConfig(this)
            config = this.InitialCondition;
        end
    end
end