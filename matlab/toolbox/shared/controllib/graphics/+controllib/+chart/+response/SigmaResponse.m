classdef SigmaResponse < controllib.chart.internal.foundation.InputOutputModelResponse & ...
                        controllib.chart.internal.foundation.MixInControlsModelResponse
    % controllib.chart.response.SigmaResponse
    %   - manage data and style properties for a response in "sigmaplot"
    %   - inherited from controllib.chart.internal.foundation.InputOutputModelResponse
    %
    % h = SigmaResponse(model)
    %   model       DynamicSystem
    % 
    % h = SigmaResponse(_____,Name-Value)
    %   Name                    response name, string, "" (default)
    %   Style                   response style object, controllib.chart.internal.options.ResponseStyle (default)
    %   Tag                     response tag, string, matlab.lang.internal.uuid (default)
    %   LegendDisplay           show response in legend, matlab.lang.OnOffSwitchState, true (default)
    %   Frequency               frequency specification used to generate data, [] (default) auto generates frequency specification
    %   SingularValueType       type of singular value response, 0 (default) plots the SV of H
    %
    % Settable properties:
    %   Name                    label for response in chart, string
    %   Visible                 show response in chart, matlab.lang.OnOffSwitchState
    %   Style                   response style object, controllib.chart.internal.options.ResponseStyle
    %   LegendDisplay           show response in legend, matlab.lang.OnOffSwitchState
    %   UserData                custom data, any MATLAB array
    %   Model                   DynamicSystem for response
    %   Frequency               frequency specification used to generate data, double or cell
    %   SingularValueType       type of singular value response, double
    %
    % Read-Only properties:
    %   FrequencyUnit    string specifying frequency unit, based on Model TimeUnit.
    %   MagnitudeUnit    string specifying magnitude unit.
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

    % Copyright 2022-2024 The MathWorks, Inc.
    
    %% Properties
    properties(Dependent, AbortSet, SetObservable)
        % "SourceData": struct
        % Values used to generate data
        SourceData
    end
    
    properties (Dependent,AbortSet,SetObservable,Access=protected)
        % "FrequencySpec": double vector or 1x2 cell
        % Frequency specification for response.
        FrequencySpec
        % "SingularValueType": double scalar
        % Type of singular value response.
        SingularValueType
    end

    properties (Hidden,Dependent,SetAccess=private)
        % "FrequencyUnit": string
        % Get FrequencyUnit of Model.
        FrequencyUnit
    end

    properties (Hidden,Constant)
        % "MagnitudeUnit": string
        % Get MagnitudeUnit of ResponseData.
        MagnitudeUnit = "abs"
    end

    properties (GetAccess = protected,SetAccess=private)
        FrequencySpec_I
        SingularValueType_I
    end
    
    %% Clean up property later
    properties(Hidden, Access = {?TuningGoal.Generic,?controllib.chart.internal.view.wave.SigmaResponseView,...
            ?controllib.chart.internal.view.wave.data.ResponseWrapper})
        UseMaximumSingularValue = false
    end
    
    %% Constructor
    methods
        function this = SigmaResponse(modelSource,sigmaResponseOptionalInputs,baseResponseOptionalInputs)
            arguments
                modelSource
                sigmaResponseOptionalInputs.SingularValueType (1,1) double...
                    {mustBeMember(sigmaResponseOptionalInputs.SingularValueType,[0 1 2 3])} = 0
                sigmaResponseOptionalInputs.Frequency (:,1) ...
                    {controllib.chart.internal.utils.validators.mustBeFrequencySpec} = []
                baseResponseOptionalInputs.?controllib.chart.internal.foundation.BaseResponseOptionalInputs
            end

            % Create model source if model provided as first argument
            if ~isa(modelSource,'controllib.chart.internal.utils.ModelSource')
                modelSource = controllib.chart.internal.utils.ModelSource(modelSource);
            end

            sigmaResponseOptionalInputs = controllib.chart.response.SigmaResponse.parseSigmaResponseInputs(sigmaResponseOptionalInputs);            
            baseResponseOptionalInputs = namedargs2cell(baseResponseOptionalInputs);
            this@controllib.chart.internal.foundation.InputOutputModelResponse(modelSource,baseResponseOptionalInputs{:});

            this.SingularValueType_I = sigmaResponseOptionalInputs.SingularValueType;
            this.FrequencySpec_I = sigmaResponseOptionalInputs.Frequency;
            if ~isempty(sigmaResponseOptionalInputs.Frequency)
                this.AutoGenerateXData = false;
            end
            build(this);

            this.Type = "sigma";
        end
    end

    %% Get/Set
    methods
        % SourceData
        function SourceData = get.SourceData(this)
            % Model
            SourceData.Model = this.Model;
            SourceData.FrequencySpec = this.FrequencySpec_I;
            SourceData.SingularValueType = this.SingularValueType_I;
        end

        function set.SourceData(this,SourceData)
            mustBeMember(fields(SourceData),fields(this.SourceData));
            this.Model = SourceData.Model;
            this.FrequencySpec_I = SourceData.FrequencySpec;
            this.SingularValueType_I = SourceData.SingularValueType;

            markDirtyAndUpdate(this);
        end

        % FrequencyUnit
        function FrequencyUnit = get.FrequencyUnit(this)
            arguments
                this (1,1) controllib.chart.response.SigmaResponse
            end
            if strcmp(this.Model.TimeUnit,'seconds')
                timeUnit = 's';
            else
                timeUnit = this.Model.TimeUnit(1:end-1);
            end
            FrequencyUnit = string(['rad/',timeUnit]);
        end

        % FrequencySpec
        function FrequencySpec = get.FrequencySpec(this)
            arguments
                this (1,1) controllib.chart.response.SigmaResponse
            end
            FrequencySpec = this.FrequencySpec_I;
        end
        
        function set.FrequencySpec(this,FrequencySpec)
            arguments
                this (1,1) controllib.chart.response.SigmaResponse
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

        % SingularValueType
        function SingularValueType = get.SingularValueType(this)
            arguments
                this (1,1) controllib.chart.response.SigmaResponse
            end
            SingularValueType = this.SingularValueType_I;
        end
        
        function set.SingularValueType(this,SingularValueType)
            arguments
                this (1,1) controllib.chart.response.SigmaResponse
                SingularValueType (1,1) double {mustBeMember(SingularValueType,[0 1 2 3])}
            end
            try
                this.SingularValueType_I = SingularValueType;
                markDirtyAndUpdate(this);               
            catch ME
                throw(ME);
            end
        end

        % UseMaximumSingularValue
        function set.UseMaximumSingularValue(this,Flag)
            arguments
                this (1,1) controllib.chart.response.SigmaResponse
                Flag (1,1) logical
            end
            this.UseMaximumSingularValue = Flag;
            notify(this,'ResponseChanged');
        end
    end

    %% Static methods
    methods (Static)
        function modifyIncomingSerializationContent(thisSerialized)
            if ~thisSerialized.hasNameValue("Version") %24b
                thisSerialized.rename("Frequency","FrequencySpec_I");
                thisSerialized.rename("SingularValueType","SingularValueType_I");
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
                this (1,1) controllib.chart.response.SigmaResponse
            end
            this.ResponseData = controllib.chart.internal.data.response.SigmaResponseDataSource(...
                this.Model,Frequency=this.FrequencySpec_I,SingularValueType=this.SingularValueType_I);
        end

        function updateData(this)
            arguments
                this (1,1) controllib.chart.response.SigmaResponse
            end
            options.SingularValueType = this.SingularValueType_I;
            options.Frequency = this.FrequencySpec_I;
            this.AutoGenerateXData = isempty(options.Frequency);
            options = controllib.chart.response.SigmaResponse.parseSigmaResponseInputs(options);
            optionsCell = namedargs2cell(options);
            updateData@controllib.chart.internal.foundation.InputOutputModelResponse(this,optionsCell{:},Model=this.Model);
        end
    end

    %% Private static methods
    methods (Static,Access=private)
        function sigmaResponseOptionalInputs = parseSigmaResponseInputs(sigmaResponseOptionalInputs)
            % Parse Frequency
            if iscell(sigmaResponseOptionalInputs.Frequency)
                sigmaResponseOptionalInputs.Frequency = sigmaResponseOptionalInputs.Frequency(:)';
            end
        end
    end

    %% Hidden static methods
    methods (Hidden,Static)
        function dataProperties = getDataProperties()
            dataProperties = "SourceData";
        end
    end

    %% Hidden TuningGoal methods
    methods (Hidden, Access = {?TuningGoal.Generic,...
            ?controllib.chart.response.SigmaResponse})
        function value = getMaximumValue(this)
            arguments
                this (1,1) controllib.chart.response.SigmaResponse
            end
            value = -inf;
            for ii = 1:numel(this.ResponseData.SingularValue)
                value = max(value,max(this.ResponseData.SingularValue{ii},[],"all"));
            end
        end
    end
end

