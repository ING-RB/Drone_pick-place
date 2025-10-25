classdef BodeResponse < controllib.chart.internal.foundation.InputOutputModelResponse & ...
                        controllib.chart.internal.foundation.MixInControlsModelResponse
    % controllib.chart.response.BodeResponse
    %   - manage data and style properties for a response in "bodeplot"
    %   - inherited from controllib.chart.internal.foundation.InputOutputModelResponse
    %
    % h = BodeResponse(model)
    %   model       DynamicSystem
    % 
    % h = BodeResponse(_____,Name-Value)
    %   Name                    response name, string, "" (default)
    %   Style                   response style object, controllib.chart.internal.options.ResponseStyle (default)
    %   Tag                     response tag, string, matlab.lang.internal.uuid (default)
    %   LegendDisplay           show response in legend, matlab.lang.OnOffSwitchState, true (default)
    %   Frequency               frequency specification used to generate data, [] (default) auto generates frequency specification
    %   NumberOfStandardDeviations  standard deviation used to show confidence region for identified models
    %
    % Settable properties:
    %   Name                    label for response in chart, string
    %   Visible                 show response in chart, matlab.lang.OnOffSwitchState
    %   Style                   response style object, controllib.chart.internal.options.ResponseStyle
    %   LegendDisplay           show response in legend, matlab.lang.OnOffSwitchState
    %   UserData                custom data, any MATLAB array
    %   Model                   DynamicSystem for response
    %   Frequency               frequency specification used to generate data, double or cell
    %   NumberOfStandardDeviations  standard deviation used to show confidence region for identified models
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
    %       Creates the response data. Can call in subclass
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
        NumberOfStandardDeviations_I
    end

    properties (Hidden,AbortSet,SetObservable,SetAccess=?controllib.chart.internal.foundation.MagnitudePhaseFrequencyPlot,Transient,NonCopyable)
        PhaseWrappingBranch = -180
        PhaseMatchingFrequency = 0
        PhaseMatchingValue = 0
    end
    
    %% Constructor
    methods
        function this = BodeResponse(modelSource,bodeResponseOptionalInputs,baseResponseOptionalInputs)
            arguments
                modelSource
                bodeResponseOptionalInputs.Frequency (:,1) ...
                    {controllib.chart.internal.utils.validators.mustBeFrequencySpec} = []
                bodeResponseOptionalInputs.NumberOfStandardDeviations (1,1) double = get(bodeoptions('cstprefs'),'ConfidenceRegionNumberSD')
                baseResponseOptionalInputs.?controllib.chart.internal.foundation.BaseResponseOptionalInputs
            end

            % Create model source if model provided as first argument
            % if ~isa(modelSource,'controllib.chart.internal.utils.ModelSource')
            %     modelSource = createPlotSource(modelSource);
            % end

            bodeResponseOptionalInputs = controllib.chart.response.BodeResponse.parseBodeResponseInputs(bodeResponseOptionalInputs);
            baseResponseOptionalInputs = namedargs2cell(baseResponseOptionalInputs);
            this@controllib.chart.internal.foundation.InputOutputModelResponse(modelSource,baseResponseOptionalInputs{:});
            
            modelSource = this.ModelSource;
            
            this.FrequencySpec_I = bodeResponseOptionalInputs.Frequency;
            this.NumberOfStandardDeviations_I = bodeResponseOptionalInputs.NumberOfStandardDeviations;
            if ~isempty(bodeResponseOptionalInputs.Frequency)
                this.AutoGenerateXData = false;
            end
            build(this);

            this.Type = "bode";

            if isa(modelSource.Model,'idlti')
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
                this (1,1) controllib.chart.response.BodeResponse
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
                this (1,1) controllib.chart.response.BodeResponse
            end
            FrequencySpec = this.FrequencySpec_I;
        end
        
        function set.FrequencySpec(this,FrequencySpec)
            arguments
                this (1,1) controllib.chart.response.BodeResponse
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
                this (1,1) controllib.chart.response.BodeResponse
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
                this (1,1) controllib.chart.response.BodeResponse
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
                this (1,1) controllib.chart.response.BodeResponse
                PhaseMatchingValue (1,1) double
            end
            this.PhaseMatchingValue = PhaseMatchingValue;
            if ~isempty(this.ResponseData) && isvalid(this.ResponseData)
                this.ResponseData.PhaseMatchingValue = PhaseMatchingValue;
            end            
        end
    end
	
    %% Get/Set dynamic props
    methods (Access = private)
        % NumberOfStandardDeviations
        function NumberOfStandardDeviations = getNumberOfStandardDeviations(this)
            arguments
                this (1,1) controllib.chart.response.BodeResponse
            end
            NumberOfStandardDeviations = this.NumberOfStandardDeviations_I;
        end
        
        function setNumberOfStandardDeviations(this,NumberOfStandardDeviations)
            arguments
                this (1,1) controllib.chart.response.BodeResponse
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
                thisSerialized.rename("Frequency","FrequencySpec_I");
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
                this (1,1) controllib.chart.response.BodeResponse
            end
            this.ResponseData = controllib.chart.internal.data.response.BodeResponseDataSource(this.Model,...
                Frequency=this.FrequencySpec,NumberOfStandardDeviations=this.NumberOfStandardDeviations_I,...
                PhaseWrappingBranch=this.PhaseWrappingBranch,PhaseMatchingFrequency=this.PhaseMatchingFrequency,...
                PhaseMatchingValue=this.PhaseMatchingValue);
        end

        function updateData(this,varargin)
            options.Frequency = this.FrequencySpec;
            options.NumberOfStandardDeviations = this.NumberOfStandardDeviations_I;
            options = controllib.chart.response.BodeResponse.parseBodeResponseInputs(options);
            optionsCell = namedargs2cell(options);

            this.AutoGenerateXData = isempty(options.Frequency);
            updateData@controllib.chart.internal.foundation.InputOutputModelResponse(this,varargin{:},optionsCell{:},Model=this.Model);
            
            if isa(this.Model,'idlti') && ~isprop(this,'NumberOfStandardDeviations')
                p = addprop(this,'NumberOfStandardDeviations');
                p.Hidden = 1;
                p.Dependent = 1;
                p.AbortSet = 1;
                p.SetObservable = 1;
                p.GetMethod = @getNumberOfStandardDeviations;
                p.SetMethod = @setNumberOfStandardDeviations;
            elseif ~isa(this.Model,'idlti') && isprop(this,'NumberOfStandardDeviations')
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
        function bodeResponseOptionalInputs = parseBodeResponseInputs(bodeResponseOptionalInputs)
            % Parse Frequency
            if iscell(bodeResponseOptionalInputs.Frequency)
                bodeResponseOptionalInputs.Frequency = bodeResponseOptionalInputs.Frequency(:)';
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

