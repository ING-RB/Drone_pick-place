classdef (Abstract) IViewConfiguration < handle
    %IVIEWCONFIGURATION Interface class provides abstract member functions
    %and properties that all ViewConfiguration classes need to implement.

    % Copyright 2020-2023 The MathWorks, Inc.

    properties (Abstract)
        % Handle to the View Class
        View
    end

    methods (Abstract)
        % Set the property value of the view element.
        setViewProperty(obj, element, property, value);

        % For dark-theme support, set the themeable property value using
        % "specifyThemePropertyMappings"
        setViewPropertyForTheming(obj, element, property, value);

        % Get the property value of a view element.
        value = getViewProperty(obj, element, property);

        % For a dropdown list, add items to the dropdown list that shows up
        % when the dropdown is clicked.
        addItemsToDropDownList(obj, element, item);

        % For a dropdown list, clear exisiting dropdown list item values.
        clearDropDownItemsList(obj, element);
    end
end
