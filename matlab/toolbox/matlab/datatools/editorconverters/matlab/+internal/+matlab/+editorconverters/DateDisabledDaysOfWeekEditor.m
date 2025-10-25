classdef DateDisabledDaysOfWeekEditor < internal.matlab.editorconverters.EditorConverter
    %

    % Copyright 2018 The MathWorks, Inc.
    
    properties
        value;
    end
    
    methods
        
        % Called to set the client-side value
        function setClientValue(this, value)
            %handle cell array of numbers
            if iscell(value)
                try
                    this.value = cell2mat(value);
                catch
                    this.value = value;
                end
            else 
                this.value = value;
            end
            
            %handle cell array of chars
            if ischar(this.value) && ~isempty(this.value)
                this.value = string(this.value);
            end
        end
        
        % Called to set the server-side value
        function setServerValue(this, value, ~, ~)
            if isempty(value)
                this.value = [];
            elseif isa(value, 'internal.matlab.editorconverters.datatype.DateDisabledDaysOfWeek')
                this.value = value.getDisabledDaysOfWeek;
            else
                this.value = value;
            end
        end
        
        % Called to get the server-side representation of the value
        function value = getServerValue(this)
            value = internal.matlab.editorconverters.datatype.DateDisabledDaysOfWeek(this.value);
        end
        
        % Called to get the client-side representation of the value
        function varValue = getClientValue(this)
            varValue = this.value;
        end
        
        % Called to get the editor state, which contains properties
        % specific to the editor
        function props = getEditorState(~)
            props = struct;
            props.richEditor = 'rendererseditors/editors/DateCheckboxListEditor/DateCheckboxListEditor';
        end
        
        % Called to set the editor state.
        function setEditorState(~, ~)
        end
    end
    
end
