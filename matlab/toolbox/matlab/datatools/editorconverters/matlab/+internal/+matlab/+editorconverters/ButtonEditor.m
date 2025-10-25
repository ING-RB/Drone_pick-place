classdef ButtonEditor < internal.matlab.editorconverters.EditorConverter

    % This class is unsupported and might change or be removed without
    % notice in a future version.

    % This class provides the editor converter functionality for values
    % which are displayed as buttons.

    % Copyright 2022 The MathWorks, Inc.

    properties
        Text
        ButtonPushedFcn
        Value
    end

    methods
        % Called to set the server-side value
        function setServerValue(this, dataValue, ~, ~)
            if isa(dataValue, "internal.matlab.editorconverters.datatype.ButtonValue")
                this.Text = dataValue.Text;
                this.ButtonPushedFcn = dataValue.ButtonPushedFcn;
                this.Value = dataValue;
            else
                this.Value = internal.matlab.editorconverters.datatype.ButtonValue('', function_handle.empty);
            end
        end

        % Called to set the client-side value
        function setClientValue(this, ~)
            this.ButtonPushedFcn()
        end

        % Called to get the server-side representation of the value
        function value = getServerValue(this)
            value = this.Value;
        end

        % Called to get the client-side representation of the value
        function value = getClientValue(~)
            value = '';
        end

        % Called to get the editor state, which contains properties
        % specific to the range editor
        function props = getEditorState(this)
            props = struct;

            props.Text = this.Text;
        end

        % Called to set the editor state.
        function setEditorState(~, ~)
        end
    end
end
