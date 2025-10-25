classdef packagedFunction < matlab.lang.internal.introspective.classInformation.packagedItem
    methods
        function ci = packagedFunction(packageName, packagePath, itemName, itemExt)
            ci@matlab.lang.internal.introspective.classInformation.packagedItem(packageName, packagePath, itemName, append(itemName, itemExt));
        end
    end
end

%   Copyright 2007-2023 The MathWorks, Inc.
