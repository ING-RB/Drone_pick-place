classdef UITableColumnEditableEditor < internal.matlab.editorconverters.EditorConverter
    % This class is unsupported and might change or be removed without
    % notice in a future version.
    
    % Copyright 2018-2020 The MathWorks, Inc.
    
    properties
        value;
    end
    
    methods
        % Called to set the client-side value
        function setClientValue(this, value)
            if (size(value,1)==1 && size(value,2)==1 && strcmp(value(1,1), '')) || isempty(value)
                this.value = logical.empty();
            elseif ischar(value)
                this.value = eval(value);
                if iscolumn(this.value)
                    this.value = this.value';
                end
            else
                try
                    this.value = cell2mat(cellfun(@(x) {this.convertToLogical(x)}, cell(value)'));
                catch
                    this.value = cell(value)';
                end
            end
        end
        
        % Called to get the server-side representation of the value
        function value = getServerValue(this)
            value = this.value;
        end
        
        % Called to set the server-side value
        function setServerValue(this, value, ~, ~)
            this.value = value;
        end
        
        % Called to get the client-side representation of the value
        function value = getClientValue(this)
            value = this.value;
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
    
    methods(Access=private)
        function value = convertToLogical(~, element)
            if isa(element, 'logical')
                value = element;
            else
                try
                    value = logical(evalin('base', element));
                catch
                    value = element;
                end
            end
        end
    end
end
