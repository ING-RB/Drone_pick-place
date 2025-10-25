classdef NumericOrStringEditor < ...
        internal.matlab.editorconverters.EditorConverter
    
    % This class is unsupported and might change or be removed withoutc
    % notice in a future version.
        
    % Copyright 2015-2017 The MathWorks, Inc.
    
    properties
        value;
        propName;
    end
        
    methods
        function setServerValue(this, value, ~, propName)
            % Store the value as is
            this.value = value;
            this.propName = propName;
        end
        
        function setClientValue(this, value)
            % Store the value as is
            this.value = value;
        end
        
        function value = getServerValue(this)
            % Return the server value
            value = this.value;
            try
                c = eval(this.value);
                if iscell(c) 
                    if isscalar(c)
                        % treat scalar cell arrays as chars
                        value = c{1};
                    else
                        value = c;
                    end
                end
            catch
            end
        end
        
        function value = getClientValue(this)
            if ischar(this.value)
                value = this.value;
            elseif iscellstr(this.value) && length(this.value) <= 1
                if isempty(this.value)
                    value = '';
                else
                    value = this.value{1};
                end
            else
                fdu = internal.matlab.datatoolsservices.FormatDataUtils;
                value = fdu.formatSingleDataForMixedView(this.value);
            end
        end
        
        function props = getEditorState(this)
            props = struct;
            props.editValue = this.value;
            if any(this.propName == ...
                ["String", "Title", "XLabel", "YLabel", "DataLabel", "CoordinateLabel"])
                % These properties are always text (they're not lists of
                % numbers).  Force input/output to be 'cell', which handles
                % scalar text or cell array text.
                props.outputType = 'cell';
                props.inputType = 'cell';
            end
        end
        
        function setEditorState(~, ~)
        end
    end
end
