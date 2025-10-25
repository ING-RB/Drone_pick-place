classdef PassiveResponse < controllib.chart.internal.foundation.InputOutputModelResponse & ...
                        controllib.chart.internal.foundation.MixInControlsModelResponse
    % controllib.chart.response.PassiveResponse
    %   - manage data and style properties for a response in "passiveplot"
    %   - inherited from controllib.chart.internal.foundation.InputOutputModelResponse
    %
    % h = PassiveResponse(model)
    %   model       DynamicSystem
    % 
    % h = PassiveResponse(_____,Name-Value)
    %   Name                    response name, string, "" (default)
    %   Style                   response style object, controllib.chart.internal.options.ResponseStyle (default)
    %   Tag                     response tag, string, matlab.lang.internal.uuid (default)
    %   LegendDisplay           show response in legend, matlab.lang.OnOffSwitchState, true (default)
    %   Frequency               frequency specification used to generate data, [] (default) auto generates frequency specification
    %   PassiveType             type of passivity index response, "relative" (default) 
    %
    % Settable properties:
    %   Name                    label for response in chart, string
    %   Visible                 show response in chart, matlab.lang.OnOffSwitchState
    %   Style                   response style object, controllib.chart.internal.options.ResponseStyle
    %   LegendDisplay           show response in legend, matlab.lang.OnOffSwitchState
    %   UserData                custom data, any MATLAB array
    %   Model                   DynamicSystem for response
    %   Frequency               frequency specification used to generate data, double or cell
    %   PassiveType             type of passivity index response, string
    %
    % Events:
    %   ResponseChanged      notified after update is called
    %   ResponseDeleted      notified after delete is called
    %   StyleChanged         notified after Style object is changed
    %
    % Read-Only properties:
    %   FrequencyUnit    string specifying frequency unit, based on Model TimeUnit.
    %   IndexUnit        string specifying index unit.
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

    % Copyright 2023-2024 The MathWorks, Inc.

    %% Properties
    properties (Hidden,Dependent, AbortSet, SetObservable)
        % "SourceData": struct
        % Values used to generate data
        SourceData
    end

    properties (Dependent,AbortSet,SetObservable,Access=protected)
        % "FrequencySpec": double vector or 1x2 cell
        % Frequency specification used to generate data.
        FrequencySpec
        % "PassiveType": string scalar
        % Type of passivity index response.
        PassiveType
    end

    properties (Hidden,Dependent,SetAccess=private)
        % "FrequencyUnit": string
        % Get FrequencyUnit of Model.
        FrequencyUnit
    end

    properties (Hidden,Constant)
        % "IndexUnit": string
        % Get IndexUnit of ResponseData.
        IndexUnit = "abs"
    end

    properties (GetAccess = protected,SetAccess=private)
        PassiveType_I
        FrequencySpec_I
    end  

    %% Constructor
    methods
        function this = PassiveResponse(modelSource,passiveResponseOptionalInputs,baseResponseOptionalInputs)
            arguments
                modelSource
                passiveResponseOptionalInputs.PassiveType (1,1) string ...
                    {mustBeMember(passiveResponseOptionalInputs.PassiveType,["input","output","io","relative"])} = "relative"; 
                passiveResponseOptionalInputs.Frequency (:,1) ...
                    {controllib.chart.internal.utils.validators.mustBeFrequencySpec} = []
                baseResponseOptionalInputs.?controllib.chart.internal.foundation.BaseResponseOptionalInputs
            end

            % Create model source if model provided as first argument
            if ~isa(modelSource,'controllib.chart.internal.utils.ModelSource')
                modelSource = controllib.chart.internal.utils.ModelSource(modelSource);
            end
            
            passiveResponseOptionalInputs = controllib.chart.response.PassiveResponse.parsePassiveResponseInputs(passiveResponseOptionalInputs);
            baseResponseOptionalInputs = namedargs2cell(baseResponseOptionalInputs);
            this@controllib.chart.internal.foundation.InputOutputModelResponse(modelSource,baseResponseOptionalInputs{:});
            this.PassiveType = passiveResponseOptionalInputs.PassiveType;
            this.FrequencySpec_I = passiveResponseOptionalInputs.Frequency;
            if ~isempty(passiveResponseOptionalInputs.Frequency)
                this.AutoGenerateXData = false;
            end
            build(this);

            this.Type = "passive";
        end
    end

    %% Get/Set
    methods
        % SourceData
        function SourceData = get.SourceData(this)
            % Model
            SourceData.Model = this.Model;
            SourceData.FrequencySpec = this.FrequencySpec;
            SourceData.PassiveType = this.PassiveType;
        end

        function set.SourceData(this,SourceData)
            mustBeMember(fields(SourceData),fields(this.SourceData));
            this.Model = SourceData.Model;
            this.FrequencySpec = SourceData.FrequencySpec;
            this.PassiveType = SourceData.PassiveType;

            markDirtyAndUpdate(this);
        end

        % FrequencySpec
        function FrequencySpec = get.FrequencySpec(this)
            arguments
                this (1,1) controllib.chart.response.PassiveResponse
            end
            FrequencySpec = this.FrequencySpec_I;
        end

        function set.FrequencySpec(this,FrequencySpec)
            arguments
                this (1,1) controllib.chart.response.PassiveResponse
                FrequencySpec (:,1) {controllib.chart.internal.utils.validators.mustBeFrequencySpec}
            end
            try
                if iscell(FrequencySpec)
                    FrequencySpec = FrequencySpec';
                end
                this.FrequencySpec_I = FrequencySpec;
                markDirtyAndUpdate(this);
            catch ME
                throw(ME);
            end
        end   
        
        % FrequencyUnit
        function FrequencyUnit = get.FrequencyUnit(this)
            arguments
                this (1,1) controllib.chart.response.PassiveResponse
            end
            if strcmp(this.Model.TimeUnit,'seconds')
                timeUnit = 's';
            else
                timeUnit = this.Model.TimeUnit(1:end-1);
            end
            FrequencyUnit = string(['rad/',timeUnit]);
        end

        % PassiveType
        function PassiveType = get.PassiveType(this)
            arguments
                this (1,1) controllib.chart.response.PassiveResponse
            end
            PassiveType = this.PassiveType_I;
        end

        function set.PassiveType(this,PassiveType)
            arguments
                this (1,1) controllib.chart.response.PassiveResponse
                PassiveType (1,1) string {mustBeMember(PassiveType,["input","output","io","relative"])}
            end
            try
                this.PassiveType_I = PassiveType;
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
                thisSerialized.rename("Frequency_I","FrequencySpec_I");
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
                this (1,1) controllib.chart.response.PassiveResponse
            end
            this.ResponseData = controllib.chart.internal.data.response.PassiveResponseDataSource(...
                this.Model,PassiveType=this.PassiveType,Frequency=this.FrequencySpec);
        end

        function updateData(this)
            arguments
                this (1,1) controllib.chart.response.PassiveResponse
            end
            options.PassiveType = this.PassiveType;
            options.Frequency = this.FrequencySpec;
            options = controllib.chart.response.PassiveResponse.parsePassiveResponseInputs(options);
            optionsCell = namedargs2cell(options);
            updateData@controllib.chart.internal.foundation.InputOutputModelResponse(this,optionsCell{:},Model=this.Model);
        end
    end

    %% Private static methods
    methods (Static,Access=private)
        function passiveResponseOptionalInputs = parsePassiveResponseInputs(passiveResponseOptionalInputs)
            % Parse Frequency
            if iscell(passiveResponseOptionalInputs.Frequency)
                passiveResponseOptionalInputs.Frequency = passiveResponseOptionalInputs.Frequency(:)';
            end
        end
    end
end

