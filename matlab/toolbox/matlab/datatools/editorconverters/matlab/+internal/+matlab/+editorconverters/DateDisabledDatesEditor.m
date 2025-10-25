classdef DateDisabledDatesEditor < internal.matlab.editorconverters.EditorConverter
    % This class is unsupported and might change or be removed without
    % notice in a future version.
    
    % Copyright 2018-2023 The MathWorks, Inc.
    
    properties
        value;
    end
    
    
    methods
        % Called to set the client-side value
        function setClientValue(this, value)
            if(isempty(value))
                this.value = datetime.empty();
            else
                try
                    yearArray = value.Year;
                    monthArray = value.Month;
                    dayArray = value.Day;

                    this.value = datetime.empty();

                    for i = 1:size(yearArray,1)
                        currDate = this.convertDateTime(yearArray, monthArray, dayArray, i);
                        this.value = [this.value currDate];
                    end
                    
                catch
                    % in case that the client in place editor text field send
                    % back some invalid value;
                    this.value = value;
                end
            end
        end
        
        % Called to get the server-side representation of the value
        function value = getServerValue(this)
            value = internal.matlab.editorconverters.datatype.DateDisabledDates(this.value);
        end
        
        
        % Called to set the server-side value
        function setServerValue(this, value, ~, ~)
            if isempty(value)
                this.value = struct('Month',[],'Day',[], 'Year',[]);
            elseif isa(value, 'internal.matlab.editorconverters.datatype.DateDisabledDates')
                this.value = value.getDisabledDates;
            else
                this.value = value;
            end
        end
        
        % Called to get the client-side representation of the value
        function value = getClientValue(this)
            % Convert datetime to a struct with 'year/month/day'
            matlabValue = this.value;
            value = struct('Month', [matlabValue(:).Month]',...
                'Day', [matlabValue(:).Day]',...
                'Year', [matlabValue(:).Year]');
        end
        
        % Called to get the editor state.
        function props = getEditorState(~)
            props = struct;
            props.richEditor = 'rendererseditors/editors/DateTableEditor/DateTableEditor';
            % Set editable to false to disable the inplace textbox editor
            % Set editable to true to enable the richeditor
            props.editable = false;
            props.richEditable = true;            
        end
        
        % Called to set the editor state.
        function setEditorState(~, ~)
        end
    end
    
    methods(Access=private)
        function value = convertDateTime(~, yearArray, monthArray, dayArray, index)
            if isempty(yearArray(index)) || isempty(monthArray(index)) || isempty(dayArray(index))
                value = NaT;
            else
                value = datetime([double(yearArray(index)), double(monthArray(index)), double(dayArray(index))]);
            end
        end
    end
end
