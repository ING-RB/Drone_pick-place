classdef constructor < matlab.lang.internal.introspective.classInformation.classItem
    properties (SetAccess=protected, GetAccess=protected)
        metaClass = [];
        packagedName = '';
        classError = false;
        classLoaded = false;
    end

    methods
        function ci = constructor(packageName, className, definition, whichTopic, justChecking)
            ci@matlab.lang.internal.introspective.classInformation.classItem(packageName, className, definition, definition, whichTopic);
            if ~justChecking
                ci.loadClass;
                if ci.classError
                    ci.isAccessible = true;
                elseif isempty(ci.metaClass)
                    ci.isAccessible = true;
                else
                    ci.isAccessible = ~ci.metaClass.Hidden;
                end
            end
        end
        
        function b = isConstructor(ci)
            b = ~ci.isClass;
        end
        
        function b = isMCOSClassOrConstructor(ci)
            ci.loadClass;
            b = ci.classError || ~isempty(ci.metaClass);
        end
        
        function topic = fullTopic(ci)
            topic = ci.fullClassName;
            if ci.isConstructor
                topic = append(topic, '/', ci.className);
            end                
        end
        
        function k = getKeyword(~)
            k = 'constructor';
        end

        function description = getDescription(ci, justH1)
            ci.loadClass;
            if isempty(ci.metaClass)
                description = '';
            else
                description = matlab.lang.internal.introspective.getBuiltinHelpText(ci.metaClass, ci.fullTopic, justH1);
            end
        end
    end

    methods (Access=protected)
        function loadClass(ci)
            if ~ci.classLoaded
                ci.classLoaded = true;
                ci.packagedName = matlab.lang.internal.introspective.makePackagedName(ci.packageName, ci.className);
                [ci.metaClass, ci.classError] = matlab.lang.internal.introspective.getMetaClass(ci.packagedName);
            end
        end
    end
end

%   Copyright 2007-2023 The MathWorks, Inc.
