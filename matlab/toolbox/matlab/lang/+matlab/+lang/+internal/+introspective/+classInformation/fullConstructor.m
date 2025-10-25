classdef fullConstructor < matlab.lang.internal.introspective.classInformation.fileConstructor
    properties (SetAccess=private, GetAccess=private)
        isUnspecified = false;
    end

    methods
        function ci = fullConstructor(classWrapper, packageName, className, basePath, noAtDir, isUnspecified, justChecking)
            pathInfo = matlab.lang.internal.introspective.hashedDirInfo(basePath);
            [~, ~, fileType] = matlab.lang.internal.introspective.extractFile(pathInfo(1), className, true);
            if fileType == ""
                fullPath = basePath;
            else
                fullPath = fullfile(basePath, append(className, fileType));
            end
            ci@matlab.lang.internal.introspective.classInformation.fileConstructor(packageName, className, basePath, fullPath, noAtDir, justChecking);
            ci.classWrapper = classWrapper;
            ci.isUnspecified = isUnspecified;
        end

        function b = isClass(ci)
            b = ci.isUnspecified;
        end
    end
end

%   Copyright 2007-2024 The MathWorks, Inc.
