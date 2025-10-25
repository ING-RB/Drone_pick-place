classdef ViewConfiguration < ...
        matlabshared.transportapp.internal.utilities.viewconfiguration.IViewConfiguration
    %VIEWCONFIGURATION provides a common set of API's for the controller to
    %interact with the corresponding View class.

    % Copyright 2020-2023 The MathWorks, Inc.

    properties
        View 
    end

    %% Lifetime
    methods
        function obj = ViewConfiguration(view)
           obj.View = view;
        end
    end

    %% Abstract Methods
    methods
        function setViewProperty(obj, element, property, value)
            % Set the property value of the view element.

            obj.View.(element).(property) = value;
        end

        function setViewPropertyForTheming(obj, element, property, value)
            % Set the themeable property value using
            % "specifyThemePropertyMappings"

            elem = obj.View.(element);
            matlab.graphics.internal.themes.specifyThemePropertyMappings(elem,...
                property, value); 
        end

        function value = getViewProperty(obj, element, property)
            % Get the property value of a view element.

            value = obj.View.(element).(property);
        end

        function addItemsToDropDownList(obj, element, items)
            % For a dropdown list, add items to the dropdown list that
            % shows up when the dropdown is clicked.

            arguments
                obj
                element
                items (1,:) string
            end

            for item = items
               obj.View.(element).addItem(item);
            end
        end

        function clearDropDownItemsList(obj, element)
            % For a dropdown list, clear exisiting dropdown list item
            % values.
            obj.View.(element).replaceAllItems({});
        end
    end
end
