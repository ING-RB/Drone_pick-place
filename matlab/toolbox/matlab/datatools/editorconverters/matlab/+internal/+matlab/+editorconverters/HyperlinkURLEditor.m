classdef HyperlinkURLEditor < internal.matlab.editorconverters.EditorConverter
    % This class is unsupported and might change or be removed without
    % notice in a future version.
    
    % HyperlinkURL EditorConverter class. This class acts as conduit
    % between server and client to get and set value for URL property
    % on Hyperlink
    
    % Copyright 2020 The MathWorks, Inc.
    
 properties
        value;
        dataType;
    end
    
    methods
        
        % Called to set the server-side value
        function setServerValue(this, value, dataType, ~)
            this.value = value;
            this.dataType = dataType;
        end
        
        % Called to set the client-side value
        function setClientValue(this, value)
            this.value = value;
        end
        
        % Called to get the server-side representation of the value
        function value = getServerValue(this)
            value = this.value;
        end
        
        % Called to get the client-side representation of the value
        function varValue = getClientValue(this)
            varValue = this.value;      
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
end

