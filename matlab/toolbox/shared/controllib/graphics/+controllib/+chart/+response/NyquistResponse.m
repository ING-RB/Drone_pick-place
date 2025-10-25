classdef NyquistResponse < controllib.chart.internal.foundation.InputOutputModelResponse & ...
                        controllib.chart.internal.foundation.MixInControlsModelResponse
    % controllib.chart.response.NyquistResponse
    %   - manage data and style properties for a response in "nyquistplot"
    %   - inherited from controllib.chart.internal.foundation.InputOutputModelResponse
    %
    % h = NyquistResponse(model)
    %   model       DynamicSystem
    % 
    % h = NyquistResponse(_____,Name-Value)
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
        NumberOfStandardDeviations_I
        ConfidenceDisplaySampling_I
    end
    
    %% Constructor
    methods
        function this = NyquistResponse(modelSource,nyquistResponseOptionalInputs,baseResponseOptionalInputs)
            arguments
                modelSource
                nyquistResponseOptionalInputs.Frequency (:,1) ...
                    {controllib.chart.internal.utils.validators.mustBeFrequencySpec} = []
                nyquistResponseOptionalInputs.NumberOfStandardDeviations (1,1) double = get(nyquistoptions('cstprefs'),'ConfidenceRegionNumberSD')
                nyquistResponseOptionalInputs.ConfidenceDisplaySampling (1,1) double = get(nyquistoptions('cstprefs'),'ConfidenceRegionDisplaySpacing')
                baseResponseOptionalInputs.?controllib.chart.internal.foundation.BaseResponseOptionalInputs
            end
            
            % Create model source if model provided as first argument
            if ~isa(modelSource,'controllib.chart.internal.utils.ModelSource')
                modelSource = controllib.chart.internal.utils.ModelSource(modelSource);
            end

            nyquistResponseOptionalInputs = controllib.chart.response.NyquistResponse.parseNyquistResponseInputs(nyquistResponseOptionalInputs);
            baseResponseOptionalInputs = namedargs2cell(baseResponseOptionalInputs);
            this@controllib.chart.internal.foundation.InputOutputModelResponse(modelSource,baseResponseOptionalInputs{:});
            
            this.FrequencySpec_I = nyquistResponseOptionalInputs.Frequency;
            this.NumberOfStandardDeviations_I = nyquistResponseOptionalInputs.NumberOfStandardDeviations;
            this.ConfidenceDisplaySampling_I = nyquistResponseOptionalInputs.ConfidenceDisplaySampling;

            build(this);

            this.Type = "nyquist";

            if isa(modelSource.Model,'idlti')
                p = addprop(this,'NumberOfStandardDeviations');
                p.Hidden = 1;
                p.Dependent = 1;
                p.AbortSet = 1;
                p.SetObservable = 1;
                p.GetMethod = @getNumberOfStandardDeviations;
                p.SetMethod = @setNumberOfStandardDeviations;
                p = addprop(this,'ConfidenceDisplaySampling');
                p.Hidden = 1;
                p.Dependent = 1;
                p.AbortSet = 1;
                p.SetObservable = 1;
                p.GetMethod = @getConfidenceDisplaySampling;
                p.SetMethod = @setConfidenceDisplaySampling;
            end
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
                this (1,1) controllib.chart.response.NyquistResponse
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
                this (1,1) controllib.chart.response.NyquistResponse
            end
            FrequencySpec = this.FrequencySpec_I;
        end
        
        function set.FrequencySpec(this,FrequencySpec)
            arguments
                this (1,1) controllib.chart.response.NyquistResponse
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
    end

    %% Get/Set dynamic props
    methods (Access = private)
        % NumberOfStandardDeviations
        function NumberOfStandardDeviations = getNumberOfStandardDeviations(this)
            arguments
                this (1,1) controllib.chart.response.NyquistResponse
            end
            NumberOfStandardDeviations = this.NumberOfStandardDeviations_I;
        end
        
        function setNumberOfStandardDeviations(this,NumberOfStandardDeviations)
            arguments
                this (1,1) controllib.chart.response.NyquistResponse
                NumberOfStandardDeviations (1,1) double
            end
            try
                this.NumberOfStandardDeviations_I = NumberOfStandardDeviations;
                markDirtyAndUpdate(this);
            catch ME
                throw(ME);
            end
        end

        % DisplaySpacing
        function ConfidenceDisplaySampling = getConfidenceDisplaySampling(this)
            arguments
                this (1,1) controllib.chart.response.NyquistResponse
            end
            ConfidenceDisplaySampling = this.ConfidenceDisplaySampling_I;
        end
        
        function setConfidenceDisplaySampling(this,ConfidenceDisplaySampling)
            arguments
                this (1,1) controllib.chart.response.NyquistResponse
                ConfidenceDisplaySampling (1,1) double
            end
            try
                this.ConfidenceDisplaySampling_I = ConfidenceDisplaySampling;
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
            if isa(this.Model,'idlti') && ~isprop(this,'ConfidenceDisplaySampling')
                p = addprop(this,'ConfidenceDisplaySampling');
                p.Hidden = 1;
                p.Dependent = 1;
                p.AbortSet = 1;
                p.SetObservable = 1;
                p.GetMethod = @getConfidenceDisplaySampling;
                p.SetMethod = @setConfidenceDisplaySampling;
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
                this (1,1) controllib.chart.response.NyquistResponse
            end
            this.ResponseData = controllib.chart.internal.data.response.NyquistResponseDataSource(...
                this.Model,Frequency=this.FrequencySpec,NumberOfStandardDeviations=this.NumberOfStandardDeviations_I,...
                ConfidenceDisplaySampling=this.ConfidenceDisplaySampling_I);
        end

        function updateData(this)
            arguments
                this (1,1) controllib.chart.response.NyquistResponse
            end
            options.Frequency = this.FrequencySpec;
            options.NumberOfStandardDeviations = this.NumberOfStandardDeviations_I;
            options.ConfidenceDisplaySampling = this.ConfidenceDisplaySampling_I;
            options = controllib.chart.response.NyquistResponse.parseNyquistResponseInputs(options);
            optionsCell = namedargs2cell(options);
            updateData@controllib.chart.internal.foundation.InputOutputModelResponse(this,optionsCell{:},Model=this.Model);

            if isa(this.Model,'idlti') && ~isprop(this,'NumberOfStandardDeviations')
                p = addprop(this,'NumberOfStandardDeviations');
                p.Hidden = 1;
                p.Dependent = 1;
                p.AbortSet = 1;
                p.SetObservable = 1;
                p.GetMethod = @getNumberOfStandardDeviations;
                p.SetMethod = @setNumberOfStandardDeviations;
                p = addprop(this,'ConfidenceDisplaySampling');
                p.Hidden = 1;
                p.Dependent = 1;
                p.AbortSet = 1;
                p.SetObservable = 1;
                p.GetMethod = @getConfidenceDisplaySampling;
                p.SetMethod = @setConfidenceDisplaySampling;
            elseif ~isa(this.Model,'idlti') && isprop(this,'NumberOfStandardDeviations')
                p = findprop(this,'NumberOfStandardDeviations');
                delete(p);
                p = findprop(this,'ConfidenceDisplaySampling');
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
                p = addprop(thisCopy,'ConfidenceDisplaySampling');
                p.Hidden = 1;
                p.Dependent = 1;
                p.AbortSet = 1;
                p.SetObservable = 1;
                p.GetMethod = @getConfidenceDisplaySampling;
                p.SetMethod = @setConfidenceDisplaySampling;
            end
        end
    end

    %% Private static methods
    methods (Static,Access=private)
        function nyquistResponseOptionalInputs = parseNyquistResponseInputs(nyquistResponseOptionalInputs)
            % Parse Frequency
            if iscell(nyquistResponseOptionalInputs.Frequency)
                nyquistResponseOptionalInputs.Frequency = nyquistResponseOptionalInputs.Frequency(:)';
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

