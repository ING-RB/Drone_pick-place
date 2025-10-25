classdef (Hidden) ImmediateFlushDirtyPropertyStrategy < ...
        appdesservices.internal.interfaces.model.AbstractDirtyPropertyStrategy
    % DESIGNTIMEDIRTYPROPERTYSTRATEGY - Implementation of
    % AbstractDirtyPropertyStrategy for use with models at DesignTime,
    % when properties are marked dirty in a Model.
    %
    % When properties are marked dirty, those properties are immediately
    % flushed to the controller.
    
    % Copyright 2018 MathWorks, Inc.

    properties (Access = protected)
        % MODEL - the cached Model upon which this strategy operates
        Model
    end
    
    methods
        function obj = ImmediateFlushDirtyPropertyStrategy(model)
            obj.Model = model;
        end
        
        function markPropertiesDirty(obj, propertyNames)
            % Mark properties dirty, and immediately flush them to the
            % controller.
            obj.flush();
        end
    end
end

