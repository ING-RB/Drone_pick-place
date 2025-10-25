function [metaClassNames, metaClassNamesCache] = allSuperMetaClassNames(metaClass)
% a function that returns an array of metaClasses 
% also cache results for MATLAB_UNIT_SUPERCLASSES

%   Copyright 2024 The MathWorks, Inc.

persistent allSuperClassMetaClassNamesCache
persistent cacheableClassNamesArray

if isempty(allSuperClassMetaClassNamesCache)
    allSuperClassMetaClassNamesCache = configureDictionary("string", "cell");
    cacheableClassNamesArray = matlab.unittest.internal.getTestCaseSuperclasses;
end

metaClassNamesCache = allSuperClassMetaClassNamesCache;

currentClassName = metaClass.Name;
if isKey(allSuperClassMetaClassNamesCache, currentClassName)
    % cache hit
    metaClassNames = allSuperClassMetaClassNamesCache{currentClassName};
    return;
end

% cache miss
metaClasses = metaClass.SuperclassList;
metaClassNames = string({metaClasses.Name});

allSuperclassNames = arrayfun(@matlab.unittest.internal.allSuperMetaClassNames, metaClasses, UniformOutput=false);
metaClassNames = [metaClassNames, allSuperclassNames{:}];

if any(currentClassName == cacheableClassNamesArray)
    allSuperClassMetaClassNamesCache{currentClassName} = metaClassNames;
end

metaClassNamesCache = allSuperClassMetaClassNamesCache;

end