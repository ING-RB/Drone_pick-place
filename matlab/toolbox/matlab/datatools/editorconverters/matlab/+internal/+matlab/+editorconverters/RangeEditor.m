classdef RangeEditor < internal.matlab.editorconverters.EditorConverter

    % This class is unsupported and might change or be removed without
    % notice in a future version.

    % This class provides the editor converter functionality for values
    % which are displayed as an editor with a range.

    % Copyright 2021 The MathWorks, Inc.

    properties
        Value;
        MinValue(1,1) double;
        MaxValue(1,1) double;
        IncludeMin(1,1) logical = true;
        IncludeMax(1,1) logical = true;
        Step(1,1) double = NaN;
    end

    properties(Hidden)
        % Whether the validation was explicitly set or not
        ValidationSet(1,1) logical = false;
    end

    properties(Constant, Hidden)
        % Used to determine the step if the value is not set, and a
        % step of 1 is too large
        DEFAULT_DISCRETE_VALUES = 10;
    end

    methods
        function this = RangeEditor()
            [min, max] = this.getDefaultRange();
            this.MinValue = min;
            this.MaxValue = max;
        end

        % Called to set the server-side value
        function setServerValue(this, dataValue, ~, ~)
            if isa(dataValue, "internal.matlab.editorconverters.datatype.RangeValue")
                % If the value is a RangeValue, use its validation
                % settings to configure the editor
                this.Value = dataValue.Value;
                this.setValidation(dataValue.getValidationStruct());
                this.ValidationSet = true;
            else
                this.Value = dataValue;

                % Set default step value since the validation wasn't set
                this.Step = 1;
            end
        end

        function setValidation(this, validation)
            % Called to set the validation settings for the property being
            % displayed as an editor with a range.
            %
            % The validation struct is expected to have these fields at a
            % minimum:  MinValue, MaxValue, IncludeMin, and IncludeMax
            %
            % It can optionally contain:  Step
            arguments
                this

                validation(1,1) struct
            end
            this.MinValue = validation.MinValue;
            this.MaxValue = validation.MaxValue;

            if isfield(validation, "IncludeMin")
                this.IncludeMin = validation.IncludeMin;
            end

            if isfield(validation, "IncludeMax")
                this.IncludeMax = validation.IncludeMax;
            end

            if isfield(validation, "Step")
                this.Step = validation.Step;
            end
        end

        % Called to set the client-side value
        function setClientValue(this, value)
            if ischar(value)
                this.Value = str2double(value);
            else
                this.Value = value;
            end
        end

        % Called to get the server-side representation of the value
        function value = getServerValue(this)
            value = this.Value;
        end

        % Called to get the client-side representation of the value
        function value = getClientValue(this)
            value = this.Value;
        end

        % Called to get the editor state, which contains properties
        % specific to the range editor
        function props = getEditorState(this)
            props = struct;
            props.MinValue = this.MinValue;
            props.MaxValue = this.MaxValue;

            if this.supportsIncludeRange
                props.IncludeMin = this.IncludeMin;
                props.IncludeMax = this.IncludeMax;
            end

            if isnan(this.Step) || ~this.ValidationSet
                % The client did not explicity set the step.  Default to 1,
                % unless creating 10 discrete steps is less than 1, in which
                % case use that value
                this.Step = min(1, (this.MaxValue - this.MinValue)/this.DEFAULT_DISCRETE_VALUES);
            end
            props.Step = this.Step;
        end

        % Called to set the editor state.
        function setEditorState(~, ~)
        end
    end
    
    methods(Abstract)
        % Returns the default range min and max values
        [min, max] = getDefaultRange(this)
        
        % Returns true if the range supports includesMin/Max settings
        b = supportsIncludeRange(this)
    end
end
