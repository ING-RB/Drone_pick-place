function resolveImplicitPath(obj, topic)
    resolveFcn = @(topic)innerResolveImplicitPath(obj, topic);
    foundWithImport = matlab.lang.internal.introspective.iterateOverImports(resolveFcn, obj.introspectiveContext.Imports, topic, obj.resolvedSymbol.isCaseSensitive);
    if foundWithImport
        obj.resolvedSymbol.classInfo.unaryName = topic;
    else
        innerResolveImplicitPath(obj, topic);
    end
end

function b = innerResolveImplicitPath(obj, topic)
    [parts, seps] = split(topic, ["\","/","."]);
    while parts{end} == "" && ~isempty(seps)
        parts{end-1} = append(parts{end-1}, seps{end});
        parts(end) = [];
        seps(end) = [];
    end
    lastSepIsDot = ~isempty(seps) && seps{end} == ".";
    seps(seps=="\") = {'/'};

    switch numel(parts)
    case 1
        objectParts.pathAndPackage = parts{1};
        objectParts.class = '';
        unaryResolve(obj, objectParts, [], lastSepIsDot);
    case 2
        objectParts.pathAndPackage = parts{1};
        objectParts.class = parts{2};
        objectParts.method = '';
        resolveBinaryParts(obj, objectParts, [], lastSepIsDot);
    otherwise
        objectParts = resolveTernaryParts(obj, parts, seps, lastSepIsDot);
    end

    if obj.findBuiltins && ~obj.resolvedSymbol.isCaseSensitive && ~obj.resolvedSymbol.isResolved && isempty(obj.resolvedSymbol.classInfo)
        mcosResolver = matlab.lang.internal.introspective.MCOSMetaResolver(topic);
        mcosResolver.executeResolve;
        if mcosResolver.isResolved && ~mcosResolver.isPackage
            obj.resolvedSymbol.isCaseSensitive = mcosResolver.isCaseSensitive;
            obj.resolvedSymbol.classInfo = mcosResolver.getClassInfo;
            obj.resolvedSymbol.isBuiltin = true;
        end
    end

    if ~isempty(obj.resolvedSymbol.classInfo) && ~obj.resolvedSymbol.classInfo.isPackage
        obj.resolvedSymbol.classInfo.isMinimal = ~contains(objectParts.pathAndPackage, ["/", "."]);
    end

    b = ~isempty(obj.resolvedSymbol.classInfo);
end

function objectParts = resolveTernaryParts(obj, parts, seps, lastSepIsDot)
    for i=numel(parts)-2:-1:1
        objectParts.pathAndPackage = strjoin(parts(1:i), seps(1:i-1));
        objectParts.class = parts{i+1};
        objectParts.method = strjoin(parts(i+2:end), '.');
        resolveObjectParts(obj, objectParts, lastSepIsDot);
        if ~isempty(obj.resolvedSymbol.classInfo) || ~obj.resolveOverqualified
            break;
        end
    end
    if isempty(obj.resolvedSymbol.classInfo)
        objectParts.pathAndPackage = parts{1};
        objectParts.class = strjoin(parts(2:end), '.');
        objectParts.method = '';
        resolveBinaryParts(obj, objectParts, [], lastSepIsDot);
    end
end

function resolveObjectParts(obj, objectParts, lastSepIsDot)
    allPackageInfo = ternaryResolve(obj, objectParts);
    if isempty(obj.resolvedSymbol.classInfo)
        [objectParts, allPackageInfo] = convertClassToPackage(obj, objectParts, allPackageInfo);
    end

    resolveBinaryParts(obj, objectParts, allPackageInfo, lastSepIsDot);
end

function resolveBinaryParts(obj, objectParts, allPackageInfo, lastSepIsDot)
    if isempty(obj.resolvedSymbol.classInfo) && objectParts.class ~= ""
        binaryResolve(obj, objectParts, allPackageInfo);
        if isempty(obj.resolvedSymbol.classInfo)
            [objectParts, allPackageInfo] = convertClassToPackage(obj, objectParts, allPackageInfo);
        end
    end

    if isempty(obj.resolvedSymbol.classInfo)
        unaryResolve(obj, objectParts, allPackageInfo, lastSepIsDot);
    end
end

function allPackageInfo = ternaryResolve(obj, objectParts)
    allPackageInfo = getPackageInfo(obj, objectParts);

    for i = 1:numel(allPackageInfo)

        packageInfo = allPackageInfo(i);
        packagePath = packageInfo.path;
        packageName = matlab.lang.internal.introspective.getPackageName(packagePath);

        [isDocumented, packageID] = obj.isDocumentedPackage(packageInfo, packageName);

        if isDocumented

            classIndex      = matlab.lang.internal.introspective.casedStrCmp(obj.resolvedSymbol.isCaseSensitive, packageInfo.classes, objectParts.class);
            className       = '';
            fileType        = '';
            classHasNoAtDir = false;

            if any(classIndex)
                className = packageInfo.classes{classIndex};
                setFoundParentFolder(obj, fullfile(packagePath, "@" + className), objectParts.method);
            elseif ischar(packageID)
                [className, foundTarget, fileType] = matlab.lang.internal.introspective.extractFile(packageInfo, objectParts.class, obj.resolvedSymbol.isCaseSensitive);
                if foundTarget
                    classHasNoAtDir = true;
                end
            end

            if className ~= ""

                if ischar(packageID)
                    classHandle = matlab.lang.internal.introspective.classWrapper.rawMCOS(className, fileType, packagePath, packageID, classHasNoAtDir, false, obj.resolvedSymbol.isCaseSensitive);
                else
                    classHandle = matlab.lang.internal.introspective.classWrapper.rawUDD(className, packagePath, packageID, false);
                end

                obj.resolvedSymbol.classInfo = classHandle.getClassInformation(objectParts.method, obj.justChecking);

                if ~isempty(obj.resolvedSymbol.classInfo)
                    return;
                end
            end
        end
    end
end

function allPackageInfo = binaryResolve(obj, objectParts, allPackageInfo)
    if ~isstruct(allPackageInfo)
        allPackageInfo = getPackageInfo(obj, objectParts);
    end

    binaryResolveThroughPackages(obj, objectParts, allPackageInfo);

    if ~isempty(obj.resolvedSymbol.classInfo)
        return;
    end

    [classMFile, className, packageName] = obj.resolveClassMFile(objectParts.pathAndPackage);

    if className ~= ""
        [packagePath, ~, classExt] = fileparts(classMFile);
        classHandle = matlab.lang.internal.introspective.classWrapper.rawMCOS(className, extractAfter(classExt, 1), packagePath, packageName, true, false, obj.resolvedSymbol.isCaseSensitive);
        obj.resolvedSymbol.classInfo = classHandle.getClassInformation(objectParts.class, obj.justChecking);
    end
end

function binaryResolveThroughPackages(obj, objectParts, allPackageInfo)
    for i = 1:numel(allPackageInfo)

        classHandle = [];
        packageInfo = allPackageInfo(i);
        packagePath = packageInfo.path;
        packageName = matlab.lang.internal.introspective.getPackageName(packagePath);

        [isDocumented, packageID] = obj.isDocumentedPackage(packageInfo, packageName);

        if isDocumented
            classIndex = matlab.lang.internal.introspective.casedStrCmp(obj.resolvedSymbol.isCaseSensitive, packageInfo.classes, objectParts.class);

            if any(classIndex)
                objectParts.class = packageInfo.classes{classIndex};
                if ischar(packageID)
                    classHandle = matlab.lang.internal.introspective.classWrapper.rawMCOS(objectParts.class, '', packagePath, packageID, false, true, obj.resolvedSymbol.isCaseSensitive);
                elseif obj.justChecking || isfile(fullfile(packageInfo.path, "@" + objectParts.class, objectParts.class + ".m"))
                    classHandle = matlab.lang.internal.introspective.classWrapper.rawUDD(objectParts.class, packagePath, packageID, true);
                end
            else
                setFoundParentFolder(obj, packagePath, objectParts.class);
                [className, foundTarget, fileType] = matlab.lang.internal.introspective.extractFile(packageInfo, objectParts.class, obj.resolvedSymbol.isCaseSensitive);
                if foundTarget
                    if ischar(packageID) && matlab.lang.internal.introspective.isClassMFile(fullfile(packagePath, className))
                        % MCOS Class
                        obj.resolvedSymbol.classInfo = matlab.lang.internal.introspective.classInformation.fullConstructor([], packageName, className, packagePath, true, true, obj.justChecking);
                    else
                        obj.resolvedSymbol.classInfo = matlab.lang.internal.introspective.classInformation.packagedFunction(packageName, packagePath, className, fileType);
                    end
                    return;
                else
                    packageList = dir(packagePath);

                    if obj.resolvedSymbol.isCaseSensitive
                        regexCase = 'matchcase';
                    else
                        regexCase = 'ignorecase';
                    end

                    items = regexp({packageList.name}, append('^(?<name>', objectParts.class, ')(?<ext>\.\w+)$'), 'names', regexCase);
                    items = [items{:}];

                    for item = items
                        helpFunction = matlab.lang.internal.introspective.getHelpFunctionForExtension(item.ext);
                        if helpFunction ~= ""
                            % unknown packaged item with help extension
                            itemFullName = append(item.name, item.ext);
                            obj.resolvedSymbol.classInfo = matlab.lang.internal.introspective.classInformation.packagedUnknown(packageName, packagePath, item.name, itemFullName, helpFunction);
                            return;
                        end
                    end
                end
            end
        end

        if isempty(classHandle) && ischar(packageID)
            [packagePath, classDir] = fileparts(packagePath);
            if classDir ~= "" && startsWith(classDir, '@')
                setFoundParentFolder(obj, packageInfo.path, objectParts.class);
                packageSplit = regexp(packageName, '(?<package>.*(?=\.))?\.?(?<class>.*)', 'names');
                packageName  = packageSplit.package;
                classHandle  = matlab.lang.internal.introspective.classWrapper.rawMCOS(packageSplit.class, '', packagePath, packageName, false, false, obj.resolvedSymbol.isCaseSensitive);
            end
        end

        if ~isempty(classHandle)
            obj.resolvedSymbol.classInfo = classHandle.getClassInformation(objectParts.class, obj.justChecking);
            if ~isempty(obj.resolvedSymbol.classInfo)
                return;
            end
        end
    end
end

function unaryResolve(obj, objectParts, allPackageInfo, lastSepIsDot)
    className = objectParts.pathAndPackage;

    obj.resolveUnaryClass(className);

    if obj.resolvedSymbol.whichTopic == "" && ~isempty(regexp(className, '.*\w$', 'once'))
        if ~isstruct(allPackageInfo)
            allPackageInfo = getPackageInfo(obj, objectParts);
        end

        obj.resolvePackageInfo(allPackageInfo, false);

        if isempty(obj.resolvedSymbol.classInfo)
            if lastSepIsDot
                % which may have used an extension as a target
                obj.resolvedSymbol.whichTopic = '';
            end
        elseif ~obj.resolvedSymbol.classInfo.isPackage && ~contains(className, '/') && matlab.lang.internal.introspective.isClass(className)
            % if a class folder exists for a true unary name, but the unary class was
            % not resolved, then this folder is for extension methods for a builtin
            obj.resolvedSymbol.classInfo = [];
        end
    end

    if ~isempty(obj.resolvedSymbol.classInfo)
        obj.resolvedSymbol.classInfo.unaryName = className;
    end
end

function [objectParts, newPackageInfo] = convertClassToPackage(obj, objectParts, oldPackageInfo)
    newPackageInfo = [];

    for i = 1:numel(oldPackageInfo)
        packageIndex = matlab.lang.internal.introspective.casedStrCmp(obj.resolvedSymbol.isCaseSensitive, oldPackageInfo(i).packages, objectParts.class);
        if any(packageIndex)
            newPackageInfo = [newPackageInfo; matlab.lang.internal.introspective.hashedDirInfo(fullfile(oldPackageInfo(i).path, append('+', oldPackageInfo(i).packages{packageIndex})), obj.resolvedSymbol.isCaseSensitive)]; %#ok<AGROW>
        end
    end

    if obj.resolveOverqualified
        uddPackageInfo  = matlab.lang.internal.introspective.hashedDirInfo(append(objectParts.pathAndPackage, '/@', objectParts.class), obj.resolvedSymbol.isCaseSensitive);
        mcosPackageInfo = matlab.lang.internal.introspective.hashedDirInfo(append(objectParts.pathAndPackage, '/+', objectParts.class), obj.resolvedSymbol.isCaseSensitive);
        newPackageInfo = [newPackageInfo; mcosPackageInfo; uddPackageInfo];

        [~, i] = unique({newPackageInfo.path}, 'stable');
        newPackageInfo = newPackageInfo(i);
    end

    objectParts.pathAndPackage = append(objectParts.pathAndPackage, '/', replace(objectParts.class, '.', '/'));
    objectParts.class          = objectParts.method;
    objectParts.method         = '';
end

function allPackageInfo = getPackageInfo(obj, objectParts)
    packagePath    = regexprep(objectParts.pathAndPackage, '\.(\w*)$', '/$1');
    allPackageInfo = matlab.lang.internal.introspective.hashedDirInfo(regexprep(packagePath, '(^|/)(\w*)$', '$1@$2'), obj.resolvedSymbol.isCaseSensitive);

    if contains(objectParts.class, '.')
        return;
    end

    pathSeps = regexp(packagePath, '[/.]');

    if isempty(pathSeps)
        allPackageInfo = [matlab.lang.internal.introspective.hashedDirInfo(append('+', packagePath), obj.resolvedSymbol.isCaseSensitive); allPackageInfo];
    elseif ~obj.resolveOverqualified
        packagePath = replace(packagePath, ["/", "."], "/+");
        allPackageInfo = [matlab.lang.internal.introspective.hashedDirInfo(packagePath, obj.resolvedSymbol.isCaseSensitive); allPackageInfo];
    else
        for pathSep = fliplr(pathSeps)
            packagePath    = append(extractBefore(packagePath, pathSep), '/+', extractAfter(packagePath, pathSep));
            allPackageInfo = [matlab.lang.internal.introspective.hashedDirInfo(packagePath, obj.resolvedSymbol.isCaseSensitive); allPackageInfo]; %#ok<AGROW>
        end
    end
end

function setFoundParentFolder(obj, parentFolder, childName)
    if obj.resolvedSymbol.isCaseSensitive && ~obj.resolvedSymbol.isUnderqualified &&  obj.foundParentFolder == "" && ~contains(childName, '.')
        obj.foundParentFolder = parentFolder;
    end
end

%   Copyright 2014-2024 The MathWorks, Inc.
