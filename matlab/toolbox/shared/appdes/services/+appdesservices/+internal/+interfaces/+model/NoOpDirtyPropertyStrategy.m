classdef (Hidden) NoOpDirtyPropertyStrategy < ...
        appdesservices.internal.interfaces.model.AbstractDirtyPropertyStrategy
    % NOOPDIRTYPROPERTYSTRATEGY - Implementation of
    % AbstractDirtyPropertyStrategy for use before any controller has been
    % installed.
    %
    % This strategy performs no operation when properties are marked dirty.
    
    % Copyright 2018 MathWorks, Inc.

    properties (Access = protected)
        % MODEL - the cached Model upon which this strategy operates
        Model
    end
    
    methods
        function obj = NoOpDirtyPropertyStrategy(model)
            obj.Model = model;
        end
        
        function markPropertiesDirty(obj, propertyNames)
        end
        
    end
end

