classdef DateTimeEditor < internal.matlab.editorconverters.EditorConverter
    % This class is unsupported and might change or be removed without
    % notice in a future version.
    
    % Copyright 2018-2020 The MathWorks, Inc.
    
    properties
        value;
    end
    
    methods
        % Called to set the client-side value
        function setClientValue(this, value)
            if ischar(value) && strcmp(value, "NaT")
                % char value from client side for NaT datetime: 'NaT'
                this.value = NaT;
            else
                % struct from client-side
                this.value = datetime(value.Year, value.Month, value.Day);
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
            if isnat(this.value)
                % The peernode controller doesn't handle NaT or NaN
                % We're going to check and replace NaT here  (datetime
                % NaN to represent Month, Day, Year value when date is NaT.
                value = "NaT";
            else
                % Convert datetime to a struct with 'year/month/day'
                matlabValue = this.value;
                value = struct('Month', [matlabValue(:).Month]',...
                    'Day', [matlabValue(:).Day]',...
                    'Year', [matlabValue(:).Year]');
            end
        end
        
        % Called to get the editor state.
        function props = getEditorState(~)
            props = [];
        end
        
        % Called to set the editor state.
        function setEditorState(~, ~)
        end
    end
end
