function methodList = filterInaccessibleMethods(classMeta)
    methodList = classMeta.MethodList;
    methodList(strcmp({methodList.Name}, shortenName(classMeta.Name))) = [];
    methodList(arrayfun(@(c)~matlab.lang.internal.introspective.isAccessible(c, 'methods'), methodList)) = [];
end

%   Copyright 2022-2023 The MathWorks, Inc.
