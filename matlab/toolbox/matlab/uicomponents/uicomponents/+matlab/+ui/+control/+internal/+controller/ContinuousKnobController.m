classdef (Hidden) ContinuousKnobController < ...
        matlab.ui.control.internal.controller.LimitedValueComponentController & ...
        matlab.ui.control.internal.controller.mixin.TickComponentController
    % ContinuousKnobController controller for ContinuousKnob

    % Copyright 2011-2021 The MathWorks, Inc.

    methods
        function obj = ContinuousKnobController(varargin)
            obj@matlab.ui.control.internal.controller.LimitedValueComponentController(varargin{:});
            obj@matlab.ui.control.internal.controller.mixin.TickComponentController(varargin{:});
        end
    end

    methods (Access = protected)
        function viewPvPairs = getPropertiesForView(obj, propertyNames)
            viewPvPairs = {};
            viewPvPairs = [viewPvPairs obj.getTickPropertiesForView(propertyNames)];

            viewPvPairs = [viewPvPairs getPropertiesForView@matlab.ui.control.internal.controller.LimitedValueComponentController(obj, propertyNames)];
        end

        function changedPropertiesStruct = handlePropertiesChanged(obj, changedPropertiesStruct)
            changedPropertiesStruct = handlePropertiesChanged@matlab.ui.control.internal.controller.mixin.TickComponentController(obj, changedPropertiesStruct);
            changedPropertiesStruct = handlePropertiesChanged@matlab.ui.control.internal.controller.LimitedValueComponentController(obj, changedPropertiesStruct);
        end

        function handleEvent(obj, src, event)
            handleEvent@matlab.ui.control.internal.controller.mixin.TickComponentController(obj, src, event);
            handleEvent@matlab.ui.control.internal.controller.LimitedValueComponentController(obj, src, event);
        end
    end

    methods(Access = 'protected')

        function componentValue = convertViewValueToComponentValue(obj, viewValue)
            % Override the default behavior because the view does not send
            % the actual component's value

            % The view returns a scaled position of the needle from
            % 0-1, where 0 means that the needle is pointing to the
            % minimum value(lower left) and 1 means that the needle
            % is pointing to maximum(lower right). convert this
            % scaling factor to the value.
            limits = obj.Model.Limits;

            % scale range represents the magnitude of the  "span"
            % of the scale limits, meaning the overall distance
            % between the min and the max
            scaleRange = abs(limits(2) - limits(1));

            % new value is how far along the scale range the user
            % rotated the needle
            componentValue = scaleRange * viewValue + limits(1);
        end

    end

end

