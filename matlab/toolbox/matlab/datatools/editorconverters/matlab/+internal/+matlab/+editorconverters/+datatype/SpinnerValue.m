classdef SpinnerValue < internal.matlab.editorconverters.datatype.RangeValue
    % This is an interface for data types that want to have their editor be
    % shown with a spinner.  This will happen automatically for scalar values
    % that are defined with restrictions in the property definition, for
    % example:
    %
    % properties
    %    A (1,1) double {mustBePositive} = 1;
    % end
    %
    % But using this type is an alternative, especially useful for dynamic
    % properties where the validation cannot be set.

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