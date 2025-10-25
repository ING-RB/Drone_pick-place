classdef SliderEditor < internal.matlab.editorconverters.RangeEditor
    
    % This class is unsupported and might change or be removed without
    % notice in a future version.
    
    % This class provides the editor converter functionality for values
    % which are displayed as a spinner.
    
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
