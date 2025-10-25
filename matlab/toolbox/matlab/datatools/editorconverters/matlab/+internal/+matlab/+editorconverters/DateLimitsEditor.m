classdef DateLimitsEditor < internal.matlab.editorconverters.EditorConverter
    % This class is unsupported and might change or be removed without
    % notice in a future version.
    
    % Copyright 2018 The MathWorks, Inc.
    
    properties
        value;
    end
    
    properties (Constant)
        START_LABEL = "Start";
        END_LABEL = "End";
    end
    
    methods
        % Called to set the client-side value
        function setClientValue(this, value)
            try
                yearArray = value.Year;
                monthArray = value.Month;
                dayArray = value.Day;
                
                %if the size is not equal, the value sent back is not valid
                if isequal(size(yearArray), [2,1]) || ...
                        isequal(size(monthArray), [2,1]) || ...
                        isequal(size(dayArray), [2,1])
                    startValue = this.convertDateTime(yearArray, monthArray, dayArray, 1);
                    endValue = this.convertDateTime(yearArray, monthArray, dayArray, 2);                 
                    this.value = [startValue endValue];
                else
                    this.value = NaT;
                end
                
            catch
                % in case that the client in place editor text field send
                % back some invalid value;
                this.value = NaT;
            end
        end
        
        % Called to get the server-side representation of the value
        function value = getServerValue(this)
            value = internal.matlab.editorconverters.datatype.DateLimits(this.value);
        end
        
        
        % Called to set the server-side value
        function setServerValue(this, value, ~, ~)
            if isempty(value)
                this.value = [datetime('01-Jan-0000') datetime('31-Dec-9999')];
            elseif isa(value, 'internal.matlab.editorconverters.datatype.DateLimits')
                this.value = value.getLimits;
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
        function props = getEditorState(this)
            props = struct;
            props.richEditor = 'inspector_client/editors/DatePickerRichEditor';
            props.fields = [this.START_LABEL, this.END_LABEL];
            props.numElements = 2;
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
