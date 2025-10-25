classdef classItem < matlab.lang.internal.introspective.classInformation.base
    properties
        packageName        (1,1) string = "";
        className          (1,1) string = "";
    end

    methods
        function ci = classItem(packageName, className, definition, minimalPath, whichTopic)
            ci@matlab.lang.internal.introspective.classInformation.base(definition, minimalPath, whichTopic);
            ci.packageName = packageName;
            ci.className   = className;
            ci.element     = className;
        end

        function topic = fullClassName(ci)
            topic = matlab.lang.internal.introspective.makePackagedName(ci.packageName, ci.className);
        end
    end
end

%   Copyright 2007-2024 The MathWorks, Inc.
