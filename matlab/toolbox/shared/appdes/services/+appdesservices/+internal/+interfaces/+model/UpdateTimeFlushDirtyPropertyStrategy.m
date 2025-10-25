classdef (Hidden) UpdateTimeFlushDirtyPropertyStrategy < ...
        appdesservices.internal.interfaces.model.AbstractDirtyPropertyStrategy
    % RUNTIMEDIRTYPROPERTYSTRATEGY - Implementation of
    % AbstractDirtyPropertyStrategy for deferred 
    % when properties are marked dirty in a Model.
    %
    % When properties are marked dirty, the MCOS base class is informed of
    % their 'dirtiness' but they are not yet flushed to the controller until
    % the UpdateVisitor flush.
    
    % Copyright 2018 MathWorks, Inc.

    properties (Access = protected)
        % MODEL - the cached Model upon which this strategy operates
        Model
    end
    
    methods
        function obj = UpdateTimeFlushDirtyPropertyStrategy(model)
            obj.Model = model;
        end
        
        function markPropertiesDirty(obj, propertyNames)
            % Inform the MCOS superclass that properties are dirty so that
            % UpdateVisitor will be activated.
            obj.Model.doMarkDirty(true);
        end
    end
end
