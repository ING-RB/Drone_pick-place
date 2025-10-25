classdef (Hidden) SliderController < ...
        matlab.ui.control.internal.controller.LimitedValueComponentController & ...
        matlab.ui.control.internal.controller.mixin.TickComponentController
    % SliderController controller for Slider

    % Copyright 2021-2023 The MathWorks, Inc.

    methods
        function obj = SliderController(varargin)
            obj@matlab.ui.control.internal.controller.LimitedValueComponentController(varargin{:});
            obj@matlab.ui.control.internal.controller.mixin.TickComponentController(varargin{:});
            obj.NumericProperties{end+1} = 'Step';
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
end
