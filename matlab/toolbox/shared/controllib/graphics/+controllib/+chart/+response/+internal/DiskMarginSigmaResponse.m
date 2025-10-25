classdef DiskMarginSigmaResponse < controllib.chart.response.DiskMarginResponse
    % controllib.chart.response.internal.DiskMarginSigmaResponse
    %   - manage data and style properties for a response in "diskmarginplot"
    %   - used in TuningGoal.Margins
    %   - inherited from controllib.chart.response.DiskMarginResponse 
    %
    % h = DiskMarginSigmaResponse(model)
    %   model       DynamicSystem
    % 
    % h = DiskMarginSigmaResponse(_____,Name-Value)
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
    %   FrequencyUnit    char array specifying frequency unit, based on Model TimeUnit.
    %   MagnitudeUnit    char array specifying magnitude unit.
    %   PhaseUnit        char array specifying phase unit.
    %
    % See Also:
    %   <a href="matlab:help controllib.chart.internal.foundation.InputOutputModelResponse">controllib.chart.internal.foundation.InputOutputModelResponse</a>

    % Copyright 2023-2024 The MathWorks, Inc.

    %% Constructor
    methods
        function this = DiskMarginSigmaResponse(modelSource,diskMarginResponseOptionalInputs,baseResponseOptionalInputs)
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
            
            diskMarginResponseOptionalInputs = namedargs2cell(diskMarginResponseOptionalInputs);
            baseResponseOptionalInputs = namedargs2cell(baseResponseOptionalInputs);
            this@controllib.chart.response.DiskMarginResponse(modelSource,diskMarginResponseOptionalInputs{:},baseResponseOptionalInputs{:});
        end
    end
    

    %% Static methods
    methods (Static)
        function modifyIncomingSerializationContent(thisSerialized)
            modifyIncomingSerializationContent@controllib.chart.response.DiskMarginResponse(thisSerialized);
        end

        function this = finalizeIncomingObject(this)
            this = finalizeIncomingObject@controllib.chart.response.DiskMarginResponse(this);
        end

        function modifyOutgoingSerializationContent(thisSerialized,this)
            modifyOutgoingSerializationContent@controllib.chart.response.DiskMarginResponse(thisSerialized,this);
        end
    end

    %% Protected methods (override in subclass)
    methods (Access = protected)
        function initializeData(this)
            arguments
                this (1,1) controllib.chart.response.internal.DiskMarginSigmaResponse
            end
            this.ResponseData = controllib.chart.internal.data.response.DiskMarginSigmaResponseDataSource(...
                this.Model,Skew=this.Skew,Frequency=this.FrequencySpec);
        end
    end
end

