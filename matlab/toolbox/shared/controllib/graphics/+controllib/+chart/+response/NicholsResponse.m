classdef NicholsResponse < controllib.chart.internal.foundation.InputOutputModelResponse & ...
                        controllib.chart.internal.foundation.MixInControlsModelResponse
    % controllib.chart.response.NicholsResponse
    %   - manage data and style properties for a response in "nicholsplot"
    %   - inherited from controllib.chart.internal.foundation.InputOutputModelResponse
    %
    % h = NicholsResponse(model)
    %   model       DynamicSystem
    % 
    % h = NicholsResponse(_____,Name-Value)
    %   Name                    response name, string, "" (default)
    %   Style                   response style object, controllib.chart.internal.options.ResponseStyle (default)
    %   Tag                     response tag, string, matlab.lang.internal.uuid (default)
    %   LegendDisplay           show response in legend, matlab.lang.OnOffSwitchState, true (default)
    %   Frequency               frequency specification used to generate data, [] (default) auto generates frequency specification
    %
    % Settable properties:
    %   Name                    label for response in chart, string
    %   Visible                 show response in chart, matlab.lang.OnOffSwitchState
    %   Style                   response style object, controllib.chart.internal.options.ResponseStyle
    %   LegendDisplay           show response in legend, matlab.lang.OnOffSwitchState
    %   UserData                custom data, any MATLAB array
    %   Model                   DynamicSystem for response
    %   Frequency               frequency specification used to generate data, double or cell
    %
    % Read-Only properties:
    %   FrequencyUnit    string specifying frequency unit, based on Model TimeUnit.
    %   MagnitudeUnit    string specifying magnitude unit.
    %   PhaseUnit        string specifying phase unit.
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
    properties (Dependent, AbortSet, SetObservable)
        % "SourceData": struct
        % Values used to generate data
        SourceData
    end
    
    properties (Dependent,AbortSet,SetObservable,Access=protected)
        % "FrequencySpec": double vector or 1x2 cell
        % Frequency specification for response.
        FrequencySpec
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
        % "PhaseUnit": string
        % Get PhaseUnit of ResponseData.
        PhaseUnit = "rad"
    end

    properties (GetAccess = protected,SetAccess=private)
        FrequencySpec_I
    end

    properties (Hidden,AbortSet,SetObservable,SetAccess=?controllib.chart.NicholsPlot,Transient,NonCopyable)
        PhaseWrappingBranch = -180
        PhaseMatchingFrequency = 0
        PhaseMatchingValue = 0
    end

    %% Constructor
    methods
        function this = NicholsResponse(modelSource,nicholsResponseOptionalInputs,baseResponseOptionalInputs)
            arguments
                modelSource
                nicholsResponseOptionalInputs.Frequency (:,1) ...
                    {controllib.chart.internal.utils.validators.mustBeFrequencySpec} = []
                baseResponseOptionalInputs.?controllib.chart.internal.foundation.BaseResponseOptionalInputs
            end

            % Create model source if model provided as first argument
            if ~isa(modelSource,'controllib.chart.internal.utils.ModelSource')
                modelSource = controllib.chart.internal.utils.ModelSource(modelSource);
            end

            nicholsResponseOptionalInputs = controllib.chart.response.NicholsResponse.parseNicholsResponseInputs(nicholsResponseOptionalInputs);
            baseResponseOptionalInputs = namedargs2cell(baseResponseOptionalInputs);
            this@controllib.chart.internal.foundation.InputOutputModelResponse(modelSource,baseResponseOptionalInputs{:});
            
            this.FrequencySpec_I = nicholsResponseOptionalInputs.Frequency;

            build(this);

            this.Type = "nichols";
        end
    end

    %% Get/Set
    methods
        % SourceData
        function SourceData = get.SourceData(this)
            % Model
            SourceData.Model = this.Model;
            SourceData.FrequencySpec = this.FrequencySpec;
        end

        function set.SourceData(this,SourceData)
            mustBeMember(fields(SourceData),fields(this.SourceData));
            this.Model = SourceData.Model;
            this.FrequencySpec = SourceData.FrequencySpec;

            markDirtyAndUpdate(this);
        end

        % FrequencyUnit
        function FrequencyUnit = get.FrequencyUnit(this)
            arguments
                this (1,1) controllib.chart.response.NicholsResponse
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
                this (1,1) controllib.chart.response.NicholsResponse
            end
            FrequencySpec = this.FrequencySpec_I;
        end
        
        function set.FrequencySpec(this,FrequencySpec)
            arguments
                this (1,1) controllib.chart.response.NicholsResponse
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

        % PhaseWrappingBranch
        function set.PhaseWrappingBranch(this,PhaseWrappingBranch)
            arguments
                this (1,1) controllib.chart.response.NicholsResponse
                PhaseWrappingBranch (1,1) double
            end
            this.PhaseWrappingBranch = PhaseWrappingBranch;
            if ~isempty(this.ResponseData) && isvalid(this.ResponseData)
                this.ResponseData.PhaseWrappingBranch = PhaseWrappingBranch;
            end            
        end

        % PhaseMatchingFrequency
        function set.PhaseMatchingFrequency(this,PhaseMatchingFrequency)
            arguments
                this (1,1) controllib.chart.response.NicholsResponse
                PhaseMatchingFrequency (1,1) double
            end
            this.PhaseMatchingFrequency = PhaseMatchingFrequency;
            if ~isempty(this.ResponseData) && isvalid(this.ResponseData)
                this.ResponseData.PhaseMatchingFrequency = PhaseMatchingFrequency;
            end            
        end

        % PhaseWrappingBranch
        function set.PhaseMatchingValue(this,PhaseMatchingValue)
            arguments
                this (1,1) controllib.chart.response.NicholsResponse
                PhaseMatchingValue (1,1) double
            end
            this.PhaseMatchingValue = PhaseMatchingValue;
            if ~isempty(this.ResponseData) && isvalid(this.ResponseData)
                this.ResponseData.PhaseMatchingValue = PhaseMatchingValue;
            end            
        end
    end

    %% Static methods
    methods (Static)
        function modifyIncomingSerializationContent(thisSerialized)
            if ~thisSerialized.hasNameValue("Version") %24b
                thisSerialized.rename("Frequency","FrequencySpec_I");
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
                this (1,1) controllib.chart.response.NicholsResponse
            end
            this.ResponseData = controllib.chart.internal.data.response.NicholsResponseDataSource(...
                this.Model,Frequency=this.FrequencySpec,PhaseWrappingBranch=this.PhaseWrappingBranch,...
                PhaseMatchingFrequency=this.PhaseMatchingFrequency,PhaseMatchingValue=this.PhaseMatchingValue);
        end

        function updateData(this,varargin)
            options.Frequency = this.FrequencySpec;
            options = controllib.chart.response.NicholsResponse.parseNicholsResponseInputs(options);
            optionsCell = namedargs2cell(options);
            updateData@controllib.chart.internal.foundation.InputOutputModelResponse(this,varargin{:},optionsCell{:},Model=this.Model);
        end
    end

    %% Private static methods
    methods (Static,Access=private)
        function nicholsResponseOptionalInputs = parseNicholsResponseInputs(nicholsResponseOptionalInputs)
            % Parse Frequency
            if iscell(nicholsResponseOptionalInputs.Frequency)
                nicholsResponseOptionalInputs.Frequency = nicholsResponseOptionalInputs.Frequency(:)';
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

