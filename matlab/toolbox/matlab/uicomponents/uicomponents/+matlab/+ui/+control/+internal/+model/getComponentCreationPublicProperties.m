function parameterList = getComponentCreationPublicProperties(component)
%GETCOMPONENTCREATIONPUBLICPROPERTIES Get public properties of component
%   Returns public properties for the component class provided as input
parameterList = properties(component);
if any(strcmp(parameterList, 'ContextMenu'))
    % Add 'UIContextMenu' hidden property to list - g2130935
    parameterList{end + 1} = 'UIContextMenu';
end
end