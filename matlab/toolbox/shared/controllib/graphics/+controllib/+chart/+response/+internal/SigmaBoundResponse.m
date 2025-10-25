classdef SigmaBoundResponse < controllib.chart.internal.foundation.InputOutputModelResponse & ...
                        controllib.chart.internal.foundation.MixInControlsModelResponse
    % controllib.chart.response.internal.SigmaBoundResponse
    %   - manage data and style properties for a bound response in "sigmaplot"
    %   - inherited from controllib.chart.internal.foundation.InputOutputModelResponse
    %
    % h = SigmaBoundResponse(model)
    %   model       DynamicSystem
    % 
    % h = SigmaBoundResponse(_____,Name-Value)
    %   Name                    response name, string, "" (default)
    %   Style                   response style object, controllib.chart.internal.options.ResponseStyle (default)
    %   Tag                     response tag, string, matlab.lang.internal.uuid (default)
    %   LegendDisplay           show response in legend, matlab.lang.OnOffSwitchState, true (default)
    %   Frequency               frequency specification used to generate data, [] (default) auto generates frequency specification
    %   SingularValueType       type of singular value response, 0 (default) plots the SV of H
    %   BoundType               type of bound, "upper" (default) plots above response data
    %   Focus                   focus of Tuning Goal, [0 Inf] (default)
    %   UseFrequencyFocus       contribute to XLimitFocus, true (default)
    %   UseMagnitudeFocus       contribute to YLimitFocus, true (default)
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
    %   UseFrequencyFocus       contribute to XLimitFocus, logical
    %   UseMagnitudeFocus       contribute to YLimitFocus, logical
    %
    % Read-Only properties:
    %   FrequencyUnit    string specifying frequency unit, based on Model TimeUnit.
    %   MagnitudeUnit    string specifying magnitude unit.
    %
    % See Also:
    %   <a href="matlab:help controllib.chart.internal.foundation.InputOutputModelResponse">controllib.chart.internal.foundation.InputOutputModelResponse</a>

    % Copyright 2023-2024 The MathWorks, Inc.
    
    %% Properties
    properties(Hidden,Dependent, AbortSet, SetObservable)
        % "Frequency": double vector or 1x2 cell
        % Frequency specification used to generate data.
        Frequency
        % "SingularValueType": double scalar
        % Type of singular value response.
        SingularValueType
        % "BoundType": string scalar
        % Type of response bound.
        BoundType
        % "Focus": 1x2 double
        % Frequency focus of Tuning Goal.
        Focus
        % "UseFrequencyFocus": logical scalar
        % Response contributes to XLimitFocus.
        UseFrequencyFocus
        % "UseMagnitudeFocus": logical scalar
        % Response contributes to YLimitFocus.
        UseMagnitudeFocus
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
        BoundType_I
        Focus_I
        FrequencySpec_I
        SingularValueType_I
        UseFrequencyFocus_I
        UseMagnitudeFocus_I
    end 
    
    %% Clean up property later
    properties (Hidden, Access = {?TuningGoal.Generic,?controllib.chart.internal.view.wave.SigmaBoundResponseView,...
            ?controllib.chart.internal.view.wave.data.ResponseWrapper})
        UseMaximumSingularValue = false
    end
    
    %% Constructor
    methods
        function this = SigmaBoundResponse(modelSource,sigmaBoundResponseOptionalInputs,baseResponseOptionalInputs)
            arguments
                modelSource
                sigmaBoundResponseOptionalInputs.BoundType (1,1) string...
                    {mustBeMember(sigmaBoundResponseOptionalInputs.BoundType,["upper","lower","SBound","TBound"])} = "upper"
                sigmaBoundResponseOptionalInputs.Focus (1,2) double = [0 Inf]
                sigmaBoundResponseOptionalInputs.SingularValueType (1,1) double...
                    {mustBeMember(sigmaBoundResponseOptionalInputs.SingularValueType,[0 1 2 3])} = 0
                sigmaBoundResponseOptionalInputs.UseFrequencyFocus (1,1) logical = true
                sigmaBoundResponseOptionalInputs.UseMagnitudeFocus (1,1) logical = true
                sigmaBoundResponseOptionalInputs.Frequency (:,1) ...
                    {controllib.chart.internal.utils.validators.mustBeFrequencySpec} = []
                baseResponseOptionalInputs.?controllib.chart.internal.foundation.BaseResponseOptionalInputs
            end

            % Create model source if model provided as first argument
            if ~isa(modelSource,'controllib.chart.internal.utils.ModelSource')
                modelSource = controllib.chart.internal.utils.ModelSource(modelSource);
            end
            
            [~,sigmaBoundResponseOptionalInputs] = controllib.chart.response.internal.SigmaBoundResponse.parseSigmaBoundResponseInputs(modelSource.Model,sigmaBoundResponseOptionalInputs);
            baseResponseOptionalInputs = namedargs2cell(baseResponseOptionalInputs);
            this@controllib.chart.internal.foundation.InputOutputModelResponse(modelSource,baseResponseOptionalInputs{:});
            
            this.BoundType_I = sigmaBoundResponseOptionalInputs.BoundType;
            this.Focus_I = sigmaBoundResponseOptionalInputs.Focus;
            this.SingularValueType_I = sigmaBoundResponseOptionalInputs.SingularValueType;
            this.FrequencySpec_I = sigmaBoundResponseOptionalInputs.Frequency;
            this.UseFrequencyFocus_I = sigmaBoundResponseOptionalInputs.UseFrequencyFocus;
            this.UseMagnitudeFocus_I = sigmaBoundResponseOptionalInputs.UseMagnitudeFocus;
            if ~isempty(sigmaBoundResponseOptionalInputs.Frequency)
                this.AutoGenerateXData = false;
            end
            build(this);

            this.Type = "sigmaBound";
        end
    end

    %% Get/Set
    methods
        % Frequency
        function Frequency = get.Frequency(this)
            arguments
                this (1,1) controllib.chart.response.internal.SigmaBoundResponse
            end
            Frequency = this.FrequencySpec_I;
        end

        function set.Frequency(this,Frequency)
            arguments
                this (1,1) controllib.chart.response.internal.SigmaBoundResponse
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
                this (1,1) controllib.chart.response.internal.SigmaBoundResponse
            end
            if strcmp(this.Model.TimeUnit,'seconds')
                timeUnit = 's';
            else
                timeUnit = this.Model.TimeUnit(1:end-1);
            end
            FrequencyUnit = string(['rad/',timeUnit]);
        end

        % SingularValueType
        function SingularValueType = get.SingularValueType(this)
            arguments
                this (1,1) controllib.chart.response.internal.SigmaBoundResponse
            end
            SingularValueType = this.SingularValueType_I;
        end

        function set.SingularValueType(this,SingularValueType)
            arguments
                this (1,1) controllib.chart.response.internal.SigmaBoundResponse
                SingularValueType (1,1) double {mustBeMember(SingularValueType,[0 1 2 3])}
            end
            try
                this.SingularValueType_I = SingularValueType;
                markDirtyAndUpdate(this);
            catch ME
                error(ME.message);
            end
        end

        % UseMaximumSingularValue
        function set.UseMaximumSingularValue(this,Flag)
            arguments
                this (1,1) controllib.chart.response.internal.SigmaBoundResponse
                Flag (1,1) logical
            end
            this.UseMaximumSingularValue = Flag;
            notify(this,'ResponseChanged');
        end 

        % BoundType
        function BoundType = get.BoundType(this)
            arguments
                this (1,1) controllib.chart.response.internal.SigmaBoundResponse
            end
            BoundType = this.BoundType_I;
        end

        function set.BoundType(this,BoundType)
            arguments
                this (1,1) controllib.chart.response.internal.SigmaBoundResponse
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
                this (1,1) controllib.chart.response.internal.SigmaBoundResponse
            end
            Focus = this.Focus_I;
        end

        function set.Focus(this,Focus)
            arguments
                this (1,1) controllib.chart.response.internal.SigmaBoundResponse
                Focus (1,2) double
            end
            try
                this.Focus_I = Focus;
                markDirtyAndUpdate(this);
            catch ME
                error(ME.message);
            end
        end

        % UseFrequencyFocus
        function UseFrequencyFocus = get.UseFrequencyFocus(this)
            arguments
                this (1,1) controllib.chart.response.internal.SigmaBoundResponse
            end
            UseFrequencyFocus = this.UseFrequencyFocus_I;
        end

        function set.UseFrequencyFocus(this,UseFrequencyFocus)
            arguments
                this (1,1) controllib.chart.response.internal.SigmaBoundResponse
                UseFrequencyFocus (1,1) logical
            end
            try
                this.UseFrequencyFocus_I = UseFrequencyFocus;
                markDirtyAndUpdate(this);
            catch ME
                error(ME.message);
            end
        end

        % UseMagnitudeFocus
        function UseMagnitudeFocus = get.UseMagnitudeFocus(this)
            arguments
                this (1,1) controllib.chart.response.internal.SigmaBoundResponse
            end
            UseMagnitudeFocus = this.UseMagnitudeFocus_I;
        end

        function set.UseMagnitudeFocus(this,UseMagnitudeFocus)
            arguments
                this (1,1) controllib.chart.response.internal.SigmaBoundResponse
                UseMagnitudeFocus (1,1) logical
            end
            try
                this.UseMagnitudeFocus_I = UseMagnitudeFocus;
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
                this (1,1) controllib.chart.response.internal.SigmaBoundResponse
            end
            this.ResponseData = controllib.chart.internal.data.response.SigmaBoundResponseDataSource(this.Model,...
                BoundType=this.BoundType_I,Focus=this.Focus_I,Frequency=this.FrequencySpec_I,...
                UseFrequencyFocus=this.UseFrequencyFocus,UseMagnitudeFocus=this.UseMagnitudeFocus,...
                SingularValueType=this.SingularValueType_I);
        end
        
        function updateData(this)
            arguments
                this (1,1) controllib.chart.response.internal.SigmaBoundResponse
            end
            options.BoundType = this.BoundType_I;
            options.Focus = this.Focus_I;
            options.SingularValueType = this.SingularValueType_I;
            options.UseFrequencyFocus = this.UseFrequencyFocus_I;
            options.UseMagnitudeFocus = this.UseMagnitudeFocus_I;
            options.Frequency = this.FrequencySpec_I;
            this.AutoGenerateXData = isempty(options.Frequency);
            [model,options] = controllib.chart.response.internal.SigmaBoundResponse.parseSigmaBoundResponseInputs(this.Model,options);
            optionsCell = namedargs2cell(options);
            updateData@controllib.chart.internal.foundation.InputOutputModelResponse(this,optionsCell{:},Model=model);
        end
    end

    %% Private static methods
    methods (Static,Access=private)
        function [model,sigmaBoundResponseOptionalInputs] = parseSigmaBoundResponseInputs(model,sigmaBoundResponseOptionalInputs)    
            % Parse Focus
            try
                mustBeInRange(sigmaBoundResponseOptionalInputs.Focus(1),0,sigmaBoundResponseOptionalInputs.Focus(2),'exclude-upper')
                mustBeInRange(sigmaBoundResponseOptionalInputs.Focus(2),sigmaBoundResponseOptionalInputs.Focus(1),Inf,'exclude-lower')
            catch
                error(message('Control:tuning:TuningReq7'))
            end
        end
    end

    %% Hidden TuningGoal methods
    methods (Hidden, Access = {?TuningGoal.Generic,...
            ?controllib.chart.response.internal.SigmaBoundResponse})
        function value = getMaximumValue(this)
            arguments
                this (1,1) controllib.chart.response.internal.SigmaBoundResponse
            end
            value = -inf;
            for ii = 1:numel(this.ResponseData.SingularValue)
                value = max(value,max(this.ResponseData.SingularValue{ii},[],"all"));
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

