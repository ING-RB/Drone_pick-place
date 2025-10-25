classdef ScaleColorsEditor < internal.matlab.editorconverters.EditorConverter
    % This class is unsupported and might change or be removed without
    % notice in a future version.

    % Copyright 2017-2024 The MathWorks, Inc.

    properties
        value;
        dataType;
        Limits = [];
        ScaleColorLimits = [];

        % Define the Colors property name.  By default this is ScaleColors
        ColorsPropName (1,1) string = "ScaleColors";

        % Define the Color Limits property name.  By default this is
        % ScaleColorLimits
        ColorLimitsPropName (1,1) string = "ScaleColorLimits";
    end

    methods
        % Called to set the client-side value
        function setClientValue(this, value)
            if iscell(value)
                values = NaN(size(value,1), 2);
                for idx = 1:size(value,1)
                    if all(cellfun(@isnumeric, value(idx,:)))
                        v = cell2mat(value(idx, :));
                    else
                        if idx > 1
                            v = values(idx -1, :);
                        elseif ~isempty(this.ScaleColorLimits)
                            v = this.ScaleColorLimits;
                        elseif ~isempty(this.Limits)
                            v = this.Limits;
                        else
                            v = [0 100];
                        end
                    end
                    values(idx,:) = v;
                end
                this.value = values;
            else
                try
                    this.value = evalin('base', ['[' value ']']);
                    if ischar(this.value)
                        this.value = evalin('base', ['{' value '}']);
                    end
                catch
                    this.value = value;
                end

                if isequal(this.dataType, 'internal.matlab.editorconverters.datatype.ScaleColors') && ...
                        ((ischar(this.value) && isvector(this.value)) || (isstring(this.value) && isscalar(this.value)))
                    % Convert ' r, g b ' to {'r' 'g' 'b'} for colors
                    this.value = strsplit(strtrim(this.value), ',|;|\s*', ...
                        'DelimiterType', 'RegularExpression');
                elseif isequal(this.dataType, 'internal.matlab.editorconverters.datatype.ScaleColorLimits') && ...
                        isvector(this.value) && length(this.value) > 2 && isnumeric(this.value)
                    % Convert [1 2 3 4] to [1 2; 2 3; 3 4] for limits
                    lims = ones(length(this.value) - 1, 2);
                    for i = 1:length(this.value) - 1
                        lims(i, :) = this.value(i:i+1);
                    end
                    this.value = lims;
                end
            end
        end

        % Called to get the server-side representation of the value
        function value = getServerValue(this)
            value = feval(this.dataType, this.value);
        end


        % Called to set the server-side value
        function setServerValue(this, value, ~, ~)
            if isa(value, 'internal.matlab.editorconverters.datatype.ScaleColors')
                this.value = value.getColors;
                this.ColorsPropName = value.ColorsPropName;
                this.ColorLimitsPropName = value.ColorLimitsPropName;
            elseif isa(value, 'internal.matlab.editorconverters.datatype.ScaleColorLimits')
                this.value = value.getLimits;
                this.ColorsPropName = value.ColorsPropName;
                this.ColorLimitsPropName = value.ColorLimitsPropName;
            else
                this.value = value;
            end
        end

        % Called to get the client-side representation of the value
        function value = getClientValue(this)
            value = this.value;
        end

        % Called to get the editor state.
        function props = getEditorState(this)
            props = struct;
            props.richEditor = 'rendererseditors/editors/ScaleColorsEditor/ScaleColorsEditor';
            props.richEditorDependencies = {char(this.ColorsPropName), char(this.ColorLimitsPropName), 'Limits'};

            props.colorsPropName = this.ColorsPropName;
            props.colorLimitsPropName = this.ColorLimitsPropName;
        end

        % Called to set the editor state.
        function setEditorState(this, props)
            this.dataType = props.dataType;
            if isfield(props, "Limits")
                this.Limits = props.Limits;
            end
            if isfield(props, this.ColorLimitsPropName)
                this.ScaleColorLimits = props.(this.ColorLimitsPropName);
            end
        end
    end
end
