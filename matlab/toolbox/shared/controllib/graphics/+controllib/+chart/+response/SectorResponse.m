classdef SectorResponse < controllib.chart.internal.foundation.InputOutputModelResponse & ...
                        controllib.chart.internal.foundation.MixInControlsModelResponse
    % controllib.chart.response.SectorResponse
    %   - manage data and style properties for a response in "sectorplot"
    %   - inherited from controllib.chart.internal.foundation.InputOutputModelResponse
    %
    % h = SectorResponse(model,Q)
    %   model       DynamicSystem
    %   Q           sector geometry
    % 
    % h = SectorResponse(_____,Name-Value)
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
    %   Q                       sector geometry, double or DynamicSystem
    %
    % Read-Only properties:
    %   FrequencyUnit    string specifying frequency unit, based on Model TimeUnit.
    %   IndexUnit        string specifying index unit.
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
        % "Q": double matrix or DynamicSystem
        % Sector geometry used to generate data.
        Q
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
        Q_I
        FrequencySpec_I
    end

    %% Constructor
    methods
        function this = SectorResponse(modelSource,Q,sectorResponseOptionalInputs,baseResponseOptionalInputs)
            arguments
                modelSource
                Q {mustBeNonempty}
                sectorResponseOptionalInputs.Frequency (:,1) ...
                    {controllib.chart.internal.utils.validators.mustBeFrequencySpec} = []
                baseResponseOptionalInputs.?controllib.chart.internal.foundation.BaseResponseOptionalInputs
            end

            % Create model source if model provided as first argument
            if ~isa(modelSource,'controllib.chart.internal.utils.ModelSource')
                modelSource = controllib.chart.internal.utils.ModelSource(modelSource);
            end
            
            sectorResponseOptionalInputs = controllib.chart.response.SectorResponse.parseSectorResponseInputs(sectorResponseOptionalInputs);
            baseResponseOptionalInputs = namedargs2cell(baseResponseOptionalInputs);
            this@controllib.chart.internal.foundation.InputOutputModelResponse(modelSource,baseResponseOptionalInputs{:});

            this.Q_I = Q;
            this.FrequencySpec_I = sectorResponseOptionalInputs.Frequency;
            if ~isempty(sectorResponseOptionalInputs.Frequency)
                this.AutoGenerateXData = false;
            end
            build(this);

            this.Type = "sector";
        end
    end

    %% Get/Set
    methods
        % SourceData
        function SourceData = get.SourceData(this)
            % Model
            SourceData.Model = this.Model;
            SourceData.FrequencySpec = this.FrequencySpec;
            SourceData.Q = this.Q;
        end

        function set.SourceData(this,SourceData)
            mustBeMember(fields(SourceData),fields(this.SourceData));
            this.Model = SourceData.Model;
            this.FrequencySpec = SourceData.FrequencySpec;
            this.Q = SourceData.Q;

            markDirtyAndUpdate(this);
        end

        % FrequencySpec
        function FrequencySpec = get.FrequencySpec(this)
            arguments
                this (1,1) controllib.chart.response.SectorResponse
            end
            FrequencySpec = this.FrequencySpec_I;
        end

        function set.FrequencySpec(this,FrequencySpec)
            arguments
                this (1,1) controllib.chart.response.SectorResponse
                FrequencySpec (:,1) {controllib.chart.internal.utils.validators.mustBeFrequencySpec}
            end
            try
                this.FrequencySpec_I = FrequencySpec;
                markDirtyAndUpdate(this);
            catch ME
                throw(ME);
            end
        end

        % FrequencyUnit
        function FrequencyUnit = get.FrequencyUnit(this)
            arguments
                this (1,1) controllib.chart.response.SectorResponse
            end
            if strcmp(this.Model.TimeUnit,'seconds')
                timeUnit = 's';
            else
                timeUnit = this.Model.TimeUnit(1:end-1);
            end
            FrequencyUnit = string(['rad/',timeUnit]);
        end

        % Q
        function Q = get.Q(this)
            arguments
                this (1,1) controllib.chart.response.SectorResponse
            end
            Q = this.Q_I;
        end

        function set.Q(this,Q)
            arguments
                this (1,1) controllib.chart.response.SectorResponse
                Q
            end
            try
                this.Q_I = Q;
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
                this (1,1) controllib.chart.response.SectorResponse
            end
            this.ResponseData = controllib.chart.internal.data.response.SectorResponseDataSource(...
                this.Model,this.Q,Frequency=this.FrequencySpec_I);
        end

        function updateData(this)
            arguments
                this (1,1) controllib.chart.response.SectorResponse
            end
            options.Q = this.Q_I;
            options.Frequency = this.FrequencySpec_I;
            options = controllib.chart.response.SectorResponse.parseSectorResponseInputs(options);
            optionsCell = namedargs2cell(options);
            updateData@controllib.chart.internal.foundation.InputOutputModelResponse(this,optionsCell{:},Model=this.Model);
        end
    end

    %% Private static methods
    methods (Static,Access=private)
        function sectorResponseOptionalInputs = parseSectorResponseInputs(sectorResponseOptionalInputs)
            % Parse Frequency
            if iscell(sectorResponseOptionalInputs.Frequency)
                sectorResponseOptionalInputs.Frequency = sectorResponseOptionalInputs.Frequency(:)';
            end
        end
    end
end

