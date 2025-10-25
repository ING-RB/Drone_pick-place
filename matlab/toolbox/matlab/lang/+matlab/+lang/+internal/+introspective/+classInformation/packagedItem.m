classdef packagedItem < matlab.lang.internal.introspective.classInformation.base
    properties
        packagedName (1,1) string = "";
    end

    methods
        function ci = packagedItem(packageName, packagePath, itemName, itemFullName)
            definition = fullfile(packagePath, itemFullName);
            ci@matlab.lang.internal.introspective.classInformation.base(definition, definition, definition);
            ci.element = itemName;
            ci.packagedName = append(packageName, '.', itemName);
        end
        
        function topic = fullTopic(ci)
            topic = ci.packagedName;
        end
        
        function k = getKeyword(~)
            k = 'packagedItem';
        end
    end
end

%   Copyright 2007-2024 The MathWorks, Inc.
