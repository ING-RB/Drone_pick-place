function fullElementName = getFullElementName(className, elementMeta)
    if isprop(elementMeta, 'Static') && elementMeta.Static
        separator = '.';
    else
        separator = '/';
    end
    fullElementName = append(className, separator, elementMeta.Name);
end

%   Copyright 2022 The MathWorks, Inc.
