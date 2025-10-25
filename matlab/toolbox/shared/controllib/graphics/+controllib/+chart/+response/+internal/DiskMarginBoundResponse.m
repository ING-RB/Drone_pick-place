classdef DiskMarginBoundResponse < controllib.chart.internal.foundation.BaseResponse
    % controllib.chart.response.DiskMarginBoundResponse
    %   - manage data and style properties for a bound response in "diskmarginplot"
    %   - inherited from controllib.chart.internal.foundation.BaseResponse
    %
    % h = DiskMarginBoundResponse()
    % 
    % h = DiskMarginBoundResponse(_____,Name-Value)
    %   Name                    response name, string, "" (default)
    %   Style                   response style object, controllib.chart.internal.options.ResponseStyle (default)
    %   Tag                     response tag, string, matlab.lang.internal.uuid (default)
    %   LegendDisplay           show response in legend, matlab.lang.OnOffSwitchState, true (default)
    %   BoundType               type of bound, "lower" (default) plots below response data
    %   Focus                   focus of Tuning Goal, [0 Inf] (default)
    %   GM                      gain margin of Tuning Goal, 7.6 (default)
    %   PM                      phase margin of Tuning Goal, 45 (default)
    %   Ts                      sample time of closed-loop system, 0 (default)
    %
    % Settable properties:
    %   Name                    label for response in chart, string
    %   Visible                 show response in chart, matlab.lang.OnOffSwitchState
    %   Style                   response style object, controllib.chart.internal.options.ResponseStyle
    %   LegendDisplay           show response in legend, matlab.lang.OnOffSwitchState
    %   UserData                custom data, any MATLAB array
    %   BoundType               type of bound, string
    %   Focus                   focus of Tuning Goal, double
    %   GM                      gain margin of Tuning Goal, double
    %   PM                      phase margin of Tuning Goal, double
    %   Ts                      sample time of closed-loop system, double
    %
    % Read-Only properties:
    %   FrequencyUnit    string specifying frequency unit, based on Model TimeUnit.
    %   MagnitudeUnit    string specifying magnitude unit.
    %   PhaseUnit        string specifying phase unit.
    %
    % See Also:
    %   <a href="matlab:help controllib.chart.internal.foundation.BaseResponse">controllib.chart.internal.foundation.BaseResponse</a>

    % Copyright 2023-2024 The MathWorks, Inc.
    
    %% Properties
    properties(Hidden,Dependent, AbortSet, SetObservable)
        % "BoundType": string scalar
        % Type of response bound.
        BoundType
        % "Focus": 1x2 double
        % Frequency focus of Tuning Goal.
        Focus
        % "GM": double scalar
        % Gain margin of Tuning Goal in dB.
        GM
        % "PM": double scalar
        % Phase margin of Tuning Goal in deg.
        PM
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
        % "FrequencyUnit": string
        % Get FrequencyUnit of ResponseData.
        FrequencyUnit = "rad/s"
        % "MagnitudeUnit": string
        % Get MagnitudeUnit of ResponseData.
        MagnitudeUnit = "dB"
        % "PhaseUnit": string
        % Get PhaseUnit of ResponseData.
        PhaseUnit = "deg"
    end

    properties (GetAccess = protected,SetAccess=private)
        BoundType_I
        Focus_I
        GM_I
        PM_I
        Ts_I
    end

    %% Constructor
    methods
        function this = DiskMarginBoundResponse(diskMarginBoundResponseOptionalInputs,baseResponseOptionalInputs)
            arguments
                diskMarginBoundResponseOptionalInputs.BoundType (1,1) string...
                    {mustBeMember(diskMarginBoundResponseOptionalInputs.BoundType,["upper","lower"])} = "lower"
                diskMarginBoundResponseOptionalInputs.Focus (1,2) double = [0 Inf]
                diskMarginBoundResponseOptionalInputs.GM (1,1) double {mustBePositive} = 7.6
                diskMarginBoundResponseOptionalInputs.PM (1,1) double...
                    {mustBeInRange(diskMarginBoundResponseOptionalInputs.PM,0,180)} = 45
                diskMarginBoundResponseOptionalInputs.Ts (1,1) double...
                    {controllib.chart.internal.utils.validators.mustBeSampleTime} = 0
                baseResponseOptionalInputs.?controllib.chart.internal.foundation.BaseResponseOptionalInputs
            end
            diskMarginBoundResponseOptionalInputs = controllib.chart.response.internal.DiskMarginBoundResponse.parseDiskMarginBoundResponseInputs(diskMarginBoundResponseOptionalInputs);
            baseResponseOptionalInputs = namedargs2cell(baseResponseOptionalInputs);
            this@controllib.chart.internal.foundation.BaseResponse(baseResponseOptionalInputs{:});

            this.LegendDisplay = 'off';
            this.BoundType_I = diskMarginBoundResponseOptionalInputs.BoundType;
            this.Focus_I = diskMarginBoundResponseOptionalInputs.Focus;
            this.GM_I = diskMarginBoundResponseOptionalInputs.GM;
            this.PM_I = diskMarginBoundResponseOptionalInputs.PM;
            this.Ts_I = diskMarginBoundResponseOptionalInputs.Ts;
            build(this);

            this.Type = "diskMarginBound";
        end
    end

    %% Get/Set
    methods
        % BoundType
        function BoundType = get.BoundType(this)
            arguments
                this (1,1) controllib.chart.response.internal.DiskMarginBoundResponse
            end
            BoundType = this.BoundType_I;
        end

        function set.BoundType(this,BoundType)
            arguments
                this (1,1) controllib.chart.response.internal.DiskMarginBoundResponse
                BoundType (1,1) string {mustBeMember(BoundType,["upper","lower"])}
            end
            try
                this.BoundType_I = BoundType;
                markDirtyAndUpdate(this);
            catch ME
                error(ME.message);
            end
        end

        % GM
        function GM = get.GM(this)
            arguments
                this (1,1) controllib.chart.response.internal.DiskMarginBoundResponse
            end
            GM = this.GM_I;
        end

        function set.GM(this,GM)
            arguments
                this (1,1) controllib.chart.response.internal.DiskMarginBoundResponse
                GM (1,1) double {mustBePositive}
            end
            try
                this.GM_I = GM;
                markDirtyAndUpdate(this);
            catch ME
                error(ME.message);
            end
        end

        % PM
        function PM = get.PM(this)
            arguments
                this (1,1) controllib.chart.response.internal.DiskMarginBoundResponse
            end
            PM = this.PM_I;
        end

        function set.PM(this,PM)
            arguments
                this (1,1) controllib.chart.response.internal.DiskMarginBoundResponse
                PM (1,1) double {mustBeInRange(PM,0,180)}
            end
            try
                this.PM_I = PM;
                markDirtyAndUpdate(this);
            catch ME
                error(ME.message);
            end
        end

        function Focus = get.Focus(this)
            arguments
                this (1,1) controllib.chart.response.internal.DiskMarginBoundResponse
            end
            Focus = this.Focus_I;
        end

        function set.Focus(this,Focus)
            arguments
                this (1,1) controllib.chart.response.internal.DiskMarginBoundResponse
                Focus (1,2) double
            end
            try
                this.Focus_I = Focus;
                markDirtyAndUpdate(this);
            catch ME
                error(ME.message);
            end
        end

        % Ts
        function Ts = get.Ts(this)
            arguments
                this (1,1) controllib.chart.response.internal.DiskMarginBoundResponse
            end
            Ts = this.Ts_I;
        end

        function set.Ts(this,Ts)
            arguments
                this (1,1) controllib.chart.response.internal.DiskMarginBoundResponse
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
                this (1,1) controllib.chart.response.internal.DiskMarginBoundResponse
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
                this (1,1) controllib.chart.response.internal.DiskMarginBoundResponse
            end
            this.ResponseData = controllib.chart.internal.data.response.DiskMarginBoundResponseDataSource(...
                GM=this.GM_I,PM=this.PM_I,Focus=this.Focus_I,Ts=this.Ts_I);
        end

        function updateData(this)
            arguments
                this (1,1) controllib.chart.response.internal.DiskMarginBoundResponse
            end
            options.BoundType = this.BoundType_I;
            options.Focus = this.Focus_I;
            options.GM = this.GM_I;
            options.PM = this.PM_I;
            options.Ts = this.Ts_I;
            options = controllib.chart.response.internal.DiskMarginBoundResponse.parseDiskMarginBoundResponseInputs(options);
            if ~isempty(this.ResponseData) && isvalid(this.ResponseData)
                update(this.ResponseData,BoundType=options.BoundType,...
                    Focus=options.Focus,...
                    GM=options.GM,...
                    PM=options.PM,...
                    Ts=options.Ts);
            end
        end
    end

    %% Private static methods
    methods (Static,Access=private)
        function diskMarginBoundResponseOptionalInputs = parseDiskMarginBoundResponseInputs(diskMarginBoundResponseOptionalInputs)
            % Parse Focus
            try
                mustBeInRange(diskMarginBoundResponseOptionalInputs.Focus(1),0,diskMarginBoundResponseOptionalInputs.Focus(2),'exclude-upper')
                mustBeInRange(diskMarginBoundResponseOptionalInputs.Focus(2),diskMarginBoundResponseOptionalInputs.Focus(1),Inf,'exclude-lower')
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

