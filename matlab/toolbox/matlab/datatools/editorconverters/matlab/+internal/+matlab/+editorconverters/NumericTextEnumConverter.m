classdef NumericTextEnumConverter < internal.matlab.editorconverters.EditorConverter
    
    % This class is unsupported and might change or be removed without
    % notice in a future version.
       
    % Copyright 2023 The MathWorks, Inc.

    properties
        Value;
    end
    
    methods
        
        % Called to set the server-side value
        function setServerValue(this, value, ~, ~)
            this.Value = value;
        end
        
        % Called to set the client-side value
        function setClientValue(this, value)
            this.Value = value;
        end
        
        % Called to get the server-side representation of the value
        function value = getServerValue(this)
            value = this.Value;
            numericVal = str2double(value);
            if ~isnan(numericVal)
                % Use the numeric value if it converts to one
                value = numericVal;
            end
        end
        
        % Called to get the client-side representation of the value
        function varValue = getClientValue(this)
            varValue = this.Value;
        end
        
        % Called to get the editor state, which contains properties
        % specific to the editor
        function props = getEditorState(~)
            props = [];
        end
        
        % Called to set the editor state.  
        function setEditorState(~, ~)
        end
    end
end
