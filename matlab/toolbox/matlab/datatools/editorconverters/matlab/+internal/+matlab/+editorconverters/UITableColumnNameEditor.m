classdef UITableColumnNameEditor < internal.matlab.editorconverters.EditorConverter
    % This class is unsupported and might change or be removed without
    % notice in a future version.
    
    % Copyright 2018 The MathWorks, Inc.
    
    properties
        value;
    end
    
    methods
        % Called to set the client-side value
        function setClientValue(this, value)
            % if the value is 'numbered', return
            if ischar(value) && strcmp(value,'numbered')
                this.value = value;
            else
                this.value = cell(value)';
                
                if isempty(this.value)
                    this.value = {};
                end
            end
        end
        
        % Called to get the server-side representation of the value
        function value = getServerValue(this)
            value = internal.matlab.editorconverters.datatype.UITableColumnName(this.value);
        end
        
        
        % Called to set the server-side value
        function setServerValue(this, value, ~, ~)
            if isempty(value)
                this.value = '';
            elseif isa(value, 'internal.matlab.editorconverters.datatype.UITableColumnName')
                this.value = value.getName;
            else
                this.value = value;
            end
        end
        
        % Called to get the client-side representation of the value
        function value = getClientValue(this)
            if isempty(this.value)
                value = '';
            else
                value = string(this.value);
            end
        end
        
        % Called to get the editor state.  Unused.
        function props = getEditorState(~)
            props = struct;
            props.richEditor = 'rendererseditors/editors/UITableColumnEditor/UITableColumnEditor';
            props.richEditorDependencies = {'ColumnName', 'ColumnWidth', 'ColumnEditable'};
        end
        
        % Called to set the editor state.
        function setEditorState(~, ~)
        end
    end
end
