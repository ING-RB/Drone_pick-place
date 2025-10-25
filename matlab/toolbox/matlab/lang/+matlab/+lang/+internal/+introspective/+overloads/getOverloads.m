function outputList = getOverloads(topic, imports, args)
    arguments
        topic   (1,1) string;
        imports (1,:) string;

        args.OnlyGetFirstOverload  (1,1) logical = false;
        args.ShouldFormatSeparator (1,1) logical = false;
    end

    outputList = {};

    objectNameParts = split(topic, '/');

    methodPart = objectNameParts{end};

    if methodPart == ""
        return;
    end

    if isscalar(objectNameParts)
        objectPart = "";
    else
        objectPart = join(objectNameParts(1:end-1), '/');
    end

    [overloadList, isExplicitlyVisible] = getListOfClassesWithOverload(methodPart, imports);
    [referenceList, folders] = getClassesFromReference(methodPart);

    referenceList = setdiff(referenceList, overloadList);
    overloadList = [overloadList, referenceList];
    folders = setdiff(folders, overloadList);

    isExplicitlyVisible = [isExplicitlyVisible; true(numel(referenceList), 1)];

    thisMethod = objectPart == overloadList;
    overloadList(thisMethod) = [];
    isExplicitlyVisible(thisMethod) = [];

    checkForSeparator = false(size(overloadList));
    if args.ShouldFormatSeparator
        [~, ~, classesInMem] = inmem;
        [~, indexesInMem] = intersect(overloadList, classesInMem);
        checkForSeparator(indexesInMem) = true;
    end

    for i = 1:numel(overloadList)
        qualifiedName = getQualifiedName(overloadList{i}, methodPart, checkForSeparator(i), isExplicitlyVisible(i));

        if qualifiedName ~= ""
            outputList{end+1} = qualifiedName; %#ok<AGROW>

            if args.OnlyGetFirstOverload
                break;
            end
        end
    end

    folders = folders + "/" + methodPart;
    outputList = [outputList, cellstr(folders)];

    if numel(outputList) > 1
        [~, sortedIndex] = sort(lower(outputList));
        outputList = outputList(sortedIndex);
    end
end

function [classNames, isExplicitlyVisible] = getListOfClassesWithOverload(topic, imports)
    classNames = {};
    isExplicitlyVisible = [];

    cellfun(@import, imports);

    try
        [overloadPath, overloadComment] = which(topic, '-all');
    catch
        return;
    end

    if numel(overloadComment) < 2
        return;
    end

    [isValidOverload, isExplicitlyVisible] = cellfun(@(p,c)isValidOverloadRule(p,c, topic), overloadPath, overloadComment);

    overloadComment = overloadComment(isValidOverload);
    isExplicitlyVisible = isExplicitlyVisible(isValidOverload);

    qualifier = regexp(overloadComment,'(?<qualifier>[\w.]+)\smethod(?! or )','names','once');
    qualifier = [qualifier{:}];

    if ~isempty(qualifier)
        classNames = {qualifier.qualifier};
        [classNames, i] = unique(classNames);
        isExplicitlyVisible = isExplicitlyVisible(i);
    end
end

function [isValid, isExplicitlyVisible] = isValidOverloadRule(path, comment, topic)
    [parent, filename, ext] = fileparts(path);
    isValid = ext ~= "" && ~strcmp(ext,'.p') && comment ~= "" && ~strcmp(comment, 'Shadowed');
    if isValid
        isExplicitlyVisible = matches(filename, topic) && ~isempty(regexp(parent, '(?<![\\/][@+][^\\/]+)[\\/]@[^\\/]+$', 'once'));
    else
        isExplicitlyVisible = false;
    end
end

function qualifiedName = getQualifiedName(qualifiedName, fcnName, shouldFormatSeparator, isExplicitlyVisible)
    if ~shouldFormatSeparator && isExplicitlyVisible
        qualifiedName = append(qualifiedName, '/', fcnName);
    else
        [sep, isHidden] = getMCOSSeparator(qualifiedName, fcnName);

        if isHidden && ~isExplicitlyVisible
            qualifiedName = '';
        else
            if sep == ""
                sep = getUDDSeparator(qualifiedName, fcnName);
            end

            if sep == ""
                sep = '/';
            end

            qualifiedName = append(qualifiedName, sep, fcnName);
        end
    end
end

function [sep, isHidden] = getMCOSSeparator(qualifiedName, fcnName)
    sep      = '';
    isHidden = false;

    classInfo = matlab.lang.internal.introspective.getMetaClass(qualifiedName);

    if ~isempty(classInfo)
        methodMatch = strcmp({classInfo.MethodList.Name},fcnName);
        methodInfo  = classInfo.MethodList(methodMatch);

        if ~isempty(methodInfo)
            isHidden = classInfo.Hidden || all([methodInfo.Hidden]);

            if all([methodInfo.Static])
                sep = '.';
            else
                sep = '/';
            end
        end
    end
end

function sep = getUDDSeparator(qualifiedName, fcnName)
    sep = '';

    parts = strsplit(qualifiedName,'.');

    if numel(parts) == 2
        package = findpackage(parts{1});
        if ~isempty(package)
            for class = package.Classes'
                if strcmp(parts{2}, class.Name)
                    for method = class.Methods'
                        if strcmp(fcnName, method.Name)
                            if strcmp(method.Static,'off')
                                sep = '/';
                            else
                                sep = '.';
                            end
                            return;
                        end
                    end
                end
            end
        end
    end
end

function [classNames, folders] = getClassesFromReference(topic)
    refTopic = matlab.internal.doc.reference.ReferenceTopic(topic);
    refTopic.EntityTypes = ["Function", "Method"];
    [~, others] = matlab.lang.internal.introspective.getBestReferenceItem(refTopic, topic);
    classNames = {};
    classFolders = strings(0);
    folders = strings(0);
    for other = others
        refItem = other.item;
        if ~isempty(refItem.RefEntities) && refItem.DeprecationStatus == matlab.internal.reference.property.DeprecationStatus.Current
            referenceName = char(matlab.internal.help.getQualifiedNameFromReferenceItem(refItem));
            if ~contains(topic, '.') && contains(referenceName, '.')
                classNames{end+1} = extractBefore(referenceName, "." + topic + textBoundary); %#ok<AGROW>
                classFolders(end+1) = refItem.HelpFolder; %#ok<AGROW>
            else
                folders(end+1) = refItem.HelpFolder; %#ok<AGROW>
            end
        end
    end
    folders = setdiff(folders, classFolders);
end

%   Copyright 2015-2024 The MathWorks, Inc.
