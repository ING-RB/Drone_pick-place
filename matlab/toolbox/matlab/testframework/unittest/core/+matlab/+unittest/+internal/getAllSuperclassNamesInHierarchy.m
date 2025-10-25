function allSuperClassNames = getAllSuperclassNamesInHierarchy(currentClass)
% The function is undocumented and may change in a future release.

% Copyright 2017-2024 The MathWorks, Inc.

assert(isscalar(currentClass));
allMetaClassNames = matlab.unittest.internal.allSuperMetaClassNames(currentClass);
allSuperClassNames = unique(allMetaClassNames.');
end