classdef StringEnumerationEditor < ...
        internal.matlab.editorconverters.EditorConverter

    % This class is unsupported and might change or be removed without
    % notice in a future version.

    % Copyright 2018-2021 The MathWorks, Inc.

    properties
        value;
        propCategories;
    end

    methods

        % Called to set the server-side value
        function setServerValue(this, value, ~, ~)
            this.value = value;
        end

        % Called to set the client-side value
        function setClientValue(this, value)
            this.value = value;
        end

        % Called to get the server-side representation of the value
        function value = getServerValue(this)
            if startsWith(this.value, "'") && endsWith(this.value, "'")
                value = this.value;
            else
                value = ['''' this.value ''''];
            end
        end

        % Called to get the client-side representation of the value
        function varValue = getClientValue(this)
            % Remove quotes from value if scalar (otherwise its a
            % summary value like 1x5 categorical)
            if isa(this.value, 'internal.matlab.editorconverters.datatype.StringEnumeration')
                varValue = this.value.Value;
            else
                varValue = this.value;
            end

            if isscalar(varValue) || ischar(varValue)
                if ~ischar(varValue)
                    varValue = char(varValue);
                end

                varValue = strrep(varValue, '''', '');
            end
        end

        % Called to get the editor state, which contains properties
        % specific to the editor
        function props = getEditorState(this)
            props = struct;
            
            if ~isempty(this.value)
                try
                props.categories = this.value.EnumeratedValues;
                catch
                    % Try to get the enumeration values directly
                    props.categories = cellstr(enumeration(class(this.value)));
                end
                if ~iscell(props.categories)
                    props.categories = {props.categories};
                end
            end
            props.isProtected = true;
            props.showUndefined = false;
            
            if isa(this.value, "internal.matlab.editorconverters.datatype.ProtectedStringEnumeration")
                props.clientValidation = true;
            else
                props.clientValidation = false;
            end
        end
        
        % Called to set the editor state.
        function setEditorState(~, ~)
        end
    end
end
