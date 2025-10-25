classdef SpinnerEditor < internal.matlab.editorconverters.RangeEditor
    
    % This class is unsupported and might change or be removed without
    % notice in a future version.
    
    % This class provides the editor converter functionality for values
    % which are displayed as a spinner.
    
    % Copyright 2021 The MathWorks, Inc.
    
    properties(Constant, Hidden)
        % Spinner default minimum value
        DEFAULT_SPINNER_MIN = -Inf;

        % Spinner default maximum value
        DEFAULT_SPINNER_MAX = Inf;
    end

    methods
        function [min, max] = getDefaultRange(this)
            min = this.DEFAULT_SPINNER_MIN;
            max = this.DEFAULT_SPINNER_MAX;
        end
        
        function b = supportsIncludeRange(~)
            b = true;
        end
    end
end
