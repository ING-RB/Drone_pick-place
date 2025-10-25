classdef RangeValue
    % This is an abstact class for data types that want to have a value,
    % minimum value, maximum value, and step.

    % Copyright 2021 The MathWorks, Inc.

    properties
        % Range value
        Value

        % Range Minimum value
        MinValue(1,1) double;

        % Range Maximum value
        MaxValue(1,1) double;

        % Range Step.  Default to NaN to differentiate between user specified
        % step values and a default value.  The EditorConverter will pick the
        % appropriate step if it is not specified.
        Step(1,1) double = NaN;

        % Whether to include the minimum value in the range, default is true
        IncludeMin(1,1) logical = true;

        % Whether to include the maximum value in the range, default is true
        IncludeMax(1,1) logical = true;
    end

    methods
        function this = RangeValue(value, options)
            % Construct a RangeValue object.  Options can contain the
            % MinValue, MaxValue, IncludeMin, IncludeMax, and Step.
            arguments
                value;

                options.MinValue;
                options.MaxValue;
                options.IncludeMin;
                options.IncludeMax;
                options.Step;
            end

            this.Value = value;

            [min, max] = this.getDefaultRange();
            if isfield(options, "MinValue")
                this.MinValue = options.MinValue;
            else
                this.MinValue = min;
            end

            if isfield(options, "MaxValue")
                this.MaxValue = options.MaxValue;
            else
                this.MaxValue = max;
            end

            if isfield(options, "IncludeMin")
                this.IncludeMin = options.IncludeMin;
            end

            if isfield(options, "IncludeMax")
                this.IncludeMax = options.IncludeMax;
            end

            if isfield(options, "Step")
                this.Step = options.Step;
            end
        end

        function s = getValidationStruct(this)
            % Returns a struct containing the validation settings for this
            % range value.

            arguments
                this
            end

            s = struct;
            s.MinValue = this.MinValue;
            s.MaxValue = this.MaxValue;

            if this.supportsIncludeRange
                s.IncludeMin = this.IncludeMin;
                s.IncludeMax = this.IncludeMax;
            end
            s.Step = this.Step;
        end
    end

    methods(Abstract)
        % Returns the default range min and max values
        [min, max] = getDefaultRange(this)
        
        % Returns true if the range supports includesMin/Max settings
        b = supportsIncludeRange(this)
    end
end
