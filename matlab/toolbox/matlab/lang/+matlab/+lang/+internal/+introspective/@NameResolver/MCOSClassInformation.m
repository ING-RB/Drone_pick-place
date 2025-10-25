function MCOSClassInformation(obj, topic, MCOSParts)
    if MCOSParts.packages == ""
        resolveWithoutMCOSPackages(obj, topic, MCOSParts);
    else
        resolveWithMCOSPackages(obj, MCOSParts);
    end
end

function resolveWithoutMCOSPackages(obj, topic, MCOSParts)
    if MCOSParts.method == ""
        allPackageInfo = matlab.lang.internal.introspective.hashedDirInfo(topic, obj.resolvedSymbol.isCaseSensitive);
        obj.resolvePackageInfo(allPackageInfo, true);
    else
        allPackageInfo = matlab.lang.internal.introspective.hashedDirInfo(append(MCOSParts.path, '@', MCOSParts.class), obj.resolvedSymbol.isCaseSensitive);

        for i = 1:numel(allPackageInfo)

            packageInfo = allPackageInfo(i);
            packagePath = packageInfo.path;
            packageName = matlab.lang.internal.introspective.getPackageName(packagePath);

            % Correct the case for subsequent uses of this data
            MCOSParts.class = matlab.lang.internal.introspective.extractCaseCorrectedName(packagePath, MCOSParts.class);

            [isDocumented, packageID] = obj.isDocumentedPackage(packageInfo, packageName);

            if isDocumented || ischar(packageID)
                % MCOS or OOPS class or UDD package
                [fixedName, foundTarget, fileType] = matlab.lang.internal.introspective.extractFile(packageInfo, MCOSParts.method, obj.resolvedSymbol.isCaseSensitive, MCOSParts.ext);
                if foundTarget
                    % MCOS or OOPS class/method or UDD packaged function
                    if MCOSParts.local ~= ""
                        classHandle = matlab.lang.internal.introspective.classWrapper.rawMCOS(fixedName, fileType, fileparts(packagePath), '', false, false, obj.resolvedSymbol.isCaseSensitive);
                        obj.resolvedSymbol.classInfo = classHandle.getClassInformation(MCOSParts.local, obj.justChecking);
                    elseif strcmp(MCOSParts.class, fixedName)
                        obj.resolvedSymbol.classInfo = matlab.lang.internal.introspective.classInformation.simpleMCOSConstructor(MCOSParts.class, fullfile(packagePath, append(MCOSParts.class, fileType)), obj.justChecking);
                    elseif isDocumented
                        obj.resolvedSymbol.classInfo = createPackagedFunction(MCOSParts.class, packagePath, fixedName, fileType);
                    else
                        classHandle = matlab.lang.internal.introspective.classWrapper.rawMCOS(fixedName, fileType, packagePath, '', false, false, obj.resolvedSymbol.isCaseSensitive);
                        obj.resolvedSymbol.classInfo = matlab.lang.internal.introspective.classInformation.fileMethod(classHandle, MCOSParts.class, packagePath, packagePath, fixedName, fileType, '');
                        obj.resolvedSymbol.classInfo.setAccessible;
                    end
                    return;
                end
            end
        end
    end
end

function resolveWithMCOSPackages(obj, MCOSParts)
    inputClassName = MCOSParts.class;
    methodName     = MCOSParts.method;

    packagePath    = append(MCOSParts.path, MCOSParts.packages);
    allPackageInfo = matlab.lang.internal.introspective.hashedDirInfo(packagePath, obj.resolvedSymbol.isCaseSensitive);

    if inputClassName == "" && methodName == ""
        if ~isempty(allPackageInfo)
            % MCOS Package
            obj.resolvedSymbol.classInfo = matlab.lang.internal.introspective.classInformation.package(allPackageInfo(1).path, true, false);
        end
        return;
    end

    isUnspecifiedConstructor = methodName == "";
    if isUnspecifiedConstructor
        methodName = inputClassName;
    end

    for i = 1:numel(allPackageInfo)

        packageInfo     = allPackageInfo(i);
        packagePath     = packageInfo.path;
        packageName     = matlab.lang.internal.introspective.getPackageName(packagePath);
        className       = '';
        classHasNoAtDir = false;

        if inputClassName ~= ""

            classIndex = matlab.lang.internal.introspective.casedStrCmp(obj.resolvedSymbol.isCaseSensitive, packageInfo.classes, inputClassName);

            if any(classIndex)
                className = packageInfo.classes{classIndex};
            end
        elseif ~isUnspecifiedConstructor

            [className, foundTarget, fileType] = matlab.lang.internal.introspective.extractFile(packageInfo, methodName, obj.resolvedSymbol.isCaseSensitive, MCOSParts.ext);

            if foundTarget
                if ~matlab.lang.internal.introspective.isClassMFile(fullfile(packagePath, className))
                    obj.resolvedSymbol.classInfo = createPackagedFunction(packageName, packagePath, className, fileType);
                    return;
                end
                classHasNoAtDir = true;

            elseif MCOSParts.ext ~= ""
                packageList = dir(fullfile(packagePath, append('*', MCOSParts.ext)));
                itemIndex   = matlab.lang.internal.introspective.casedStrCmp(obj.resolvedSymbol.isCaseSensitive, {packageList.name}, append(MCOSParts.method, MCOSParts.ext));

                if any(itemIndex)
                    itemFullName  = packageList(itemIndex).name;
                    [~, itemName] = fileparts(itemFullName);

                    [~, ~, ext] = fileparts(itemFullName);
                    helpFunction = matlab.lang.internal.introspective.getHelpFunctionForExtension(ext);

                    obj.resolvedSymbol.classInfo = matlab.lang.internal.introspective.classInformation.packagedUnknown(packageName, packagePath, itemName, itemFullName, helpFunction);
                    return;
                end
            end
        end

        if className ~= ""
            hasLocalName = MCOSParts.local ~= "";
            classHandle = matlab.lang.internal.introspective.classWrapper.rawMCOS(className, '', packagePath, packageName, classHasNoAtDir, ~hasLocalName, obj.resolvedSymbol.isCaseSensitive);
            if hasLocalName
                methodName = MCOSParts.local;
            end
            obj.resolvedSymbol.classInfo = classHandle.getClassInformation(methodName, obj.justChecking);

            if ~isempty(obj.resolvedSymbol.classInfo)
                return;
            end
        end
    end
end

function classInfo = createPackagedFunction(packageName, packagePath, className, fileType)
    if className == "Contents" && fileType == ".m"
        classInfo = matlab.lang.internal.introspective.classInformation.package(packagePath, true, false);
    else
        classInfo = matlab.lang.internal.introspective.classInformation.packagedFunction(packageName, packagePath, className, fileType);
    end
end

%   Copyright 2013-2024 The MathWorks, Inc.
