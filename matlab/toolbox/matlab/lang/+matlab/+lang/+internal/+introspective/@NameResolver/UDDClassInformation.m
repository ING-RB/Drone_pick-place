function UDDClassInformation(obj, UDDParts)

    packagePath    = append(UDDParts.path, UDDParts.package);
    inputClassName = extractAfter(UDDParts.class, 1);
    methodName     = UDDParts.method;

    if methodName == ""
        methodName = inputClassName;
    end

    allPackageInfo = matlab.lang.internal.introspective.hashedDirInfo(packagePath, obj.resolvedSymbol.isCaseSensitive);
    
    for i = 1:numel(allPackageInfo)
        
        packageInfo = allPackageInfo(i);
        packagePath = packageInfo.path;
        packageName = matlab.lang.internal.introspective.getPackageName(packagePath);
        
        [isDocumented, packageID] = obj.isDocumentedPackage(packageInfo, packageName);
        
        if isDocumented
            classIndex = matlab.lang.internal.introspective.casedStrCmp(obj.resolvedSymbol.isCaseSensitive, packageInfo.classes, inputClassName);
            if any(classIndex)
                className = packageInfo.classes{classIndex};
                
                classHandle   = matlab.lang.internal.introspective.classWrapper.rawUDD(className, packagePath, packageID, true);
                obj.resolvedSymbol.classInfo = classHandle.getClassInformation(methodName, obj.justChecking);
                                
                if ~isempty(obj.resolvedSymbol.classInfo)
                    return;
                end
            end
        end
    end
end

%   Copyright 2013-2024 The MathWorks, Inc.
