function [properties, childrenEl] = getPropertiesFromComponentElement(componentEl, parentCodeName, objectName, isLoad)
    %GETPROPERTIESFROMCOMPONENTELEMENT % iterates a component element children, extracting all properties and the "Children" element

%   Copyright 2024 The MathWorks, Inc.

    arguments
        componentEl matlab.io.xml.dom.Element
        parentCodeName char
        objectName
        isLoad logical = false
    end

    childrenEl = [];
    propertiesOutputAssigned = false;

    childNodes = componentEl.getChildNodes();

    count = childNodes.getLength();

    hasParent = strlength(parentCodeName) ~= 0;

    if hasParent
        count = count + 1;
    end

    childrenNodes = cell(1, count);
    elementNodeCount = 0;
    for i = 1:count
        child = childNodes.item(i - 1);

        if isa(child, 'matlab.io.xml.dom.Element')
            if ~strcmp(child.TagName, 'Children')
                elementNodeCount = elementNodeCount + 1;
                childrenNodes{elementNodeCount} = child;
            else
                childrenEl = child;
            end
        end
    end

    startElementIndex = 1;
    if hasParent
        elementNodeCount = elementNodeCount + 1;
        startElementIndex = 2;

        propertiesOutputAssigned = true;
        properties(1) = struct('PropertyName', 'Parent', 'PropertyValue', append(objectName, '.', parentCodeName));
    end

    % Use a backward loop trick to pre-allocate array
    for i = elementNodeCount:-1:startElementIndex
        child = childrenNodes{i - startElementIndex + 1};

        propertiesOutputAssigned = true;
        properties(i) = struct('PropertyName', child.TagName, 'PropertyValue', appdesigner.internal.artifactgenerator.XMLUtil.getElementValue(child));
    end

    if ~propertiesOutputAssigned
        properties = [];
    end
 
    if isLoad && strcmp(componentEl.TagName, 'UIFigure')
        % check real visibility / AD_Visible
        properties = [properties struct('PropertyName', 'Visible', 'PropertyValue', '''off''')];
    end
end
