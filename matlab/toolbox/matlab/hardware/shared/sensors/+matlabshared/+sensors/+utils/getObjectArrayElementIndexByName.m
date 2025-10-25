%   Copyright 2022 The MathWorks, Inc.
function index = getObjectArrayElementIndexByName(elementName,objArray)
%GETOBJECTARRAYELEMENTINDEXBYNAME Get the index of the object with a given name from the object array
% Returns 0 if the object is not found

[~,index] = getObjectArrayElementByName(elementName,objArray);

end
