classdef ItemsEditor < internal.matlab.editorconverters.EditorConverter
    % This class is unsupported and might change or be removed without
    % notice in a future version.

    % Copyright 2017-2022 The MathWorks, Inc.

    properties
        value;
        dataType;
    end

    methods
        % Called to set the client-side value
        function setClientValue(this, value)
            if iscell(value) && length(value) == 1
                value = value{1};
            end
            if ischar(value) && startsWith(value, "{") && endsWith(value, "}")
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
            props.richEditor = 'rendererseditors/editors/ItemsEditor/ItemsEditor';
            props.richEditorDependencies = {'SelectedIndex', 'Items'};

            dataTypeName = this.getDataTypeName(this.dataType);
            minNumber = eval([dataTypeName, '.MinNumber']);
            maxNumber = eval([dataTypeName, '.MaxNumber']);
            defaultNameKey = eval([dataTypeName, '.DefaultNameKey']);
            if ~isempty(minNumber)
                props.minNumber = minNumber;
            end

            if ~isempty(maxNumber)
                props.maxNumber = maxNumber;
            end

            if ~isempty(defaultNameKey)
                props.defaultNameKey = defaultNameKey;
            end

            props.outputType = 'array';
        end

        % Called to set the editor state.
        function setEditorState(this, props)
            this.dataType = props.dataType;
        end
    end
end
