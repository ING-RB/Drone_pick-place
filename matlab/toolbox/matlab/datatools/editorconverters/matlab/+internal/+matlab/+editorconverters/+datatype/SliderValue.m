classdef SliderValue < internal.matlab.editorconverters.datatype.RangeValue
    % This is an interface for data types that want to have their editor be
    % shown with a slider.

    % Copyright 2021 The MathWorks, Inc.

    properties(Constant, Hidden)
        % Slider default minimum value
        DEFAULT_SLIDER_MIN = 0;

        % Slider default maximum value
        DEFAULT_SLIDER_MAX = 10;
    end

    methods
        function [min, max] = getDefaultRange(this)
            min = this.DEFAULT_SLIDER_MIN;
            max = this.DEFAULT_SLIDER_MAX;
        end
        
        function b = supportsIncludeRange(~)
            b = false;
        end
    end
end
