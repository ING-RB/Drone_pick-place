function tf = isCellHomogeneous(cellArray)
%ISCELLHOMOGENEOUS Check if all elements are of the same type.
%   Verify that this cell array contains elements that are all of
%   the same MATLAB data type.

%   Copyright 2021 The MathWorks, Inc.

 if isempty(cellArray)
     tf = true;
     return
 end
 cellClassesChars = cellfun(@class, cellArray, ...
     'UniformOutput', false);
 cellClasses = convertCharsToStrings(cellClassesChars);

 tf = all(cellClasses(1) == cellClasses, 'all');

end
