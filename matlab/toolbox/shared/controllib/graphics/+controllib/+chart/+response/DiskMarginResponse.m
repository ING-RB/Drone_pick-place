classdef DiskMarginResponse < controllib.chart.internal.foundation.InputOutputModelResponse & ...
                        controllib.chart.internal.foundation.MixInControlsModelResponse
    % controllib.chart.response.DiskMarginResponse
    %   - manage data and style properties for a response in "diskmarginplot"
    %   - inherited from controllib.chart.internal.foundation.InputOutputModelResponse
    %
    % h = DiskMarginResponse(model)
    %   model       DynamicSystem
    % 
    % h = DiskMarginResponse(_____,Name-Value)
    %   Name                    response name, string, "" (default)
    %   Style                   response style object, controllib.chart.internal.options.ResponseStyle (default)
    %   Tag                     response tag, string, matlab.lang.internal.uuid (default)
    %   LegendDisplay           show response in legend, matlab.lang.OnOffSwitchState, true (default)
    %   Frequency               frequency specification used to generate data, [] (default) auto generates frequency specification
    %   Skew                    skew of uncertainty region used to compute the stability margins, 0 (default)
    %
    % Settable properties:
    %   Name                    label for response in chart, string
    %   Visible                 show response in chart, matlab.lang.OnOffSwitchState
    %   Style                   response style object, controllib.chart.internal.options.ResponseStyle
    %   LegendDisplay           show response in legend, matlab.lang.OnOffSwitchState
    %   UserData                custom data, any MATLAB array
    %   Model                   DynamicSystem for response
    %   Frequency               frequency specification used to generate data, double or cell
    %   Skew                    skew of uncertainty region used to compute the stability margins, double
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

    % Copyright 2023-2024 The MathWorks, Inc.

    %% Properties
    properties(Hidden, Dependent, AbortSet, SetObservable)
        % "SourceData": struct
        % Values used to generate data
        SourceData
    end
    
    properties (Dependent,AbortSet,SetObservable,Access=protected)
        % "FrequencySpec": double vector or 1x2 cell
        % Frequency specification for response.
        FrequencySpec
        % "Skew": double vector
        % Skew of uncertainty region.
        Skew
        % "IsStable": logical matrix
        % Stability information for Model.
        IsStable
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
        PhaseUnit = "deg"
    end

    properties (GetAccess = protected,SetAccess=private)
        FrequencySpec_I
        Skew_I
        IsStable_I
    end
    
    %% Constructor
    methods
        function this = DiskMarginResponse(modelSource,diskMarginResponseOptionalInputs,baseResponseOptionalInputs)
            arguments
                modelSource
                diskMarginResponseOptionalInputs.Skew (1,1) double = 0
                diskMarginResponseOptionalInputs.Frequency (:,1) ...
                    {controllib.chart.internal.utils.validators.mustBeFrequencySpec} = []
                baseResponseOptionalInputs.?controllib.chart.internal.foundation.BaseResponseOptionalInputs
            end

            % Create model source if model provided as first argument
            if ~isa(modelSource,'controllib.chart.internal.utils.ModelSource')
                modelSource = controllib.chart.internal.utils.ModelSource(modelSource);
            end

            diskMarginResponseOptionalInputs = controllib.chart.response.DiskMarginResponse.parseDiskMarginResponseInputs(diskMarginResponseOptionalInputs);
            baseResponseOptionalInputs = namedargs2cell(baseResponseOptionalInputs);
            this@controllib.chart.internal.foundation.InputOutputModelResponse(modelSource,baseResponseOptionalInputs{:});

            this.FrequencySpec_I = diskMarginResponseOptionalInputs.Frequency;
            this.Skew_I = diskMarginResponseOptionalInputs.Skew;
            if ~isempty(diskMarginResponseOptionalInputs.Frequency)
                this.AutoGenerateXData = false;
            end
            build(this);

            this.Type = "diskmargin";
        end
    end

    %% Get/Set
    methods
        % SourceData
        function SourceData = get.SourceData(this)
            % Model
            SourceData.Model = this.Model;
            SourceData.FrequencySpec = this.FrequencySpec;
            SourceData.Skew = this.Skew;
            SourceData.IsStable = this.IsStable;
        end

        function set.SourceData(this,SourceData)
            mustBeMember(fields(SourceData),fields(this.SourceData));
            this.Model = SourceData.Model;
            this.FrequencySpec = SourceData.FrequencySpec;
            this.Skew = SourceData.Skew;
            this.IsStable = SourceData.IsStable;

            markDirtyAndUpdate(this);
        end

        % FrequencyUnit
        function FrequencyUnit = get.FrequencyUnit(this)
            arguments
                this (1,1) controllib.chart.response.DiskMarginResponse
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
                this (1,1) controllib.chart.response.DiskMarginResponse
            end
            FrequencySpec = this.FrequencySpec_I;
        end
        
        function set.FrequencySpec(this,FrequencySpec)
            arguments
                this (1,1) controllib.chart.response.DiskMarginResponse
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

        % Skew
        function Skew = get.Skew(this)
            arguments
                this (1,1) controllib.chart.response.DiskMarginResponse
            end
            Skew = this.Skew_I;
        end
        
        function set.Skew(this,Skew)
            arguments
                this (1,1) controllib.chart.response.DiskMarginResponse
                Skew (:,1) double
            end
            try
                this.Skew_I = Skew;
                markDirtyAndUpdate(this);               
            catch ME
                throw(ME);
            end
        end

        % IsStable
        function IsStable = get.IsStable(this)
            arguments
                this (1,1) controllib.chart.response.DiskMarginResponse
            end
            IsStable = this.IsStable_I;
        end
        
        function set.IsStable(this,IsStable)
            arguments
                this (1,1) controllib.chart.response.DiskMarginResponse
                IsStable logical
            end
            try
                this.IsStable_I = IsStable;
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
                thisSerialized.rename("Skew","Skew_I");
                thisSerialized.rename("IsStable","IsStable_I");
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
                this (1,1) controllib.chart.response.DiskMarginResponse
            end
            this.ResponseData = controllib.chart.internal.data.response.DiskMarginResponseDataSource(...
                this.Model,Skew=this.Skew,Frequency=this.FrequencySpec);
        end

        function updateData(this)
            arguments
                this (1,1) controllib.chart.response.DiskMarginResponse
            end
            options.Skew = this.Skew;
            options.Frequency = this.FrequencySpec;
            options.IsStable = this.IsStable;
            options = controllib.chart.response.DiskMarginResponse.parseDiskMarginResponseInputs(options);
            optionsCell = namedargs2cell(options);
            updateData@controllib.chart.internal.foundation.InputOutputModelResponse(this,optionsCell{:},Model=this.Model);
        end
    end

    %% Private static methods
    methods (Static,Access=private)
        function diskMarginResponseOptionalInputs = parseDiskMarginResponseInputs(diskMarginResponseOptionalInputs)
            % Parse Frequency
            if iscell(diskMarginResponseOptionalInputs.Frequency)
                diskMarginResponseOptionalInputs.Frequency = diskMarginResponseOptionalInputs.Frequency(:)';
            end
        end
    end
end

