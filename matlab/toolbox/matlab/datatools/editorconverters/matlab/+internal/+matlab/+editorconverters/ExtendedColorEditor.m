classdef ExtendedColorEditor < internal.matlab.editorconverters.EditorConverter
    
    % This class is unsupported and might change or be removed without
    % notice in a future version.

    % Copyright 2018-2019 The MathWorks, Inc.
    
    properties
        value;
    end
    
    methods
        % Called to set the server-side value
        function setServerValue(this, value, ~, ~)
            this.value = value;
        end
        
        % Called to set the client-side value
        function setClientValue(this, value)
            colorArray = string(value).split(";");
            containsNaN = false;
            
            for i =1:colorArray.length
                currValue = this.convertToVector(colorArray(i));
                if isnan(currValue)
                    containsNaN = true;
                    break;
                end
                if i==1
                    this.value = currValue;
                else
                    this.value = [this.value; currValue];
                end
            end
            
            if containsNaN
                this.value = this.convertToCell(colorArray);
            end
        end
        
        % Called to get the server-side representation of the value
        function value = getServerValue(this)
            value = this.value;
        end
        
        % Called to get the client-side representation of the value
        function value = getClientValue(this)
            value = this.value;
        end
        
        % Called to get the editor state, which contains properties
        % specific to the editor
        function props = getEditorState(~)
            props = [];
        end
        
        % Called to set the editor state, which are properties specific to
        % the editor
        function setEditorState(~, ~)
        end
        
    end
    
    methods(Access=private)
        function value = convertToVector(~, input)
            stringArray = input.split(",");
            value = [];
            for i = 1:stringArray.length
                value(i) = str2double(stringArray(i)); %#ok<*AGROW>
            end
        end
        
        function value = convertToCell(~, input)
            stringArray = input.split(",");
            value = {};
            for i = 1:stringArray.length
                value{i} = stringArray{i};
            end
        end        
    end
end
