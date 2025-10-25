classdef IOPZResponse < controllib.chart.internal.foundation.InputOutputModelResponse & ...
                        controllib.chart.internal.foundation.MixInControlsModelResponse
    % controllib.chart.response.IOPZResponse
    %   - manage data and style properties for a response in "iopzplot"
    %   - inherited from controllib.chart.internal.foundation.InputOutputModelResponse
    %
    % h = IOPZResponse(model)
    %   model       DynamicSystem
    % 
    % h = IOPZResponse(_____,Name-Value)
    %   Name                    response name, string, "" (default)
    %   Style                   response style object, controllib.chart.internal.options.ResponseStyle (default)
    %   Tag                     response tag, string, matlab.lang.internal.uuid (default)
    %   LegendDisplay           show response in legend, matlab.lang.OnOffSwitchState, true (default)
    %   NumberOfStandardDeviations  standard deviation used to show confidence region for identified models
    %
    % Settable properties:
    %   Name                    label for response in chart, string
    %   Visible                 show response in chart, matlab.lang.OnOffSwitchState
    %   Style                   response style object, controllib.chart.internal.options.ResponseStyle
    %   LegendDisplay           show response in legend, matlab.lang.OnOffSwitchState
    %   UserData                custom data, any MATLAB array
    %   Model                   DynamicSystem for response
    %   NumberOfStandardDeviations  standard deviation used to show confidence region for identified models
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
    properties (Dependent, AbortSet, SetObservable)
        % "SourceData": struct
        % Values used to generate data
        SourceData
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
        PadeOrder_I
        NumberOfStandardDeviations_I
    end

    %% Constructor
    methods
        function this = IOPZResponse(modelSource,iopzResponseOptionalInputs,baseResponseOptionalInputs)
            arguments
                modelSource
                iopzResponseOptionalInputs.NumberOfStandardDeviations (1,1) double = get(pzoptions('cstprefs'),'ConfidenceRegionNumberSD')
                baseResponseOptionalInputs.?controllib.chart.internal.foundation.BaseResponseOptionalInputs
            end

            % Create model source if model provided as first argument
            if ~isa(modelSource,'controllib.chart.internal.utils.ModelSource')
                modelSource = controllib.chart.internal.utils.ModelSource(modelSource);
            end
            
            baseResponseOptionalInputs = namedargs2cell(baseResponseOptionalInputs);
            this@controllib.chart.internal.foundation.InputOutputModelResponse(modelSource,baseResponseOptionalInputs{:});;
            this.NumberOfStandardDeviations_I = iopzResponseOptionalInputs.NumberOfStandardDeviations;
            build(this);

            this.Type = "iopz";

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
            % Model
            SourceData.Model = this.Model;
        end

        function set.SourceData(this,SourceData)
            mustBeMember(fields(SourceData),fields(this.SourceData));
            this.Model = SourceData.Model;
            markDirtyAndUpdate(this);
        end


        % FrequencyUnit
        function FrequencyUnit = get.FrequencyUnit(this)
            arguments
                this (1,1) controllib.chart.response.IOPZResponse
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
                this (1,1) controllib.chart.response.IOPZResponse
            end
            TimeUnit = string(this.Model.TimeUnit);
        end
    end
    
    %% Get/Set dynamic props
    methods (Access = private)
        % NumberOfStandardDeviations
        function NumberOfStandardDeviations = getNumberOfStandardDeviations(this)
            arguments
                this (1,1) controllib.chart.response.IOPZResponse
            end
            NumberOfStandardDeviations = this.NumberOfStandardDeviations_I;
        end
        
        function setNumberOfStandardDeviations(this,NumberOfStandardDeviations)
            arguments
                this (1,1) controllib.chart.response.IOPZResponse
                NumberOfStandardDeviations (1,1) double
            end
            try
                update(this,NumberOfStandardDeviations=NumberOfStandardDeviations);
            catch ME
                throw(ME);
            end
        end
    end

    %% Static methods
    methods (Static)
        function modifyIncomingSerializationContent(thisSerialized)
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
                this (1,1) controllib.chart.response.IOPZResponse
            end
            this.ResponseData = controllib.chart.internal.data.response.IOPZResponseDataSource(...
                this.Model,NumberOfStandardDeviations=this.NumberOfStandardDeviations_I);
        end

        function updateData(this)
            arguments
                this (1,1) controllib.chart.response.IOPZResponse
            end
            updateData@controllib.chart.internal.foundation.InputOutputModelResponse(this,Model=this.Model);
            
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
	
    %% Hidden static methods
    methods (Hidden,Static)
        function dataProperties = getDataProperties()
            dataProperties = "SourceData";
        end
        function [styleProperties,hiddenStyleProperties] = getStyleProperties()
            styleProperties = ["Color","MarkerSize","LineWidth"];
            hiddenStyleProperties = "SemanticColor";
        end
    end
end

