classdef InspectorObjectPropertyEditor
    %INSPECTOROBJECTPROPERTYEDITOR Creates an object property editor for
    %the given inspector and property at the provided location

    % Copyright 2020-2024 The MathWorks, Inc.

    properties(Constant)
        DIALOG_WIDTH = 640;
        DIALOG_HEIGHT = 480;
    end
    
    methods (Static)
        function [varargount] = editProperty(inspectorID, propertyName, mouseX, mouseY, editable)
            % Open the popup property editor for the given property name, at the
            % specified position

            arguments
                inspectorID (1,1) string
                propertyName (1,1) string
                mouseX (1,1) double
                mouseY (1,1) double
                editable (1,1) logical = true
            end
            import internal.matlab.inspector.editors.*;

            % Get the object to inspect
            m = internal.matlab.inspector.peer.InspectorFactory.getInspectorInstances;
            inspector = m(inspectorID);
            inspectedObject = inspector.Documents.ViewModel.DataModel.Data;

            % title will be the displayed property name (which may be different
            % from the original property name)
            title = propertyName;

            if isa(inspectedObject, "internal.matlab.inspector.InspectorProxyMixin")
                % If there is a display name set for the property, use it
                if isKey(inspectedObject.PropertyDisplayNameMap, propertyName)
                    title = inspectedObject.PropertyDisplayNameMap(propertyName);
                end

                % Use the original object, except for ProxyAddPropMixin classes,
                % because these have dynamic properties
                if ~isa(inspectedObject, "internal.matlab.inspector.ProxyAddPropMixin")
                    inspectedObject = inspectedObject.OriginalObjects;
                end
            end

            position = InspectorObjectPropertyEditor.getDialogPosition(...
                mouseX, ...
                mouseY, ...
                InspectorObjectPropertyEditor.DIALOG_WIDTH, ...
                InspectorObjectPropertyEditor.DIALOG_HEIGHT);

            pope = InspectorObjectPropertyEditor.editPropertyOfObject(inspectorID, propertyName, ...
                inspectedObject, title, position, editable);
            if nargout > 0
                varargount{1} = pope;
            end
        end
    end

    methods (Static, Hidden)
        function pope = editPropertyOfObject(inspectorID, propertyName, inspectedObject, name, position, editable)
            % Open the popup property editor for the given property name, at the
            % specified position

            arguments
                inspectorID (1,1) string
                propertyName (1,1) string
                inspectedObject
                name (1,1) string
                position (4,1) double
                editable (1,1) logical
            end

            import internal.matlab.inspector.editors.*;

            % Check if the Popup Variable Editor is already open for this
            % property and InspectorID
            existingPopup = findobjinternal(0, "Type", "figure", ...
                "Tag", propertyName, "UserData", inspectorID);
            if isempty(existingPopup)

                % Show the infinite grid in the popup Variable Editor if:
                % 1 - the property is not typed (so its type is 'any')
                % 2 - the current value of the property is empty
                % If we don't do this, then the popup VE is blank.  Use the
                % last object being inspected to check for the property,
                % since the Property Inspector always shows the last
                % object's properties.
                prop = findprop(inspectedObject(end), propertyName);
                infiniteGrid = false;
                if ~isempty(prop)
                    propType = internal.matlab.inspector.Utils.getPropDataType(prop);
                    % if the type is "any", string, or a numeric type, and the
                    % value is empty, show the infinite grid.  These types are
                    % chosen because the user can reasonably enter data starting
                    % with empty (as opposed to starting with an empty table,
                    % for example).
                    if ~isempty(propType) && any(strcmp(propType, ["any", "string", internal.matlab.variableeditor.NumericArrayDataModel.NumericTypes]))
                        currValue = inspectedObject.(propertyName);
                        if isempty(currValue)
                            infiniteGrid = true;
                        end
                    end
                end

                pope = PopupObjectPropertyEditor(...
                    'InspectedObject', inspectedObject, ...
                    'PropertyName', propertyName, ...
                    'Name', name, ...
                    'InspectorID', inspectorID, ...
                    'Position', position, ...
                    'Visible', true, ...
                    'InfiniteGrid', infiniteGrid, ...
                    'Editable', editable);
            else
                % The popup VE is already open -- bring to the front
                figure(existingPopup);
                pope = existingPopup;
            end
        end

        function position = getDialogPosition(mouseX, mouseY, width, height)
            arguments
                mouseX (1,1) double {mustBeNonnegative}
                mouseY (1,1) double {mustBeNonnegative}
                width  (1,1) double {mustBeNonnegative} = internal.matlab.inspector.editors.InspectorObjectPropertyEditor.DIALOG_WIDTH
                height (1,1) double {mustBeNonnegative} = internal.matlab.inspector.editors.InspectorObjectPropertyEditor.DIALOG_HEIGHT
            end
            % Compute the position based on the mouse position
            ss = get(0, 'ScreenSize');
            yPosition = ss(4) - mouseY - height;
            xPosition = mouseX;

            if xPosition + width > ss(3)
                xPosition = ss(3) - width;
            end
            
            xPosition = max(0, xPosition);
            
            if yPosition > ss(4)
                yPosition = ss(4);
            end
            
            yPosition = max(0, yPosition);
            
            position = [xPosition, ...
                yPosition, ...
                width, ...
                height];
        end
    end
end

