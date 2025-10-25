classdef packagedUnknown < matlab.lang.internal.introspective.classInformation.packagedItem
    properties
        helpFunction = '';
    end
    
    methods
        function ci = packagedUnknown(packageName, packagePath, itemName, itemFullName, helpFunction)
            ci@matlab.lang.internal.introspective.classInformation.packagedItem(packageName, packagePath, itemName, itemFullName);
            ci.helpFunction = helpFunction;
        end
    end
    
    methods (Access=protected)
        function helpText = helpfunc(ci, justH1)
            helpText = matlab.lang.internal.introspective.callHelpFunction(ci.helpFunction, ci.whichTopic, justH1);
        end
    end
end

%   Copyright 2007-2023 The MathWorks, Inc.
