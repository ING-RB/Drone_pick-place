classdef (Hidden) ObservableUpdateTimeDirtyPropertyStrategy < ...
        appdesservices.internal.interfaces.model.AbstractDirtyPropertyStrategy
    % OBSERVABLEUPDATETIMEDIRTYPROPERTYSTRATEGY - Implementation of
    % AbstractDirtyPropertyStrategy for deferred
    % when properties are marked dirty in a Model.  Also immediately
    % forwards dirty properties via an event.
    %
    % When properties are marked dirty, the MCOS base class is informed of
    % their 'dirtiness' but they are not yet flushed to the controller until
    % the UpdateVisitor flush.

    % Copyright 2019 MathWorks, Inc.

    properties (Access = protected)
        % MODEL - the cached Model upon which this strategy operates
        Model
    end

    events
        PropertiesMarkedDirty
    end

    methods
        function obj = ObservableUpdateTimeDirtyPropertyStrategy(model)
            obj.Model = model;
        end

        function markPropertiesDirty(obj, propertyNames)
            % Inform the MCOS superclass that properties are dirty so that
            % UpdateVisitor will be activated.
            obj.Model.doMarkDirty(true);

            % Forward property sets via an event
            eventdata = appdesservices.internal.interfaces.model.PropertiesMarkedDirtyEventData(propertyNames);
            notify(obj, 'PropertiesMarkedDirty', eventdata);
        end
    end
end
