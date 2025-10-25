classdef ModelSource < matlab.mixin.SetGet & matlab.mixin.Copyable
    % Handle wrapper for DynamicSystem object.

    % Copyright 2024 The MathWorks, Inc.

    %% Properties
    properties (Dependent,SetObservable)
        Model
    end

    properties (GetAccess = protected,...
            SetAccess={...
            ?controllib.chart.internal.foundation.ModelResponse, ...
            ?controllib.chart.internal.utils.IODataSource})
        Model_I
    end

    %% Constructor
    methods
        function this = ModelSource(Model)
           if nargin>0
              validateattributes(Model,'ltipack.LabeledIOModel',{},'ModelSource','Model',1)
              this.Model = Model;
           end
        end
    end
    
    %% Get/Set
    methods
        % Model
        function Model = get.Model(this)
            Model = this.Model_I;
        end

        function set.Model(this,Model)
           setModel_(this,Model);
        end
    end

    methods (Access = protected)
        function setModel_(this,Model)
             arguments
                 this (1,1) controllib.chart.internal.utils.ModelSource
                 Model DynamicSystem
             end
             Model = checkModel(this,Model);
             this.Model_I = Model;
        end

        function checkedModel = checkModel(this,Model)
            % Overload this method in subclass to add specific checks or
            % modify the Model
            if isa(Model,'idlti') && size(Model,2) == 0
                checkedModel = noise2meas(Model);
            else
                checkedModel = Model;
            end
        end
    end
end