classdef SectorBoundResponse < controllib.chart.internal.foundation.InputOutputModelResponse & ...
                        controllib.chart.internal.foundation.MixInControlsModelResponse
    % controllib.chart.response.internal.SectorBoundResponse
    %   - manage data and style properties for a bound response in "sectorplot"
    %   - inherited from controllib.chart.internal.foundation.InputOutputModelResponse
    %
    % h = SectorBoundResponse(model)
    %   model       DynamicSystem
    % 
    % h = SectorBoundResponse(_____,Name-Value)
    %   Name                    response name, string, "" (default)
    %   Style                   response style object, controllib.chart.internal.options.ResponseStyle (default)
    %   Tag                     response tag, string, matlab.lang.internal.uuid (default)
    %   LegendDisplay           show response in legend, matlab.lang.OnOffSwitchState, true (default)
    %   Frequency               frequency specification used to generate data, [] (default) auto generates frequency specification
    %   SingularValueType       type of singular value response, 0 (default) plots the SV of H
    %   BoundType               type of bound, "upper" (default) plots above response data
    %   Focus                   focus of Tuning Goal, [0 Inf] (default)
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
    %   BoundType               type of bound, string
    %   Focus                   focus of Tuning Goal, double
    %
    % Read-Only properties:
    %   FrequencyUnit    string specifying frequency unit, based on Model TimeUnit.
    %   IndexUnit        string specifying index unit.
    %
    % See Also:
    %   <a href="matlab:help controllib.chart.internal.foundation.InputOutputModelResponse">controllib.chart.internal.foundation.InputOutputModelResponse</a>

    % Copyright 2023-2024 The MathWorks, Inc.
    
    %% Properties
    properties(Hidden,Dependent, AbortSet, SetObservable)
        % "Frequency": double vector or 1x2 cell
        % Frequency specification used to generate data.
        Frequency
        % "BoundType": string scalar
        % Type of response bound.
        BoundType
        % "Focus": 1x2 double
        % Frequency focus of Tuning Goal.
        Focus
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
        BoundType_I
        Focus_I
        FrequencySpec_I
    end
    
    %% Constructor
    methods
        function this = SectorBoundResponse(modelSource,sectorBoundResponseOptionalInputs,baseResponseOptionalInputs)
            arguments
                modelSource
                sectorBoundResponseOptionalInputs.BoundType (1,1) string...
                    {mustBeMember(sectorBoundResponseOptionalInputs.BoundType,["upper","lower"])} = "upper"
                sectorBoundResponseOptionalInputs.Focus (1,2) double = [0 Inf]
                sectorBoundResponseOptionalInputs.Frequency (:,1) ...
                    {controllib.chart.internal.utils.validators.mustBeFrequencySpec} = []
                baseResponseOptionalInputs.?controllib.chart.internal.foundation.BaseResponseOptionalInputs
            end

            % Create model source if model provided as first argument
            if ~isa(modelSource,'controllib.chart.internal.utils.ModelSource')
                modelSource = controllib.chart.internal.utils.ModelSource(modelSource);
            end
            
            [~,sectorBoundResponseOptionalInputs] = controllib.chart.response.internal.SectorBoundResponse.parseSectorBoundResponseInputs(modelSource.Model,sectorBoundResponseOptionalInputs);
            baseResponseOptionalInputs = namedargs2cell(baseResponseOptionalInputs);
            this@controllib.chart.internal.foundation.InputOutputModelResponse(modelSource,baseResponseOptionalInputs{:});

            this.BoundType_I = sectorBoundResponseOptionalInputs.BoundType;
            this.Focus_I = sectorBoundResponseOptionalInputs.Focus;
            this.FrequencySpec_I = sectorBoundResponseOptionalInputs.Frequency;
            if ~isempty(sectorBoundResponseOptionalInputs.Frequency)
                this.AutoGenerateXData = false;
            end
            build(this);

            this.Type = "sectorBound";
        end
    end

    %% Get/Set
    methods
        % Frequency
        function Frequency = get.Frequency(this)
            arguments
                this (1,1) controllib.chart.response.internal.SectorBoundResponse
            end
            Frequency = this.FrequencySpec_I;
        end

        function set.Frequency(this,Frequency)
            arguments
                this (1,1) controllib.chart.response.internal.SectorBoundResponse
                Frequency (:,1) {controllib.chart.internal.utils.validators.mustBeFrequencySpec}
            end
            try
                this.FrequencySpec_I = Frequency;
                markDirtyAndUpdate(this);
            catch ME
                error(ME.message);
            end
        end

        % FrequencyUnit
        function FrequencyUnit = get.FrequencyUnit(this)
            arguments
                this (1,1) controllib.chart.response.internal.SectorBoundResponse
            end
            if strcmp(this.Model.TimeUnit,'seconds')
                timeUnit = 's';
            else
                timeUnit = this.Model.TimeUnit(1:end-1);
            end
            FrequencyUnit = string(['rad/',timeUnit]);
        end

        % BoundType
        function BoundType = get.BoundType(this)
            arguments
                this (1,1) controllib.chart.response.internal.SectorBoundResponse
            end
            BoundType = this.BoundType_I;
        end

        function set.BoundType(this,BoundType)
            arguments
                this (1,1) controllib.chart.response.internal.SectorBoundResponse
                BoundType (1,1) string {mustBeMember(BoundType,["upper","lower"])}
            end
            try
                this.BoundType_I = BoundType;
                markDirtyAndUpdate(this);
            catch ME
                error(ME.message);
            end
        end

        % Focus
        function Focus = get.Focus(this)
            arguments
                this (1,1) controllib.chart.response.internal.SectorBoundResponse
            end
            Focus = this.Focus_I;
        end

        function set.Focus(this,Focus)
            arguments
                this (1,1) controllib.chart.response.internal.SectorBoundResponse
                Focus (1,2) double
            end
            try
                this.Focus_I = Focus;
                markDirtyAndUpdate(this);
            catch ME
                error(ME.message);
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
                this (1,1) controllib.chart.response.internal.SectorBoundResponse
            end
            this.ResponseData = controllib.chart.internal.data.response.SectorBoundResponseDataSource(this.Model,...
                BoundType=this.BoundType_I,Focus=this.Focus_I,Frequency=this.FrequencySpec_I);
        end

        function updateData(this)
            arguments
                this (1,1) controllib.chart.response.internal.SectorBoundResponse
            end
            options.BoundType = this.BoundType_I;
            options.Focus = this.Focus_I;
            options.Frequency = this.FrequencySpec_I;
            [model,options] = controllib.chart.response.internal.SectorBoundResponse.parseSectorBoundResponseInputs(this.Model,options);
            optionsCell = namedargs2cell(options);
            updateData@controllib.chart.internal.foundation.InputOutputModelResponse(this,optionsCell{:},Model=model);
        end
    end

    %% Private static methods
    methods (Static,Access=private)
        function [model,sectorBoundResponseOptionalInputs] = parseSectorBoundResponseInputs(model,sectorBoundResponseOptionalInputs)
            % Parse Focus
            try
                mustBeInRange(sectorBoundResponseOptionalInputs.Focus(1),0,sectorBoundResponseOptionalInputs.Focus(2),'exclude-upper')
                mustBeInRange(sectorBoundResponseOptionalInputs.Focus(2),sectorBoundResponseOptionalInputs.Focus(1),Inf,'exclude-lower')
            catch
                error(message('Control:tuning:TuningReq7'))
            end
        end
    end
    
    %% Hidden static methods
    methods (Hidden,Static)
        function [styleProperties,hiddenStyleProperties] = getStyleProperties()
            styleProperties = ["FaceColor","EdgeColor","FaceAlpha","EdgeAlpha","LineStyle","MarkerStyle","LineWidth","MarkerSize"];
            hiddenStyleProperties = ["SemanticFaceColor","SemanticEdgeColor"];
        end
    end
end

