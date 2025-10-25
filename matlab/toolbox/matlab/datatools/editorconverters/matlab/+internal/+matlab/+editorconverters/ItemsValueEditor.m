classdef ItemsValueEditor < internal.matlab.editorconverters.EditorConverter
    % This class is unsupported and might change or be removed without
    % notice in a future version.

    % Copyright 2017-2020 The MathWorks, Inc.

    properties
        value;
        dataType;
    end

    methods
        % Called to set the client-side value
        function setClientValue(this, value)
            if ischar(value) && (startsWith(value, "{") && endsWith(value, "}") || ...
                    startsWith(value, "[") && endsWith(value, "]"))
                value = eval(value);
            end

            this.value = value;
        end

        % Called to get the server-side representation of the value
        function value = getServerValue(this, ~, ~, ~)
            value = this.value;
        end

        % Called to set the server-side value
        function setServerValue(this, value, dataType, ~)
            if ischar(value) && startsWith(value, "{") && endsWith(value, "}")
                value = eval(value);
            end
            this.value = value;
            this.dataType = dataType;
        end

        % Called to get the client-side representation of the value
        function value = getClientValue(this)
            value = this.value;
        end

        % Called to get the editor state.  Unused.
        function props = getEditorState(this)
            props = struct;
            props.outputType = 'array';

            % Setting the editValue assures the value will be interpreted properly, which is
            % needed especially if the value is a cell array
            props.editValue = this.value;
            
            props.richEditorDependencies = {'SelectedIndex', 'Items'};
        end

        % Called to set the editor state.
        function setEditorState(this, props)
            this.dataType = props.dataType;
        end
    end
end
