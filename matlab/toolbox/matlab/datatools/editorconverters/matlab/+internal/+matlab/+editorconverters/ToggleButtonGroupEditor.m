classdef ToggleButtonGroupEditor < ...
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

            props = struct;
            dataTypeName = this.getDataTypeName(this.dataType);

            % Get the possible values from the data type
            props.enumeratedValues = eval([dataTypeName, '.EnumeratedValues']);

            try
                % Get the icon files from the data type
                iconNames = eval([dataTypeName, '.IconNames']);
                props.icons = iconNames;
            catch
                % Ignore errors, typically only in unit tests
            end
        end

        % Called to set the editor state.  Unused.
        function setEditorState(~, ~)
        end
    end
end
