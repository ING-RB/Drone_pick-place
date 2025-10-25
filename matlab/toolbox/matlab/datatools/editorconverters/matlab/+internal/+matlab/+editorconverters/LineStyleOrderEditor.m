classdef LineStyleOrderEditor < ...
        internal.matlab.editorconverters.EditorConverter
    
    % This class is unsupported and might change or be removed withoutc
    % notice in a future version.
        
    % Copyright 2015 The MathWorks, Inc.
    
    properties
        lineStyleOrder;
    end
        
    methods
        function setServerValue(this, value, ~, ~)
            % Store the line style order value as is
            this.lineStyleOrder = value;
        end
        
        function setClientValue(this, value)
            if (iscell(value))
                this.lineStyleOrder = value;
            else
                % if not cell array, convert to cell array from comma
                % separated string
                lineStyles = strtrim(split(value, ','));
                this.lineStyleOrder = cellstr(lineStyles);
            end
        end
        
        function value = getServerValue(this)
            % Return the server value
            value = this.lineStyleOrder;
        end
        
        function value = getClientValue(this)
            % Returns the client value as a cell array
            if (~iscell(this.lineStyleOrder))
                % convert char array to cell array
                value = num2cell(this.lineStyleOrder, 2);
            else
                value = this.lineStyleOrder;
            end
        end
        
        function props = getEditorState(~)
            props = struct;
            props.richEditor = 'rendererseditors/editors/LineStyleOrderEditor';
        end
        
        function setEditorState(~, ~)
            % Line style order editor has no editor state
        end
    end
end