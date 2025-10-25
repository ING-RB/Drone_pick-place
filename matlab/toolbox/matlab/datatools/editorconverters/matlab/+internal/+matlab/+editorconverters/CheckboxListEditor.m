classdef CheckboxListEditor < internal.matlab.editorconverters.EditorConverter
    % EditorConverter for the checkbox list editor
    
    % Copyright 2020-2021 The MathWorks, Inc.
    
    properties
        Value;
        PropertyName string = strings(0);
    end
    
    methods
        
        % Called to set the client-side value.  There are two ways the
        % client-side value can be represented, depending on if the user edits
        % from the inline text field, or if they edit from the checkbox list.
        % Both ways of editing come to this EditorConverter.
        %
        % 1) Editing through the Checkbox List Rich Editor:
        % If there are multiple values, it will be a numeric array contained in
        % a char, for example:  '[3;4]', otherwise it will be a scalar numeric
        % value as a char, like: '4'.  Empty will be '[]'
        % 
        % 2) Editing through the inline text field:
        % If there are multiple values, it will be comma separated text, like
        % 'C,D'.  A single value will be just the text, like 'C'.  Empty will be
        % just ''.
        function setClientValue(this, value)
            % Char may contain numbers, try to convert
            val = [];
            if ischar(value)
                % Need the str2num eval'ing instead of using str2double
                val = str2num(value); %#ok<ST2NM>
                if isempty(val) && ~isempty(value)
                    val = value;
                    if contains(val, ',')
                        % The text could be comma separated values
                        val = strsplit(val, ',');
                    end
                end
            end
            
            if isnumeric(val)
                % Get the text values from the item indices (val)
                this.Value = this.Value.Items(val);
            else
                this.Value = val;
            end
        end
        
        % Called to set the server-side value.  The value is stored as a
        % CheckboxList type.
        function setServerValue(this, value, ~, propName)
            if isempty(value)
                this.Value = [];
            elseif ~isa(value, "internal.matlab.editorconverters.datatype.CheckboxList")
                this.Value = internal.matlab.editorconverters.datatype.CheckboxList(value);
            else
                this.Value = value;
            end
            
            this.PropertyName = propName;
        end
        
        % Called to get the server-side representation of the value.  Returns a
        % CheckboxList data type.
        function value = getServerValue(this)
            value = internal.matlab.editorconverters.datatype.CheckboxList(this.Value);
        end
        
        % Called to get the client-side representation of the value, which is
        % the numeric indices of the selected items.  For example, if the items
        % are {'A', 'B', 'C'}, and the selection is {'B', 'C'}, returns [2,3]
        function varValue = getClientValue(this)
            if iscell(this.Value.Value)
                varValue = cellfun(@(x) find(strcmp(x, this.Value.Items)), this.Value.Value);
            else
                varValue = find(strcmp(this.Value.Value, this.Value.Items));
            end
        end
        
        % Called to get the editor state, which contains properties
        % specific to the editor
        function props = getEditorState(this)
            props = struct;
            props.richEditor = "rendererseditors/editors/CheckboxListEditor/CheckboxListEditor";
            if isa(this.Value, "internal.matlab.editorconverters.datatype.CheckboxList")
                % The CheckboxListEditor works with numeric values, convert the
                % text value to its numeric values in the Items
                if iscell(this.Value.Value)
                    b = cellfun(@(x) strcmp(x, this.Value.Items), this.Value.Value, 'UniformOutput', false);
                    numericVals = cellfun(@(x) find(x), b);
                else
                    numericVals = find(strcmp(this.Value.Value, this.Value.Items));
                end
                
                % Send the values, row names, and label to the client as part of
                % the editor states
                props.values = numericVals;
                props.rowNames = this.Value.Items;
                if ~iscell(props.rowNames)
                    props.rowNames = {props.rowNames};
                end
                props.label = this.Value.Label;
                props.immediateApply = this.Value.ImmediateApply;
            end
            
            props.propertyName = this.PropertyName;
        end
        
        % Called to set the editor state.
        function setEditorState(~, ~)
        end
    end
end
