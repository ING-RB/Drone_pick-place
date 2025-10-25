function getFolderHelp(hp, justH1)
    hasFunctionHelp = hp.helpStr ~= "";
    dirTopic = hp.inputTopic;
    if hp.helpOnInstance
        dirInfos = [];
    elseif hp.callerContext.FullFileName ~= "" && strcmpi(dirTopic, 'private')
        dirInfoIsCaseSensitive = strcmp(dirTopic, 'private');
        dirTopic = fullfile(fileparts(hp.callerContext.FullFileName), dirTopic);
        dirInfos = matlab.lang.internal.introspective.hashedDirInfo(dirTopic, dirInfoIsCaseSensitive);
    else
        dirInfos = matlab.lang.internal.introspective.hashedDirInfo(dirTopic, true);
        if isempty(dirInfos) && ~strcmp(hp.inputTopic, hp.topic)
            dirTopic = hp.topic;
            dirInfos = matlab.lang.internal.introspective.hashedDirInfo(dirTopic, true);
        end
        dirInfoIsCaseSensitive = ~isempty(dirInfos);
        if ~dirInfoIsCaseSensitive
            if hp.isTypo
                dirTopic = hp.inputTopic;
            else
                dirTopic = hp.topic;
            end
            dirInfos = matlab.lang.internal.introspective.hashedDirInfo(dirTopic, false);
        end
    end

    hp.needsHotlinking = hp.needsHotlinking && hasFunctionHelp;
    allFolderHelp = '';
    emptyFolderList = reshape(dirInfos(1:0), 1, 0);
    suppressedFolders = emptyFolderList;
    suppressedClasses = emptyFolderList;
    suppressedPackages = emptyFolderList;
    foundPackage = false;
    fullName = '';

    for dirInfo = dirInfos'
        if matlab.internal.help.folder.hasContents(dirInfo, IncludeDefaultContents=true)
            hasContents = matlab.internal.help.folder.hasContents(dirInfo);
            [isClass, isPackage] = getFolderType(dirInfo);
            if isClass
                suppressedClasses(end+1) = dirInfo; %#ok<AGROW>
                continue;
            elseif isPackage
                if hasContents
                    foundPackage = true;
                else
                    suppressedPackages(end+1) = dirInfo; %#ok<AGROW>
                    continue;
                end
            elseif ~hasContents && ~(justH1 && ~hasFunctionHelp)
                suppressedFolders(end+1) = dirInfo; %#ok<AGROW>
                continue;
            end
            if hasContents
                dirHelpStr = hp.getContentsMHelp(dirInfo, justH1);
            elseif justH1
                folderName = hp.makeStrong(getFolderName(dirInfo.path));
                dirHelpStr = getString(message('MATLAB:help:DefaultFolderHelp', folderName));
            end
            allFolderHelp = accrueHelp(allFolderHelp, dirHelpStr);
            if dirHelpStr ~= ""
                fullName = dirInfo.path;
            end
        end
    end

    if ~isempty(suppressedFolders)
        if ~hasFunctionHelp && allFolderHelp == ""
            for dirInfo = suppressedFolders
                folderName = hp.makeStrong(getFolderName(dirInfo.path));
                banner = getString(message('MATLAB:help:ContentsBanner', folderName));
                dirHelpStr = matlab.internal.help.folder.getDefaultHelp(dirInfo, banner, hp.wantHyperlinks, hp.command);
                if dirHelpStr ~= ""
                    allFolderHelp = accrueHelp(allFolderHelp, dirHelpStr);
                    fullName = dirInfo.path;
                end
            end
        else
            suppressedFolders = matlab.internal.help.folder.shortenList(suppressedFolders, dirTopic);
            if ~isempty(suppressedFolders)
                if ~dirInfoIsCaseSensitive
                    dirTopic = matlab.lang.internal.introspective.extractCaseCorrectedName(suppressedFolders{1}, dirTopic);
                end
                hp.suppressedFolderName = dirTopic;
            end
        end
    end

    hp.suppressedImplicit = ~foundPackage && ~isempty(suppressedPackages) || ~isempty(suppressedClasses);

    if ~hasFunctionHelp && allFolderHelp == "" && hp.suppressedImplicit
        if ~foundPackage
            allPackageHelp = getMCOSFolderHelp(hp, justH1, suppressedPackages, 'DefaultNamespaceHelp', 'NamespaceBanner');
            allFolderHelp = accrueHelp(allFolderHelp, allPackageHelp);
        end
        allClassHelp = getMCOSFolderHelp(hp, justH1, suppressedClasses, 'DefaultClassHelp', 'MethodsBanner');
        allFolderHelp = accrueHelp(allFolderHelp, allClassHelp);
        hp.suppressedImplicit = ~hp.isContents;
    end

    if hp.wantHyperlinks && hp.commandIsHelp && allFolderHelp ~= ""
        highlightTopic = hp.docLinks.productName;
        if highlightTopic == ""
            highlightTopic = hp.objectSystemName;
        end
        if hp.objectSystemName ~= ""
            fullName = hp.objectSystemName;
            shortName = regexp(fullName, '\w*$', 'match', 'once');
        else
            shortName = extract(string(fullName), wildcardPattern("Except", filesep) + textBoundary("end"));
        end
        allFolderHelp = matlab.internal.help.highlightHelp(allFolderHelp, highlightTopic, shortName, '<strong>', '</strong>');
    end

    if hasFunctionHelp && allFolderHelp ~= ""
        if (hp.isTypo || hp.isUnderqualified) && dirInfoIsCaseSensitive
            hp.helpStr = '';
            hp.isTypo = false;
            hp.isUnderqualified = false;
            hp.docLinks.referencePage = '';
            hp.docLinks.referenceItem = [];
            hp.displayBanner = false;
        elseif ~hp.isTypo && ~dirInfoIsCaseSensitive
            allFolderHelp = '';
        end
    end

    if allFolderHelp ~= ""
        hp.isDir = true;
        if hp.helpStr == ""
            hp.isTypo = hp.isTypo | ~dirInfoIsCaseSensitive;
            hp.helpStr = allFolderHelp;
            hp.fullTopic = fullName;
            hp.topic = matlab.lang.internal.introspective.minimizePath(hp.fullTopic, true);
        else
            hp.helpStr = append(allFolderHelp, getString(message('MATLAB:help:IsBothBanner', dirTopic)), hp.helpStr);
        end
    end
end

function helpStr = getMCOSFolderHelp(hp, justH1, dirInfos, defaultID, bannerID)
    if isempty(dirInfos)
        helpStr = '';
    else
        if hp.objectSystemName == ""
            hp.objectSystemName = matlab.lang.internal.introspective.getPackageName(dirInfos(1).path);
        end
        folderName = hp.makeStrong(hp.objectSystemName);
        if justH1
            helpStr = getString(message(append('MATLAB:help:', defaultID), folderName));
        else
            if isscalar(dirInfos)
                dirInfo = dirInfos;
            else
                dirInfo = mergeDirInfos(dirInfos);
            end
            banner = getString(message(append('MATLAB:help:', bannerID), folderName));
            helpStr = matlab.internal.help.folder.getDefaultHelp(dirInfo, banner, hp.wantHyperlinks, hp.command);
        end
    end
end

function dirInfo = mergeDirInfos(dirInfos)
    dirPath = dirInfos(1).path;
    dirInfos = rmfield(dirInfos, 'path');
    dirInfo = structArrayFun(@(x)unique(vertcat(x{:})), dirInfos);
    [~, dirPath] = matlab.lang.internal.introspective.separateImplicitDirs(dirPath);
    dirInfo.path = dirPath;
end

function s = structArrayFun(fun, s)
    cellAll = struct2cell(s);
    numFields = size(cellAll,1);
    cellMerged = cell(numFields, 1);
    for i = 1:numFields
        cellMerged{i} = fun(cellAll(i,:,:));
    end
    s = cell2struct(cellMerged, fieldnames(s));
end

function folderName = getFolderName(dirPath)
    folderName = matlab.lang.internal.introspective.minimizePath(dirPath, true);
end

function [isClass, isPackage] = getFolderType(dirInfo)
    isClass = false;
    isPackage = false;
    [parent, folder] = fileparts(dirInfo.path);
    if startsWith(folder, '@')
        [~, parentParent] = fileparts(parent);
        if startsWith(parentParent, ["@", "+"])
            % parent is a package, so folder has to be a class.
            isClass = true;
        elseif ~any(ismember(dirInfo.m, 'schema.m')) && isempty(dirInfo.classes)
            % an @-folder with either subclasses or a schema is a UDD Package
            isClass = true;
        else
            isPackage = true;
        end
    elseif startsWith(folder, '+')
        isPackage = true;
    end
end

function helpStr = accrueHelp(helpStr, newHelp)
    if helpStr == "" || newHelp == ""
        sep = '';
    else
        sep = newline;
    end

    helpStr = append(helpStr, sep, newHelp);
end

% Copyright 2018-2024 The MathWorks, Inc.
