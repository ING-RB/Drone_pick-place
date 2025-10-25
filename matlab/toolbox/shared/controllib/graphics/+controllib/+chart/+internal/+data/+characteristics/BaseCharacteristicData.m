classdef (Abstract) BaseCharacteristicData < matlab.mixin.SetGet & matlab.mixin.Heterogeneous & matlab.mixin.Copyable
    % controllib.chart.internal.data.BaseCharacteristicData
    %   - base class for computing a specific characteristic data of a response
    %
    % h = BaseCharacteristicData(data)
    %   data   controllib.chart.internal.data.response.BaseResponseDataSource
    %
    % Read-only Properties:
    %   ResponseData            response data object, controllib.chart.internal.data.response.BaseResponseDataSource
    %   Type                    type of characteristics, string scalar
    %   IsDirty                 flag if response needs to be computed, logical scalar
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
    %   postUpdate(this)
    %       Called after updating the data. Implement in subclass if needed.
    %
    % Abstract methods
    %   compute_(this)
    %       Compute the characteristic data. Called in compute(). Implement in subclass.
    
    % Copyright 2022-2024 The MathWorks, Inc.

    %% Properties
    properties (WeakHandle,SetAccess = {?controllib.chart.internal.data.characteristics.BaseCharacteristicData,...
            ?controllib.chart.internal.data.response.BaseResponseDataSource})
        ResponseData controllib.chart.internal.data.response.BaseResponseDataSource
    end

    properties (SetAccess = protected)
        Type string {mustBeValidVariableName}
        IsDirty = true
    end
    
    %% Events
    events
        DataChanged
    end
    
    %% Constructor
    methods
        function this = BaseCharacteristicData(data)
            this.ResponseData = data;
            this.Type = "BaseCharacteristicData";
        end
    end

    %% Public methods
    methods
        function update(this)
            this.IsDirty = true;
            postUpdate(this);
            notify(this,'DataChanged');
        end

        function compute(this)
            if this.IsDirty
                compute_(this);
                this.IsDirty = false;
            end
        end
    end
    
    %% Protected methods
    methods(Access = protected)
        function postUpdate(this)

        end
    end
    
    %% Abstract methods
    methods(Abstract,Access = protected)
        compute_(this)
    end
end