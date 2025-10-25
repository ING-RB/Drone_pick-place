classdef RootLocusResponse < controllib.chart.internal.foundation.InputOutputModelResponse & ...
                        controllib.chart.internal.foundation.MixInControlsModelResponse
    % controllib.chart.response.RootLocusResponse
    %   - manage data and style properties for a response in "rlocusplot"
    %   - inherited from controllib.chart.internal.foundation.InputOutputModelResponse
    %
    % h = RootLocusResponse(model)
    %   model       DynamicSystem
    % 
    % h = RootLocusResponse(_____,Name-Value)
    %   Name                    response name, string, "" (default)
    %   Style                   response style object, controllib.chart.internal.options.ResponseStyle (default)
    %   Tag                     response tag, string, matlab.lang.internal.uuid (default)
    %   LegendDisplay           show response in legend, matlab.lang.OnOffSwitchState, true (default)
    %   FeedbackGains           feedback gain values pertaining to pole locations, [] (default) auto generates feedback gains
    %
    % Settable properties:
    %   Name                    label for response in chart, string
    %   Visible                 show response in chart, matlab.lang.OnOffSwitchState
    %   Style                   response style object, controllib.chart.internal.options.ResponseStyle
    %   LegendDisplay           show response in legend, matlab.lang.OnOffSwitchState
    %   UserData                custom data, any MATLAB array
    %   Model                   DynamicSystem for response
    %   FeedbackGains           feedback gain values pertaining to pole locations, double
    %
    % Read-Only properties:
    %   TimeUnit                string specifying time unit, based on Model TimeUnit.
    %   FrequencyUnit           string specifying frequency unit, based on Model TimeUnit.
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
        % "FeedbackGains": double vector
        % Feedback gains for response.
        FeedbackGains
    end

    properties (Hidden,Dependent,SetAccess=private)
        % "TimeUnit": string
        % Get TimeUnit of Model.
        TimeUnit
        % "FrequencyUnit": string
        % Get FrequencyUnit of Model.
        FrequencyUnit
    end

    properties (GetAccess = protected,SetAccess=private)
        FeedbackGains_I
    end
    
    %% Constructor
    methods
        function this = RootLocusResponse(modelSource,rootLocusOptionalInputs,baseResponseOptionalInputs)
            arguments
                modelSource
                rootLocusOptionalInputs.FeedbackGains (:,1) double = []
                baseResponseOptionalInputs.?controllib.chart.internal.foundation.BaseResponseOptionalInputs
            end

            % Create model source if model provided as first argument
            if ~isa(modelSource,'controllib.chart.internal.utils.ModelSource')
                modelSource = controllib.chart.internal.utils.ModelSource(modelSource);
            end
            
            [model,rootLocusOptionalInputs] = controllib.chart.response.RootLocusResponse.parseRLocusResponseInputs(modelSource.Model,rootLocusOptionalInputs);
            modelSource.Model_I = model;
            baseResponseOptionalInputs = namedargs2cell(baseResponseOptionalInputs);
            this@controllib.chart.internal.foundation.InputOutputModelResponse(modelSource,baseResponseOptionalInputs{:});

            this.FeedbackGains_I = rootLocusOptionalInputs.FeedbackGains;
            build(this);

            this.Type = "rlocus";
        end
    end

    %% Get/Set
    methods
        % SourceData
        function SourceData = get.SourceData(this)
            % Model
            SourceData.Model = this.Model;
            SourceData.FeedbackGainSpec = this.FeedbackGains;
        end

        function set.SourceData(this,SourceData)
            mustBeMember(fields(SourceData),fields(this.SourceData));
            this.Model = SourceData.Model;
            this.FeedbackGains = SourceData.FeedbackGainSpec;

            markDirtyAndUpdate(this);
        end

        % FrequencyUnit
        function FrequencyUnit = get.FrequencyUnit(this)
            arguments
                this (1,1) controllib.chart.response.RootLocusResponse
            end
            if strcmp(this.Model.TimeUnit,'seconds')
                timeUnit = 's';
            else
                timeUnit = this.Model.TimeUnit(1:end-1);
            end
            FrequencyUnit = string(['rad/',timeUnit]);
        end

        % TimeUnit
        function TimeUnit = get.TimeUnit(this)
            arguments
                this (1,1) controllib.chart.response.RootLocusResponse
            end
            TimeUnit = string(this.Model.TimeUnit);
        end

        % FeedbackGains
        function FeedbackGains = get.FeedbackGains(this)
            arguments
                this (1,1) controllib.chart.response.RootLocusResponse
            end
            FeedbackGains = this.FeedbackGains_I;
        end
        
        function set.FeedbackGains(this,FeedbackGains)
            arguments
                this (1,1) controllib.chart.response.RootLocusResponse
                FeedbackGains (:,1) double
            end
            try
                this.FeedbackGains_I = FeedbackGains;
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
                thisSerialized.rename("FeedbackGains","FeedbackGains_I");
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
                this (1,1) controllib.chart.response.RootLocusResponse
            end
            this.ResponseData = controllib.chart.internal.data.response.RootLocusResponseDataSource(...
                this.Model,FeedbackGains=this.FeedbackGains);
        end

        function updateData(this,varargin)
            options.FeedbackGains = this.FeedbackGains;
            [model,options] = controllib.chart.response.RootLocusResponse.parseRLocusResponseInputs(this.Model,options);
            optionsCell = namedargs2cell(options);
            updateData@controllib.chart.internal.foundation.InputOutputModelResponse(this,varargin{:},optionsCell{:},Model=model);
        end
    end

    %% Private static methods
    methods (Static,Access=private)
        function [model,rootLocusResponseOptionalInputs] = parseRLocusResponseInputs(model,rootLocusResponseOptionalInputs)
            % Parse Feedback Gains
            rootLocusResponseOptionalInputs.FeedbackGains = unique(rootLocusResponseOptionalInputs.FeedbackGains);
        end
    end

    %% Hidden static methods
    methods (Hidden,Static)
        function dataProperties = getDataProperties()
            dataProperties = "SourceData";
        end
    end
end