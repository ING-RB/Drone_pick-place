function val = isComponentInDesignTime(component)
    %ISCOMPONENTINDESIGNTIME Returns true if a UI component is being used
    %in App Designer design-time

    % Copyright 2022 The MathWorks, Inc.

    val = false;

    % Ideally we should be able to check if the component has a
    % DesignTimeProperties property, but due to how custom components
    % (using ComponentContainer) load, the custom component setup method is
    % called before DesignTimeProperties is added to the component. We can
    % remove the use of componentObjectBeingLoadedInAppDesigner once
    % g2818227 has been addressed.
    if matlab.ui.componentcontainer.ComponentContainer.componentObjectBeingLoadedInAppDesigner || ...
       any(isprop(ancestor(component, 'figure'), 'DesignTimeProperties'))
        
        val = true;
    end
end

