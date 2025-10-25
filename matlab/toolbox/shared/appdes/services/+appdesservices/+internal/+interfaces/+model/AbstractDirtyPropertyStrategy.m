classdef (Abstract, Hidden) AbstractDirtyPropertyStrategy < handle
    % ABSTRACTDIRTYPROPERTYSTRATEGY - Interface for behavior that happens
    % when properties are marked dirty in a Model
    %
    % AbstractDirtyPropertyStrategy provides the following interfaces:
    %
    % - mark properties dirty;
    %
    % - flush dirty properties to the controller.
    
    % Copyright 2018 MathWorks, Inc.

    
    properties (Abstract, Access = protected)
        % MODEL - the cached Model upon which this strategy operates
        Model
    end
    
    methods (Abstract)
        markPropertiesDirty(obj, propertyNames)
        % MARKDIRTY - Depending on strategy, will perform actions
        % necessary after properties are marked dirty.
    end
    
    methods (Access = protected, Sealed = true)
        function flush(obj)
            % FLUSH - causes the dirty properties in the associated Model
            % to be flushed to the controller/view
            obj.Model.flushDirtyProperties();
        end
    end
end
