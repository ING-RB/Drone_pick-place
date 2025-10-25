function propGroups = displayableProperties(obj)
% displayableProperties returns the list of public and visible properties
% of the object honoring any customizations made by class authors on the
% property list through the CustomDisplay mixin

%   Copyright 2023 The MathWorks, Inc.

arguments(Input)
    obj (1, :) {mustBeNonempty, matlab.display.internal.doesClassUsePropertyValuePairDisplay(obj, "IssueError", 1)}
end
arguments(Output)
    propGroups (1,:) matlab.display.internal.PropertyGroup
end

propGroups = matlab.display.internal.displayablePropertiesHelper(obj);

propGroups = filterNonExistentProperties(propGroups, obj);

end

function propGroups = filterNonExistentProperties(propGroups, obj)
% Return a logical array indicating what indices from the input PROPS
% string array map to properties defined by the class
arguments(Input)
    propGroups (:, 1) matlab.display.internal.PropertyGroup
    obj (1, :) {mustBeNonempty}
end
arguments(Output)
    propGroups (:, 1) matlab.display.internal.PropertyGroup
end

for i=1:numel(propGroups)
    props = propGroups(i).PropertyNames;
    propNamesIndices = false(1, numel(props));
    for j=1:numel(props)
        if isprop(obj,props(j))
            propNamesIndices(j) = true;
        else
            propNamesIndices(j) = false;
        end
    end
    propGroups(i).PropertyNames = props(propNamesIndices);
    propGroups(i).DataTypes = propGroups(i).DataTypes(propNamesIndices);
end
end
