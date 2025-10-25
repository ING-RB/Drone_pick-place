function getBuiltinNamespaceHelp(hp)
    if hp.helpOnInstance
        return;
    end

    resolveFcn = @(topic)getBuiltinHelpForTopic(hp, topic);
    foundWithImport = matlab.lang.internal.introspective.iterateOverImports(resolveFcn, hp.callerContext.Imports, hp.inputTopic, false);

    if ~foundWithImport
        getBuiltinHelpForTopic(hp, hp.inputTopic);
    end
end

function isResolved = getBuiltinHelpForTopic(hp, topic)
    mcosResolver = matlab.lang.internal.introspective.MCOSMetaResolver(topic);
    mcosResolver.executeResolve();

    isResolved = mcosResolver.isResolved;
    if isResolved
        hp.needsHotlinking = true;
        hp.isTypo = hp.isTypo || ~mcosResolver.isCaseSensitive;

        if ~mcosResolver.isPackage
            return;
        end

        hp.helpStr = getBuiltinPackageContentHelpText(hp, mcosResolver.resolvedMeta);
        hp.isDir = true;

        if hp.helpStr ~= ""
            hp.fullTopic        = mcosResolver.fullTopic;
            hp.objectSystemName = mcosResolver.fullTopic;
        end

        hp.suppressedImplicit = false;
        hp.isBuiltin = true;
        hp.topic = mcosResolver.fullTopic;
    end
end

%% ------------------------------------------------------------------------
function contentText = getBuiltinPackageContentHelpText(hp, metaInfo)
    contentText = '';

    if any({metaInfo.FunctionList.Name} == "Contents")
        % Do not generate Contents if the Contents.m file has been skipped
        return;
    end

    packageText = getPackagedMetaInfoDescriptions(hp, metaInfo.PackageList, metaInfo.Name);
    if packageText ~= ""
        contentText = append(contentText, sprintf('\nPackages contained in %s:\n', metaInfo.Name), packageText);
    end

    classText = getPackagedMetaInfoDescriptions(hp, metaInfo.ClassList, metaInfo.Name);
    if classText ~= ""
        contentText = append(contentText, sprintf('\nClasses contained in %s:\n', metaInfo.Name), classText);
    end

    functionText = getPackagedMetaInfoDescriptions(hp, metaInfo.FunctionList, metaInfo.Name);
    if functionText ~= ""
        contentText = append(contentText, sprintf('\nFunctions contained in %s:\n', metaInfo.Name), functionText);
    end
end

%% ------------------------------------------------------------------------
function result = getPackagedMetaInfoDescriptions(hp, metaInfoList, packageName)
    result = '';

    if isempty(metaInfoList) || ~all(isprop(metaInfoList,'Description')) || ~all(isprop(metaInfoList,'Name'))
        return;
    end

    lineItem = cell(1,numel(metaInfoList));

    for i = 1:numel(metaInfoList)
        name = strsplit(metaInfoList(i).Name,'.');
        name = name{end};

        qualifiedName = append(packageName, '.', name);
        description   = metaInfoList(i).Description;

        link    = createHotlink(hp, qualifiedName, name);
        linkPad = repmat(' ', 1, 30-numel(name));

        lineItem{i} = append(link, linkPad, ' - ', description);
    end

    result = append(strjoin(lineItem, newline), newline);
end

%% ------------------------------------------------------------------------
function name = createHotlink(hp, qualifiedName, name)
    if hp.wantHyperlinks
        name = hp.createMATLABLink(qualifiedName, name);
    end
end

%   Copyright 2014-2024 The MathWorks, Inc.
