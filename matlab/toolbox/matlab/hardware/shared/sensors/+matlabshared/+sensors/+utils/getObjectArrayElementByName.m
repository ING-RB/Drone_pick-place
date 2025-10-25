%   Copyright 2022 The MathWorks, Inc.
function [matchingObject,index] = getObjectArrayElementByName(elementName,objArray)
% GETOBJECTARRAYELEMENTBYNAME Get the object with a given name from the object array
% Returns empty if the object is not found
index = 0;
matchingObject = [];
for i=1:numel(objArray)
    if iscell(objArray)
        obj = objArray{i};
    else
        obj = objArray(i);
    end
    assert(isprop(obj{1},'Name'), 'You cannot use ''getObjectArrayElementByName'' for array elements that do not have the property ''Name''.')
    if isprop(obj{1},'Name') && isequal(elementName,obj{1}.Name)
        matchingObject = obj;
        index = i;
        return;
    end
end
end