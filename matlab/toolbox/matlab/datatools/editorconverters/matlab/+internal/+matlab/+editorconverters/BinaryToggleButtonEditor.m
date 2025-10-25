classdef BinaryToggleButtonEditor < ...
        internal.matlab.editorconverters.EditorConverter

    % This class is unsupported and might change or be removed without
    % notice in a future version.

    % This class provides the editor conversion needed for string
    % enumerated values to toggle buttons

    % Copyright 2017-2023 The MathWorks, Inc.

    properties
        % Current value on the server
        value;

        % class path of the data type being edited
        dataType;
    end

    properties(Constant)
        IconMap = containers.Map
    end

    methods

        % Called to set the server-side value
        function setServerValue(this, value, dataType, ~)
            this.value = value;
            this.dataType = dataType;
        end

        % Called to get the server-side representation of the value
        function value = getServerValue(this)
            value = this.value;
        end


        % Called to set the client-side value
        function setClientValue(this, value)
            this.value = value;
        end

        % Called to get the client-side representation of the value
        function varValue = getClientValue(this)
            varValue = this.value;
        end

        % Called to get the editor state, which contains properties
        % specific to the editor
        function props = getEditorState(this)
            % Returns the following properties
            %
            % enumeratedValues - list of programmatic values for the
            % enumerated type
            %
            % icons            - list of icon IDs

            % Get the possible values from the data type
            dataTypeName = this.getDataTypeName(this.dataType);
            if isKey(this.IconMap, dataTypeName)
                props = this.IconMap(dataTypeName);
            else
                props = struct;
                props.enumeratedValues = eval([dataTypeName, '.EnumeratedValues']);

                % Get the icon files from the data type
                iconPath = eval([dataTypeName, '.IconName']);
                props.icon = iconPath;
                this.IconMap(dataTypeName) = props;
            end
        end

        % Called to set the editor state.  Unused.
        function setEditorState(~, ~)
        end
    end
end

