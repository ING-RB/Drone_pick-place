classdef HSVResponse < controllib.chart.internal.foundation.BaseResponse
    % controllib.chart.response.HSVResponse
    %   - manage data and style properties for a response in "hsvplot"
    %   - inherited from controllib.chart.internal.foundation.BaseResponse
    %
    % h = HSVResponse(R)
    %   R       mor.GenericBTSpec
    % 
    % h = HSVResponse(_____,Name-Value)
    %   Name                    response name, string, "" (default)
    %   Style                   response style object, controllib.chart.internal.options.ResponseStyle (default)
    %   Tag                     response tag, string, matlab.lang.internal.uuid (default)
    %   LegendDisplay           show response in legend, matlab.lang.OnOffSwitchState, true (default)
    %   HSVType                 type of HSV response to generate, "sigma" (default)
    %
    % Settable properties:
    %   Name                    label for response in chart, string
    %   Visible                 show response in chart, matlab.lang.OnOffSwitchState
    %   Style                   response style object, controllib.chart.internal.options.ResponseStyle
    %   LegendDisplay           show response in legend, matlab.lang.OnOffSwitchState
    %   UserData                custom data, any MATLAB array
    %   R                       mor.GenericBTSpec for response
    %   PlotType                type of HSV response to generate, string
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
    %   <a href="matlab:help controllib.chart.internal.foundation.BaseResponse">controllib.chart.internal.foundation.BaseResponse</a>

    % Copyright 2023-2024 The MathWorks, Inc.
    
    %% Properties
    properties (Dependent, AbortSet, SetObservable)
        % "SourceData": struct
        % Values used to generate data
        SourceData
    end

    properties (Dependent,AbortSet,SetObservable,Access=protected)
        R
        HSVType
    end

    properties (GetAccess=protected,SetAccess=private)
        R_I
        HSVType_I
    end

    %% Constructor
    methods
        function this = HSVResponse(R,hsvResponseOptionalInputs,baseResponseOptionalInputs)
            arguments
                R (1,1) mor.GenericBTSpec
                hsvResponseOptionalInputs.HSVType (1,1) string {mustBeMember(hsvResponseOptionalInputs.HSVType,["sigma" "energy" "loss"])} = "sigma";
                baseResponseOptionalInputs.?controllib.chart.internal.foundation.BaseResponseOptionalInputs
            end
            R = controllib.chart.response.HSVResponse.parseHSVResponseInputs(R);
            baseResponseOptionalInputs = namedargs2cell(baseResponseOptionalInputs);
            this@controllib.chart.internal.foundation.BaseResponse(baseResponseOptionalInputs{:});

            this.R_I = R;
            this.HSVType_I = hsvResponseOptionalInputs.HSVType;

            build(this);

            this.Type = "hsv";
        end
    end

    %% Get/Set
    methods
        % SourceData
        function SourceData = get.SourceData(this)
            SourceData.R = this.R;
            SourceData.HSVType = this.HSVType;
        end

        function set.SourceData(this,SourceData)
            mustBeMember(fields(SourceData),fields(this.SourceData));
            this.R = SourceData.R;
            this.HSVType = SourceData.HSVType;

            markDirtyAndUpdate(this);
        end

        % R
        function R = get.R(this)
            R = this.R_I;
        end

        function set.R(this,R)
            arguments
                this (1,1) controllib.chart.response.HSVResponse
                R (1,1) mor.GenericBTSpec
            end
            this.R_I = R;
        end

        % HSVType
        function HSVType = get.HSVType(this)
            HSVType = this.HSVType_I;
        end

        function set.HSVType(this,HSVType)
            arguments
                this (1,1) controllib.chart.response.HSVResponse
                HSVType (1,1) string {mustBeMember(HSVType,["sigma","energy","loss"])}
            end
            this.HSVType_I = HSVType;
        end
    end
    
    %% Static methods
    methods (Static)
        function modifyIncomingSerializationContent(thisSerialized)
            if ~thisSerialized.hasNameValue("Version") %24b
                thisSerialized.rename("R","R_I");
                thisSerialized.rename("HSVType","HSVType_I");
            end
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
                this (1,1) controllib.chart.response.HSVResponse
            end
            this.ResponseData = controllib.chart.internal.data.response.HSVResponseDataSource(this.R_I,HSVType=this.HSVType_I);
        end

        function updateData(this)
            arguments
                this (1,1) controllib.chart.response.HSVResponse
            end
            r = controllib.chart.response.HSVResponse.parseHSVResponseInputs(this.R_I);
            if ~isempty(this.ResponseData) && isvalid(this.ResponseData)
                update(this.ResponseData,R=r,HSVType=this.HSVType_I);
            end
        end
    end

    %% Private static methods
    methods (Static,Access=private)
        function R = parseHSVResponseInputs(R)
            try
                R = process(R);
            catch ME
                throw(ME)
            end
        end
    end

    %% Hidden static methods
    methods (Hidden,Static)
        function dataProperties = getDataProperties()
            dataProperties = "SourceData";
        end
        function [styleProperties,hiddenStyleProperties] = getStyleProperties()
            styleProperties = string.empty;
            hiddenStyleProperties = string.empty;
        end
    end
end

