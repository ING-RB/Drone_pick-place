classdef PZBoundResponse < controllib.chart.internal.foundation.BaseResponse
    % controllib.chart.response.PZBoundResponse
    %   - manage data and style properties for a bound response in "pzplot"
    %   - inherited from controllib.chart.internal.foundation.BaseResponse
    %
    % h = PZBoundResponse()
    % 
    % h = PZBoundResponse(_____,Name-Value)
    %   Name                    response name, string, "" (default)
    %   Style                   response style object, controllib.chart.internal.options.ResponseStyle (default)
    %   Tag                     response tag, string, matlab.lang.internal.uuid (default)
    %   LegendDisplay           show response in legend, matlab.lang.OnOffSwitchState, true (default)
    %   MinDecay                minimum decay rate of poles, 0 (default)
    %   MinDamping              minimum damping ratio of poles, 0 (default)
    %   MaxFrequency            maximum natrual frequency of poles, Inf (default)
    %   Ts                      sample time of closed-loop system, 0 (default)
    %
    % Settable properties:
    %   Name                    label for response in chart, string
    %   Visible                 show response in chart, matlab.lang.OnOffSwitchState
    %   Style                   response style object, controllib.chart.internal.options.ResponseStyle
    %   LegendDisplay           show response in legend, matlab.lang.OnOffSwitchState
    %   UserData                custom data, any MATLAB array
    %   MinDecay                minimum decay rate of poles, double
    %   MinDamping              minimum damping ratio of poles, double
    %   MaxFrequency            maximum natrual frequency of poles, double
    %   Ts                      sample time of closed-loop system, double
    %
    % Read-Only properties:
    %   TimeUnit                string specifying time unit, based on Model TimeUnit.
    %   FrequencyUnit           string specifying frequency unit, based on Model TimeUnit.
    %
    % See Also:
    %   <a href="matlab:help controllib.chart.internal.foundation.BaseResponse">controllib.chart.internal.foundation.BaseResponse</a>

    % Copyright 2023-2024 The MathWorks, Inc.
    
    %% Properties
    properties (Hidden,Dependent, AbortSet, SetObservable)
        % "MinDecay": double scalar
        % Minimum decay rate of poles.
        MinDecay
        % "MinDamping": double scalar
        % Minimum damping ratio of poles.
        MinDamping
        % "MaxFrequency": double scalar
        % Maximum natrual frequency of poles.
        MaxFrequency
        % "Ts": double scalar
        % Sample time of closed-loop system.
        Ts
    end

    properties(Hidden, Dependent, SetAccess=private)
        % "IsDiscrete": logical scalar
        % Get if closed-loop system is discrete.
        IsDiscrete
    end
    
    properties (Hidden,Constant)
        % "TimeUnit": string
        % Get TimeUnit of ResponseData.
        TimeUnit = "seconds"
        % "FrequencyUnit": string
        % Get FrequencyUnit of ResponseData.
        FrequencyUnit = "rad/s"
    end

    properties (GetAccess = protected,SetAccess=private)
        MinDecay_I
        MinDamping_I
        MaxFrequency_I
        Ts_I
    end

    %% Constructor
    methods
        function this = PZBoundResponse(pzBoundResponseOptionalInputs,baseResponseOptionalInputs)
            arguments
                pzBoundResponseOptionalInputs.MinDecay (1,1) double {mustBeNonnegative,mustBeFinite} = 0
                pzBoundResponseOptionalInputs.MinDamping (1,1) double...
                    {mustBeInRange(pzBoundResponseOptionalInputs.MinDamping,0,1)} = 0
                pzBoundResponseOptionalInputs.MaxFrequency (1,1) double {mustBePositive} = inf
                pzBoundResponseOptionalInputs.Ts (1,1) double...
                    {controllib.chart.internal.utils.validators.mustBeSampleTime} = 0
                baseResponseOptionalInputs.?controllib.chart.internal.foundation.BaseResponseOptionalInputs
            end
            baseResponseOptionalInputs = namedargs2cell(baseResponseOptionalInputs);
            this@controllib.chart.internal.foundation.BaseResponse(baseResponseOptionalInputs{:});

            this.MinDecay_I = pzBoundResponseOptionalInputs.MinDecay;
            this.MinDamping_I = pzBoundResponseOptionalInputs.MinDamping;
            this.MaxFrequency_I = pzBoundResponseOptionalInputs.MaxFrequency;
            this.Ts_I = pzBoundResponseOptionalInputs.Ts;
            build(this);

            this.Type = "pzBound";
        end
    end

    %% Get/Set
    methods
        % MinDecay
        function MinDecay = get.MinDecay(this)
            arguments
                this (1,1) controllib.chart.response.internal.PZBoundResponse
            end
            MinDecay = this.MinDecay_I;
        end

        function set.MinDecay(this,MinDecay)
            arguments
                this (1,1) controllib.chart.response.internal.PZBoundResponse
                MinDecay (1,1) double {mustBeNonnegative,mustBeFinite}
            end
            try
                this.MinDecay_I = MinDecay;
                markDirtyAndUpdate(this);
            catch ME
                error(ME.message);
            end
        end

        % MinDamping
        function MinDamping = get.MinDamping(this)
            arguments
                this (1,1) controllib.chart.response.internal.PZBoundResponse
            end
            MinDamping = this.MinDamping_I;
        end

        function set.MinDamping(this,MinDamping)
            arguments
                this (1,1) controllib.chart.response.internal.PZBoundResponse
                MinDamping (1,1) double {mustBeInRange(MinDamping,0,1)}
            end
            try
                this.MinDamping_I = MinDamping;
                markDirtyAndUpdate(this);
            catch ME
                error(ME.message);
            end
        end

        % MaxFrequency
        function MaxFrequency = get.MaxFrequency(this)
            arguments
                this (1,1) controllib.chart.response.internal.PZBoundResponse
            end
            MaxFrequency = this.MaxFrequency_I;
        end

        function set.MaxFrequency(this,MaxFrequency)
            arguments
                this (1,1) controllib.chart.response.internal.PZBoundResponse
                MaxFrequency (1,1) double {mustBePositive}
            end
            try
                this.MaxFrequency_I = MaxFrequency;
                markDirtyAndUpdate(this);
            catch ME
                error(ME.message);
            end
        end

        % Ts
        function Ts = get.Ts(this)
            arguments
                this (1,1) controllib.chart.response.internal.PZBoundResponse
            end
            Ts = this.Ts_I;
        end

        function set.Ts(this,Ts)
            arguments
                this (1,1) controllib.chart.response.internal.PZBoundResponse
                Ts (1,1) double {controllib.chart.internal.utils.validators.mustBeSampleTime}
            end
            try
                this.Ts_I = Ts;
                markDirtyAndUpdate(this);
            catch ME
                error(ME.message);
            end
        end

        % IsDiscrete
        function flag = get.IsDiscrete(this)
            arguments
                this (1,1) controllib.chart.response.internal.PZBoundResponse
            end
            flag = this.Ts_I ~= 0;
        end
    end

    %% Static methods
    methods (Static)
        function modifyIncomingSerializationContent(thisSerialized)
            modifyIncomingSerializationContent@controllib.chart.internal.foundation.BaseResponse(thisSerialized);
        end

        function this = finalizeIncomingObject(this)
            this = finalizeIncomingObject@controllib.chart.internal.foundation.BaseResponse(this);
        end

        function modifyOutgoingSerializationContent(thisSerialized,this)
            modifyOutgoingSerializationContent@controllib.chart.internal.foundation.BaseResponse(thisSerialized,this);
        end
    end
    
    %% Protected methods (override in subclass)
    methods (Access = protected)
        function initializeData(this)
            arguments
                this (1,1) controllib.chart.response.internal.PZBoundResponse
            end
            this.ResponseData = controllib.chart.internal.data.response.PZBoundResponseDataSource(...
                MinDeca =this.MinDecay_I,MinDamping=this.MinDamping_I,...
                MaxFrequency=this.MaxFrequency_I,Ts=this.Ts_I);
        end

        function updateData(this)
            arguments
                this (1,1) controllib.chart.response.internal.PZBoundResponse
            end

            if ~isempty(this.ResponseData) && isvalid(this.ResponseData)
                update(this.ResponseData,MinDecay=this.MinDecay_I,...
                    MinDamping=this.MinDamping_I,...
                    MaxFrequency=this.MaxFrequency_I,...
                    Ts=this.Ts_I);
            end
        end
    end

    %% Hidden TuningGoal methods
    methods (Hidden, Access= ?controllib.chart.internal.view.wave.PZBoundResponseView)
        function updateSpectralLimits(this,XLimits,YLimits)
            arguments
                this (1,1) controllib.chart.response.internal.PZBoundResponse
                XLimits (1,2) double
                YLimits (1,2) double
            end
            updateSpectralLimits(this.ResponseData,XLimits,YLimits);
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

