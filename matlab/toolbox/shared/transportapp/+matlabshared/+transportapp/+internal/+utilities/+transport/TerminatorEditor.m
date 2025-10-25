classdef TerminatorEditor < ...
        internal.matlab.editorconverters.EditorConverter & ...
        internal.matlab.editorconverters.PropertySheetCreator
    %TERMINATOREDITOR class sets up the rich text pop-up for the Terminator
    %property in the Property Inspector

    % Copyright 2021 The MathWorks, Inc.

    properties
        Terminator (1, 1) string
        DropDownValues
    end

    properties (Constant)
        Separator = ","
        FieldNames = ["ReadTerminator", "WriteTerminator"]
        RichTextEditorModule = "inspector_client/editors/PropertyFieldsEditor"
        TerminatorDataType = "internal.matlab.editorconverters.datatype.EditableStringEnumeration"
    end

    methods
        function setServerValue(obj, value, ~, ~)
            if isa(value, "matlabshared.transportapp.internal.utilities.transport.TerminatorClass")
                obj.Terminator = value.ReadTerminator.Value + obj.Separator + value.WriteTerminator.Value;
                obj.DropDownValues = value.ReadTerminator.EnumeratedValues;
            else
                obj.Terminator = value;
            end
        end

        function setClientValue(obj, value)
            % Set the value from the client. value is a cell array

            obj.Terminator = strjoin(value, obj.Separator);
        end

        function value = getServerValue(obj)
            import matlabshared.transportapp.internal.utilities.transport.TerminatorClass
            term = obj.Terminator;
            if contains(term, obj.Separator)
                term = strsplit(term, obj.Separator);
                value = TerminatorClass(term(1), term(2));
            else
                value = TerminatorClass(term, term);
            end
        end

        function value = getClientValue(obj)
            if contains(obj.Terminator, obj.Separator)
                value = obj.Terminator;
            else
                value = obj.Terminator + obj.Separator + obj.Terminator;
            end
        end

        function props = getEditorState(obj)
            % The editor state contains two properties, the number of
            % elements to break this array into, and the labels for the
            % positional fields
            props = struct;
            props.fields = obj.FieldNames;
            props.numElements = length(props.fields);
            props.classname = 'cell';  % needs to be set so the value isn't interpreted as numeric

            % Additionally, specify the rich editor module to popup
            props.richEditor = obj.RichTextEditorModule;

            propertySheet = obj.getPropertySheet("ReadTerminator", ...
                DataType = obj.TerminatorDataType, ...
                Renderer = internal.matlab.editorconverters.PropertySheetCreator.COMBO_BOX_EDITOR, ...
                Editable = true, ...
                Categories = obj.DropDownValues);
            propertySheet = [propertySheet, ...
                obj.getPropertySheet("WriteTerminator", ...
                DataType = obj.TerminatorDataType, ...
                Renderer = internal.matlab.editorconverters.PropertySheetCreator.COMBO_BOX_EDITOR, ...
                Editable = true, ...
                Categories = obj.DropDownValues)];

            props.propertySheet = propertySheet;
        end

        function setEditorState(~, ~)
        end
    end
end
