classdef TimeSteadyStateData < controllib.chart.internal.data.characteristics.BaseCharacteristicData
    % controllib.chart.internal.data.TimeSteadyStateData
    %   - class for computing steady state of time plots
    %   - inherited from controllib.chart.internal.data.characteristics.BaseCharacteristicData
    %
    % h = TimeSteadyStateData(data)
    %   data   controllib.chart.internal.data.response.BaseResponseDataSource
    %
    % Read-only Properties:
    %   ResponseData            response data object, controllib.chart.internal.data.response.BaseResponseDataSource
    %   Type                    type of characteristics, string scalar
    %   IsDirty                 flag if response needs to be computed, logical scalar
    %   Value                   steady state value
    %
    % Events:
    %   DataChanged             notified in update()
    %
    % Public methods:
    %   update(this)
    %       Update the the characteristic data using ResponseData. Marks IsDirty as true.
    %   compute(this)
    %       Computes the characteristic data with stored Data. Marks IsDirty as false.
    %
    % Protected methods (override in subclass):
    %   compute_(this)
    %       Compute the characteristic data. Called in compute(). Implement in subclass.
    %   postUpdate(this)
    %       Called after updating the data. Implement in subclass if needed.
    %
    % See Also:
    %   <a href="matlab:help controllib.chart.internal.data.characteristics.BaseCharacteristicData">controllib.chart.internal.data.characteristics.BaseCharacteristicData</a>
    
    % Copyright 2022-2024 The MathWorks, Inc.
    properties (SetAccess=protected)
        Value
    end

    methods
        function this = TimeSteadyStateData(data)
            this@controllib.chart.internal.data.characteristics.BaseCharacteristicData(data);
            this.Type = "SteadyState";
        end
    end

    methods (Access = protected)
        function compute_(this)
            [valueReal,valueImaginary] = getFinalValue(this.ResponseData,"all",1:this.ResponseData.NResponses);
            if ~iscell(valueReal)
                valueReal = {valueReal};
                valueImaginary = {valueImaginary};
            end
            this.Value = cellfun(@(x,y) x + 1i*y,valueReal,valueImaginary,UniformOutput=false);
        end
    end
end
