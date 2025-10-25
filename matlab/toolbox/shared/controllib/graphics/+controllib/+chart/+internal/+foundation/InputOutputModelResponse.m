classdef InputOutputModelResponse < controllib.chart.internal.foundation.ModelResponse & ...
        controllib.chart.internal.foundation.MixInInputOutputResponse
    % controllib.chart.internal.foundation.InputOutputModelResponse
    %   - base class for managing data and style for an input/output model-based response in Control charts
    %   - inherited from controllib.chart.internal.foundation.BaseResponse
    %
    % h = ModelResponse(model)
    %   model           DynamicSystem
    %
    % h = ModelResponse(_____,Name-Value)
    %   Name            response name, string, "" (default)
    %   Style           response style object, controllib.chart.internal.options.ResponseStyle (default)
    %   Tag             response tag, string, matlab.lang.internal.uuid (default)
    %   LegendDisplay   show response in legend, matlab.lang.OnOffSwitchState, true (default)
    %
    % Settable properties:
    %   Name            label for response in chart, string
    %   Visible         show response in chart, matlab.lang.OnOffSwitchState
    %   Style           response style object, controllib.chart.internal.options.ResponseStyle
    %   LegendDisplay   show response in legend, matlab.lang.OnOffSwitchState
    %   UserData        custom data, any MATLAB array
    %   Model           DynamicSystem for response
    %
    % Read-Only / Internal properties (for subclasses):
    %   Tag                  unique tag for indexing, string
    %   Type                 type of response for subclass, string
    %   AutoGenerateXData    logical value used to set limits focus, matlab.lang.OnOffSwitchState
    %   ArrayDim             array dimensions of ResponseData, double
    %   NResponses           number of elements in array of ResponseData, double
    %   CharacteristicTypes  characteristic types of response data, string
    %   ResponseData         data source object, controllib.chart.internal.data.response.BaseResponseDataSource
    %   IsDiscrete           logical value to specify if Model is discrete
    %   IsReal               logical value to specify if Model is real
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
    %   <a href="matlab:help controllib.chart.internal.foundation.ModelResponse">controllib.chart.internal.foundation.ModelResponse</a>

    % Copyright 2024 The MathWorks, Inc.

    %% Constructor
    methods
        function this = InputOutputModelResponse(modelSource,varargin)
            arguments
                modelSource (1,1) controllib.chart.internal.utils.ModelSource
            end

            arguments (Repeating)
                varargin
            end
            
            this@controllib.chart.internal.foundation.ModelResponse(modelSource,varargin{:});

            [inputNames,outputNames] = controllib.chart.internal.foundation.ModelResponse.getIONamesFromModel(modelSource.Model);

            this.NInputs = length(inputNames);
            this.NOutputs = length(outputNames);
            this.InputNames = inputNames;
            this.OutputNames = outputNames;
        end
    end

    %% Static methods
    methods (Static)
        function modifyIncomingSerializationContent(thisSerialized)
            if ~thisSerialized.hasNameValue("Version") %24b
                thisSerialized.rename("controllib.chart.internal.foundation.MixInColumnResponse.ColumnNames_I","ColumnNames_I");
                thisSerialized.rename("controllib.chart.internal.foundation.MixInColumnResponse.NColumns_I","NColumns_I");
                thisSerialized.rename("controllib.chart.internal.foundation.MixInRowResponse.NRows_I","NRows_I");
                thisSerialized.rename("controllib.chart.internal.foundation.MixInRowResponse.RowNames_I","RowNames_I");
            end
            modifyIncomingSerializationContent@controllib.chart.internal.foundation.ModelResponse(thisSerialized);
        end
    end

    %% Protected methods
    methods (Access = protected)
        function updateData(this,varargin)
            updateData@controllib.chart.internal.foundation.ModelResponse(this,varargin{:});

            [inputNames,outputNames] = this.getIONamesFromModel(this.Model);

            this.NInputs = length(inputNames);
            this.NOutputs = length(outputNames);
            this.InputNames = inputNames;
            this.OutputNames = outputNames;
        end
    end
end
