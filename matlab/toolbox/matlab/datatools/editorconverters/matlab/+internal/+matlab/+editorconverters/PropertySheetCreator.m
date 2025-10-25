classdef PropertySheetCreator < handle
    
    % This class is unsupported and might change or be removed without
    % notice in a future version.
    
    % This class can be mixed into EditorConverter classes, and it provides a
    % method to get a propertySheet struct with the specified values.
    
    % Copyright 2021 The MathWorks, Inc.
    
    properties(Constant)
        TEXT_BOX_EDITOR = "rendererseditors/editors/TextBoxEditor";
        COMBO_BOX_EDITOR = "rendererseditors/editors/ComboBoxEditor";
    end
    
    methods
        function p = getPropertySheet(~, name, options)
            arguments
                ~;
                
                % Property Name
                name string;
                
                % Property DisplayName.  If not specified, the Name value will
                % be used.
                options.DisplayName string = strings(0);
                
                % Property Data Type.  Default to text (char) if the value is
                % not specified.
                options.DataType string = "char";
                
                % Renderer to use.  Default to the Text Box editor if the value
                % is not specified.
                options.Renderer string = internal.matlab.editorconverters.PropertySheetCreator.TEXT_BOX_EDITOR;
                
                % In-place editor to use.  Default to the Renderer if the value
                % is not specified.
                options.InPlaceEditor string = strings(0);
                
                % Whether the value is editable or not.  Default to true.
                options.Editable(1,1) logical = true;
                
                % Categories to display in a dropdown editor, if the Renderer
                % and InPlaceEditor are the ComboBoxEditor.
                options.Categories string = strings(0);
            end
            
            p = struct;
            p.name = name;
            
            if isempty(options.DisplayName)
                p.displayName = name;
            else
                p.displayName = options.DisplayName;
            end
            
            if isempty(options.InPlaceEditor)
                p.inPlaceEditor = options.Renderer;
            else
                p.inPlaceEditor = options.InPlaceEditor;
            end
            
            p.dataType = options.DataType;
            p.renderer = options.Renderer;
            p.editable = options.Editable;
            
            if ~isempty(options.Categories)
                % Setup the richEditorProperties rich editor for dropdowns
                p.richEditorProperties = struct;
                p.richEditorProperties.categories = options.Categories;
                
                if endsWith(options.DataType, "StringEnumeration")
                    if options.DataType == "internal.matlab.editorconverters.datatype.EditableStringEnumeration"
                        p.richEditorProperties.clientValidation = false;
                    else
                        p.richEditorProperties.clientValidation = true;
                    end
                    
                    p.richEditorProperties.isProtected = true;
                    p.richEditorProperties.showUndefined = false;
                elseif options.DataType == "categorical"
                    p.richEditorProperties.isProtected = false;
                    p.richEditorProperties.showUndefined = true;
                else
                    p.richEditorProperties.isProtected = false;
                    p.richEditorProperties.showUndefined = false;
                end
            end
        end
    end
end