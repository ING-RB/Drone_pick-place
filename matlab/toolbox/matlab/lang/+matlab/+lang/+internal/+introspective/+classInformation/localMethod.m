classdef localMethod < matlab.lang.internal.introspective.classInformation.method
    methods
        function ci = localMethod(classWrapper, className, basePath, classMFile, derivedPath, derivedClass, methodName, packageName)
            definition = fullfile(basePath, append(className, filemarker, methodName));
            minimalPath = fullfile(derivedPath, append(derivedClass, filemarker, methodName));
            ci@matlab.lang.internal.introspective.classInformation.method(classWrapper, packageName, className, methodName, definition, minimalPath, classMFile);
        end
    end
end

%   Copyright 2007-2023 The MathWorks, Inc.
