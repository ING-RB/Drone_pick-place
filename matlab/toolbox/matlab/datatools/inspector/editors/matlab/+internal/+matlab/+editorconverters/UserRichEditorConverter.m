% This class is unsupported and might change or be removed without notice in a
% future version.

% This is editor converter for a property which defines a rich editor UI for
% editing in the Property Inspector.

% Copyright 2022-2023 The MathWorks, Inc.

classdef UserRichEditorConverter < internal.matlab.editorconverters.EditorConverter

    properties
        Value
    end

    properties(Access = private)
        CurrentValue
    end

    properties(Access = private, Constant)
        RICH_EDITOR_CLOSED = "%CLOSE";
    end

    methods
        % Called to set the server-side value
        function setServerValue(this, value, ~, ~)
            this.Value = value;
        end

        % Called to set the client-side value
        function setClientValue(this, value)
            if strcmp(value, this.RICH_EDITOR_CLOSED)
                % Special value used when the rich editor is closed.  Handle
                % this separately, and don't change the current value.
                this.CurrentValue.RichEditorUI.richEditorClosed();

                % Use the CurrentValue, so there's no changes which will be
                % processed when the editor just closes.
                this.Value = this.CurrentValue;
            else
                this.Value = value;
            end
        end

        % Called to get the server-side representation of the value
        function value = getServerValue(this)
            value = this.Value;
        end

        % Called to get the client-side representation of the value
        function varValue = getClientValue(this)
            if isa(this.Value, "internal.matlab.editorconverters.datatype.UserRichEditorUIType")
                varValue = this.Value.Value;
            else
                varValue = this.Value;
            end
            if iscell(varValue) && ~iscellstr(varValue) %#ok<ISCLSTR>
                varValue = cellstr(cellfun(@string, varValue, "UniformOutput", false));
            end
        end

        % Called to get the editor state, which contains properties specific to
        % the editor
        function props = getEditorState(this)
            props = struct;
            props.richEditor.RichEditor = 'DivFigureEditor';
            props.richEditor.ModulePath = 'inspector_editors-lib/index';
            props.richEditor.BundleLocation = '../../datatools/inspector/editors/js/inspector_editors/release/bundle.mwBundle.inspector_editors-lib.js';
            props.richEditor.DebugDependencyIdx = 'inspector_editors-lib';
            props.richEditor.DebugDependencyValue = '/toolbox/matlab/datatools/inspector/editors/js/inspector_editors/inspector_editors-lib';
            props.InspectorID = this.InspectorID;

            % Get the actual UserRichEditorUI.  Make sure it has the accurate
            % InspectorID, and get the figure data and properties from it.
            richUI = this.Value.RichEditorUI;
            richUI.InspectorID = this.InspectorID; 
            props.figureData = richUI.getFigureData();
            props.Label = richUI.getPropertyLabel();
            props.editorSize = richUI.getEditorSize();
        end

        % Called to set the editor state.
        function setEditorState(this, state)
            % Save the current value from the state
            this.CurrentValue = state.currentValue;
        end
    end
end
