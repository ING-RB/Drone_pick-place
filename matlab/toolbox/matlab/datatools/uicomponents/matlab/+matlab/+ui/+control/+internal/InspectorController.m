classdef (Hidden) InspectorController < ...
        matlab.ui.control.internal.controller.ComponentController
    % InspectorController is the controller for Inspector component

    % Copyright 2022 The MathWorks, Inc.

    methods
        function obj = InspectorController(varargin)
            obj@matlab.ui.control.internal.controller.ComponentController(varargin{:});
        end
    end

    methods(Access = 'protected')
        function propertyNames = getAdditionalPropertyNamesForView(obj)
            % Get additional properties to be sent to the view

            propertyNames = getAdditionalPropertyNamesForView@matlab.ui.control.internal.controller.ComponentController(obj);
        end

        function handleEvent(obj, src, event)
            % Allow super classes to handle their events
            handleEvent@matlab.ui.control.internal.controller.ComponentController(obj, src, event);
        end

        function changedPropertiesStruct = handlePropertiesChanged(obj, changedPropertiesStruct)
            % Handle specific property sets

            %% Special property handling goes here

            % Call the superclasses for unhandled properties
            handlePropertiesChanged@matlab.ui.control.internal.controller.ComponentController(obj, changedPropertiesStruct);
        end
    end
end

