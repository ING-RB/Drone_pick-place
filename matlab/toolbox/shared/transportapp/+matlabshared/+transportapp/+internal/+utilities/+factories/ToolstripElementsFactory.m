classdef ToolstripElementsFactory
    %TOOLSTRIPELEMENTSFACTORY is a factory class containing static methods
    %that helps construct the toolstrip section View. It provides API's for
    %creating toolstrip UI Elements like push-buttons, drop-down lists, etc.

    % Copyright 2020 The MathWorks, Inc.

    methods
        %% Private Constructor
        function obj = ToolstripElementsFactory(varargin)
        end
    end

    %% Factory Methods
    methods (Static)
        function createAndAddColumn(toolstripSection, toolstripColumn, elements)
            % Create a toolstrip column and add some toolstrip elements to
            % the column.
            % toolstripSection - The handle to the toolstrip
            % alignment - The alignment of UI Elements in the column -
            % left, center, or right.
            % toolstripColumn - The utilities.forms.ToolstripColumn type
            % that contains information about the horizontal alignment and
            % width of the toolstrip column
            % elements - The array of toolstrip UI Elements to be added to
            % the toolstrip column.

            arguments
                toolstripSection (1, 1) matlab.ui.internal.toolstrip.Section
                toolstripColumn (1, 1) matlabshared.transportapp.internal.utilities.forms.ToolstripColumn
                elements (1, :)
            end
            column = toolstripSection.addColumn("HorizontalAlignment", toolstripColumn.HorizontalAlignment, ...
                "width", toolstripColumn.Width);

            for elem = elements
                column.add(elem);
            end
        end

        function element = createPushButton(props)
            % Create a toolstrip push-button.
            % props - The list of property Names and Values combination
            % that are applied to the push-button.

            arguments
                props struct
            end

            element = matlab.ui.internal.toolstrip.Button;
            matlabshared.transportapp.internal.utilities.factories.ToolstripElementsFactory.setProperties(element, props);
        end

        function element = createDropDown(dropDownList, props)
            % Create a toolstrip drop-down list.
            % dropDownList - The list of items to show up under the drop
            % down when clicked.
            % props - The list of property Names and Values combination
            % that are applied to the drop-down.

            arguments
                dropDownList (1, :) string
                props struct
            end

            element = matlab.ui.internal.toolstrip.DropDown;

            for listItem = dropDownList
                element.addItem(listItem);
            end
            matlabshared.transportapp.internal.utilities.factories.ToolstripElementsFactory.setProperties(element, props);
        end

        function element = createLabel(props)
            % Create a toolstrip label.
            % % props - The list of property Names and Values combination
            % that are applied to the label.

            arguments
                props struct
            end

            element = matlab.ui.internal.toolstrip.Label;
            matlabshared.transportapp.internal.utilities.factories.ToolstripElementsFactory.setProperties(element, props);
        end

        function element = createButtonGroup(props)
            % Create a toolstrip button group - used for creating radio
            % buttons.
            % props - The list of property Names and Values combination
            % that are applied to the button group.

            arguments
                props struct
            end

            element = matlab.ui.internal.toolstrip.ButtonGroup;
            matlabshared.transportapp.internal.utilities.factories.ToolstripElementsFactory.setProperties(element, props);
        end

        function element = createRadioButton(buttonGroup, props)
            % Create and add a radio button to a button-group in the
            % toolstrip.
            % buttonGroup - The button group to which is to contain the
            % radio button
            % props - The list of property Names and Values combination
            % that are applied to the radio button.
            arguments
                buttonGroup matlab.ui.internal.toolstrip.ButtonGroup
                props struct
            end

            element = matlab.ui.internal.toolstrip.RadioButton(buttonGroup);
            matlabshared.transportapp.internal.utilities.factories.ToolstripElementsFactory.setProperties(element, props);
        end

        function element = createEditField(props)
            % Create a toolstrip Edit Field.
            % props - The list of property Names and Values combination
            % that are applied to the edit field.

            arguments
                props struct
            end

            element = matlab.ui.internal.toolstrip.EditField();
            matlabshared.transportapp.internal.utilities.factories.ToolstripElementsFactory.setProperties(element, props);
        end

        function element = createDropDownButton(props)
            % Create a toolstrip Drop Down Button.
            % props - The list of property Names and Values combination
            % that are applied to the drop-down button.

            arguments
                props struct
            end

            element = matlab.ui.internal.toolstrip.DropDownButton();
            matlabshared.transportapp.internal.utilities.factories.ToolstripElementsFactory.setProperties(element, props);
        end

        function element = createListItem(props)
            % Create a list item to be added to a popup list
            % props - The list of property Names and Values combination
            % that are applied to the list item.

            arguments
                props struct
            end

            element = matlab.ui.internal.toolstrip.ListItem;
            matlabshared.transportapp.internal.utilities.factories.ToolstripElementsFactory.setProperties(element, props);
        end

        function element = createPopupList(listItems, props)
            % Create a toolstrip popup list for DropDown Buttons.
            % listItems - An array of matlab.ui.internal.toolstrip.ListItem
            % to be added to the popup list.
            % props - The list of property Names and Values combination
            % that are applied to the popup list.

            arguments
                listItems (1, :) matlab.ui.internal.toolstrip.ListItem
                props struct
            end

            element = matlab.ui.internal.toolstrip.PopupList;
            for item = listItems
                element.add(item);
            end

            matlabshared.transportapp.internal.utilities.factories.ToolstripElementsFactory.setProperties(element, props);
        end

        function element = createEmptyWidget()
            % Create an empty toolstrip widget (for spacing purposes).

            element = matlab.ui.internal.toolstrip.EmptyControl();
        end
    end

    %% Helper functions
    methods (Access = private, Static)
        function setProperties(element, props)
            % Assign property values to the toolstrip UI Element.

            for field = string(fieldnames(props))'
                element.(field) = props.(field);
            end
        end
    end
end