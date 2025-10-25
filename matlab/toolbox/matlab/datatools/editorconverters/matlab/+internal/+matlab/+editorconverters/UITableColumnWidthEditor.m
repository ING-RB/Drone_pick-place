classdef UITableColumnWidthEditor < internal.matlab.editorconverters.EditorConverter
    % This class is unsupported and might change or be removed without
    % notice in a future version.
    
    % Copyright 2018-2020 The MathWorks, Inc.
    
    properties
        value;
    end
    
    methods
        % Called to set the client-side value
        function setClientValue(this, value)
            this.value = value;
            if ischar(value)
                % Try to eval the char, it could be something like '[10, 20]'
                try
                    this.value = eval(value);
                catch
                end
            end
            
            % Column width needs to be a row vector cell array, so do the
            % appropriate conversion
            if isnumeric(this.value)
                this.value = num2cell(this.value);
            elseif iscell(this.value)
                this.value = cellfun(@(x) {this.convert(x)}, this.value);
            end
            
            if iscolumn(this.value)
                this.value = this.value';
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
            value = string(this.value);
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
        function value = convert(~, element)
            try
                value = evalin('base', element);
            catch
                value = element;
            end
        end
    end
end
