classdef ComponentAddedEventData < event.EventData
    % COMPONENTADDEDEVENTDATA Argument to notify() when a new
    % component is added.

    % Copyright 2023 The MathWorks, Inc.

    properties
        Component
    end

    methods
        function obj = ComponentAddedEventData(component)
            obj.Component = component;
        end
    end
end