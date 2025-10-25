function classMethod = getMethod(metaClass, methodName, isCaseSensitive)
    classMethods = metaClass.MethodList;
    classMethod = [];
    
    if nargin < 3
       isCaseSensitive = false; 
    end

    if ~isempty(classMethods)
        % remove methods that do not match methodName
        classMethods(~matlab.lang.internal.introspective.casedStrCmp(isCaseSensitive, string({classMethods.Name}), methodName)) = [];
        if ~isempty(classMethods)
            % remove methods that are constructors
            definingClasses = [classMethods.DefiningClass];
            classMethods(strcmp({classMethods.Name}, {definingClasses.Name})) = [];
                        
            if ~isempty(classMethods)
                
                staticMethods = classMethods([classMethods.Static]);
            
                % select the first method if more than one method is remaining
                if ~isempty(staticMethods)
                    classMethod = staticMethods(1);
                else                
                    classMethod = classMethods(1);
                end
            end
        end
    end

    if isempty(classMethod) && startsWith(methodName, ["get.", "set."], "IgnoreCase", ~isCaseSensitive)
        propertyName = extractAfter(methodName, ".");
        classProperties = metaClass.PropertyList;
        if ~isempty(classProperties)
            classProperties(~matlab.lang.internal.introspective.casedStrCmp(isCaseSensitive, string({classProperties.Name}), propertyName)) = [];
            if ~isempty(classProperties)
                classProperty = classProperties(1);
                if startsWith(methodName, "g")
                    if ~isempty(classProperty.GetMethod)
                        classMethod.Name = append('get.', classProperty.Name);
                        classMethod.Access = classProperty.GetAccess;
                    end
                else
                    if ~isempty(classProperty.SetMethod)
                        classMethod.Name = append('set.', classProperty.Name);
                        classMethod.Access = classProperty.SetAccess;
                    end
                end
                if ~isempty(classMethod)
                    classMethod.DefiningClass = classProperty.DefiningClass;
                    classMethod.Hidden = classProperty.Hidden;
                    classMethod.Static = false;
                    classMethod.Abstract = false;
                    classMethod.Sealed = classProperty.DefiningClass.Sealed;
                    classMethod.Description = '';
                end
            end
        end
    end
end
        
%   Copyright 2014-2023 The MathWorks, Inc.
