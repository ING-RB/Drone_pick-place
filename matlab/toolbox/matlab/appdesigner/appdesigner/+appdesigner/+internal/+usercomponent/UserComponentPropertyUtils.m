classdef (Sealed, Abstract) UserComponentPropertyUtils < handle

    methods(Static)
        function [className, defaultValue, inferredDefaultValue, renderer] = getInferredPropertyDetails(value, className)
            % GETINFERREDPROPERTYDETAILS Determines the inspector editor type &
            % other details such as className, value
            %
            % TODO: Refactor Design time controller of User components to
            % reuse the logic in this method for determining inspector editor for using
            % workflow.
            % well.

            % Copyright 2021-2023 The MathWorks, Inc.

            inferredDefaultValue = [];
            defaultValue = [];
            renderer = [];

            if isempty(value) && isempty(className)
                return
            end

            import internal.matlab.datatoolsservices.FormatDataUtils
            import appdesigner.internal.codegeneration.ComponentCodeGenerator
            import appdesigner.internal.usercomponent.UserComponentPropertyUtils

            if ~isempty(value) && ischar(value)
                try
                    value = eval(value);
                catch
                    % If the value fails to evaluate, ignore getting the
                    % inferred property details to avoid preventing the
                    % component to load. The value should be valid but
                    % there may be unknown edge cases where the value gets
                    % saved in an invalid state such as with g3023167.
                    return;
                end
            end

            if isempty(className)
                className = FormatDataUtils.getClassString(value, false, true);
            end

            validation = struct;
            validation.dimensions = [];
            validation.class = className;
            validation.validators = [];

            H = matlab.internal.validation.ValidationHelper(validation);

            [isCatOrEnum, ~] = ...
                internal.matlab.editorconverters.ComboBoxEditor.isCategoricalOrEnum(...
                className, className, validateClass(H, value));

            isPropertySupported = UserComponentPropertyUtils.doesPropertyHaveValidEditor(isCatOrEnum, className, validateClass(H, value));

            if ~isPropertySupported
                return;
            end

            if ~isempty(value)
                inferredDefaultValue = UserComponentPropertyUtils.inferDefaultValue(isCatOrEnum, className, validateClass(H, value));
            end

            renderer = UserComponentPropertyUtils.getInspectorRenderer(isCatOrEnum, className, validateClass(H, value));
            defaultValue = ComponentCodeGenerator.propertyValueToString(className, inferredDefaultValue);
        end

        function renderer = getInspectorRenderer(isCatOrEnum, className, value)
            import internal.matlab.datatoolsservices.WidgetRegistry
            import matlab.ui.internal.DesignTimeWebUIContainerController

            widgetRegistry = WidgetRegistry.getInstance;

            multiLineEditorDataTypes = DesignTimeWebUIContainerController.getMultiLineEditorSupportedDataTypes();
            multiLineEditorType = 'internal.matlab.editorconverters.datatype.MultipleItemsValue';

            if isCatOrEnum
                renderer = widgetRegistry.getWidgets('internal.matlab.inspector.peer.PeerInspectorViewModel', 'categorical');
            elseif any(strcmp(multiLineEditorDataTypes, className))
                renderer = widgetRegistry.getWidgets('internal.matlab.inspector.peer.PeerInspectorViewModel', multiLineEditorType);
            else
                renderer = widgetRegistry.getWidgets('internal.matlab.inspector.peer.PeerInspectorViewModel', className);
            end

            % Populate the inplace editor properties for an editor. For example
            % dropdown menu items for a combobox editor.
            if (~isempty(renderer.EditorConverter))
                converter = eval(renderer.EditorConverter);
                converter.setServerValue(value, className);
                renderer.InPlaceEditorProperties = converter.getEditorState;
            end
        end

        function inferredDefaultValue = inferDefaultValue(isCatOrEnum, className, value)
            if isnumeric(value)
                inferredDefaultValue = appdesservices.internal.util.convertClientNumberToServerNumber(value);
            elseif isCatOrEnum
                inferredDefaultValue = char(value);
            elseif isequal(className, 'char')
                inferredDefaultValue = convertStringsToChars(value);
            else
                inferredDefaultValue = value;
            end
        end

        function isPropertySupported = doesPropertyHaveValidEditor(isCatOrEnum, className, value)
            import matlab.ui.internal.DesignTimeWebUIContainerController

            isPropertySupported = true;

            % If a property is of type Enum, then show the property only if
            % it is assigned with a non empty default value. If an empty value/no value is
            % assigned to an Enum property, it will not be shown in inspector.
            if isCatOrEnum && isempty(value)
                isPropertySupported = false;
            end

            supportedDataTypes = DesignTimeWebUIContainerController.getInspectorSupportedDataTypes();
            if ~isCatOrEnum && ~any(strcmp(supportedDataTypes, className))
                isPropertySupported = false;
            end

            if ~isempty(value)
                % Don't show the multi dimensional cell arrays. Only show n * 1 and 1 * n cell arrays.
                % App Designer doesn't have proper property editor to edit multi-dimensional cell arrays.
                if (strcmp(className, 'cell') && ~isvector(value))
                    isPropertySupported = false;
                end

                % Don't show string arrays.
                % App Designer doesn't have server side code gen logic to accomodate string arrays.
                if (strcmp(className, 'string') && ~isscalar(value))
                    isPropertySupported = false;
                end

                % Don't show n * 1 char arrays.
                % App Designer doesn't have server side code gen logic to accomodate n * 1 char arrays.
                if (strcmp(className, 'char') && ~isrow(value))
                    isPropertySupported = false;
                end
            end
        end

    end
end
