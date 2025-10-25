classdef DateDisplayFormatEditor < internal.matlab.editorconverters.EditorConverter
    %

    % Copyright 2018 The MathWorks, Inc.
    
    properties
        value;
    end
    
    methods
        
        % Called to set the client-side value
        function setClientValue(this, value)
            this.value = value;
        end
        
        % Called to set the server-side value
        function setServerValue(this, value, ~, ~)
            if isempty(value)
                s = settings;
                this.value = s.matlab.datetime.DefaultDateFormat.ActiveValue;
            elseif isa(value, 'internal.matlab.editorconverters.datatype.DateDisplayFormat')
                this.value = value.getDisplayFormat;
            else
                this.value = value;
            end
        end
        
        % Called to get the server-side representation of the value
        function value = getServerValue(this)
            value = internal.matlab.editorconverters.datatype.DateDisplayFormat(this.value);
        end
        
        % Called to get the client-side representation of the value
        function varValue = getClientValue(this)
            varValue = this.value;
        end
        
        % Called to get the editor state, which contains properties
        % specific to the editor
        function props = getEditorState(this)
            props = struct;
            props.categories = this.getCategories;
            props.isProtected = false;
            props.showUndefined = false;
            props.clientValidation = true;
        end
        
        % Called to set the editor state.
        function setEditorState(~, ~)
        end
    end
    
    methods(Access=private)
        function dateFormats = getCategories(~)
            %these are the same settings as are found in the Preferences windows
            %the code is being repeated here because the Preferences window logic is in Java
            s =settings;
            displayLanguage = s.matlab.datetime.DisplayLocale.ActiveValue;
            
            switch displayLanguage
                case 'en_US'
                    dateFormats = strings(5, 1);
                    dateFormats(1) = "dd-MMM-uuuu";
                    dateFormats(2) = "uuuu-MMM-dd";
                    dateFormats(3) = "uuuu-MM-dd";
                    dateFormats(4) = "dd/MMM/uuuu";
                    dateFormats(5) = "dd.MM.uuuu";
                case {"zh_CN", "ja_JP"}
                    dateFormats = strings(4, 1);
                    dateFormats(1) = strcat('uuuu',char(24180),' M',char(26376),' d', char(26085));
                    dateFormats(2) = strcat('uuuu',char(24180),' MM',char(26376),' dd', char(26085));
                    dateFormats(3) = "uuuu/MM/dd";
                    dateFormats(4) = "uuuu-MM-dd";
                case "ko_KR"
                    dateFormats = strings(4, 1);
                    dateFormats(1) = strcat('uuuu',char(45380),' M',char(50900),' d', char(51068));
                    dateFormats(2) = strcat('uuuu',char(45380),' M',char(50900),' dd', char(51068));
                    dateFormats(3) = "uuuu/MM/dd";
                    dateFormats(4) = "uuuu-MM-dd";
                otherwise
                    dateFormats = strings(5, 1);
                    dateFormats(1) = "dd-MMM-uuuu";
                    dateFormats(2) = "uuuu-MMM-dd";
                    dateFormats(3) = "uuuu-MM-dd";
                    dateFormats(4) = "dd/MMM/uuuu";
                    dateFormats(5) = "dd.MM.uuuu";
            end
            
        end
    end
    
end
